#!/usr/bin/env python3
"""Local-only delivery gate. Never fetches URLs, uploads, or changes a database."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys

STATES = {'awaiting_production', 'filming', 'editing', 'in_review', 'approved', 'published'}
APPROVALS = {'content', 'rights', 'accessibility_de', 'accessibility_en', 'device_qa'}
FILES = {'video', 'poster', 'captions_de', 'captions_en', 'transcript_de', 'transcript_en'}


def local_file(root, relative):
    if not isinstance(relative, str) or not relative or Path(relative).is_absolute():
        raise ValueError('file path must be relative to delivery directory')
    path = (root / relative).resolve()
    if not path.is_relative_to(root.resolve()) or not path.is_file():
        raise ValueError('file is missing or outside delivery directory')
    return path


def check_mp4(path, probe):
    """Check actual stream metadata and fast-start layout, not supplied claims."""
    info = probe(path)
    videos = [s for s in info.get('streams', []) if s.get('codec_type') == 'video']
    if len(videos) != 1 or any(s.get('codec_type') == 'audio' for s in info.get('streams', [])):
        raise ValueError('delivery must contain one silent video stream')
    v = videos[0]
    width, height = v.get('width', 0), v.get('height', 0)
    if v.get('codec_name') != 'h264' or v.get('pix_fmt') != 'yuv420p':
        raise ValueError('video must use H.264 with yuv420p')
    if (width, height) not in {(1280, 720), (1920, 1080)}:
        raise ValueError('video must be landscape 720p or 1080p')
    rate = v.get('avg_frame_rate', '0/1').split('/')
    fps = float(rate[0]) / float(rate[1]) if len(rate) == 2 else float(rate[0])
    duration = float(info.get('format', {}).get('duration', 0))
    bitrate = float(info.get('format', {}).get('bit_rate', 0))
    if not 24 <= fps <= 30 or not 15 <= duration <= 90 or not 0 < bitrate <= 4_500_000:
        raise ValueError('video exceeds duration, frame-rate or bitrate limits')
    # Walk top-level MP4 atoms without loading the media into memory.
    with path.open('rb') as handle:
        size = path.stat().st_size
        while handle.tell() + 8 <= size:
            start = handle.tell()
            length, kind = struct.unpack('>I4s', handle.read(8))
            header = 8
            if length == 1:
                length = struct.unpack('>Q', handle.read(8))[0]
                header = 16
            if kind == b'moov':
                return
            if kind == b'mdat':
                raise ValueError('MP4 requires fast-start (moov before mdat)')
            if length < header or start + length > size:
                break
            handle.seek(start + length)
    raise ValueError('invalid MP4 structure or missing moov atom')


def ffprobe(path):
    executable = shutil.which('ffprobe')
    if executable is None:
        raise ValueError('ffprobe is required for approved deliveries')
    result = subprocess.run(
        [executable, '-v', 'error', '-show_streams', '-show_format', '-of', 'json', str(path)],
        capture_output=True, text=True, timeout=30, check=True)
    return json.loads(result.stdout)


def validate(manifest, root, release_package=None, probe=ffprobe):
    errors = []
    if not isinstance(manifest, dict):
        return ['manifest must be an object']
    entries = manifest.get('videos')
    if manifest.get('schema_version') != 1 or not isinstance(entries, list) or not entries:
        return ['invalid or empty v1 manifest']
    seen_exercises, seen_videos = set(), set()
    if release_package and not any(e.get('package_id') == release_package for e in entries if isinstance(e, dict)):
        errors.append('release package has no videos')
    for index, entry in enumerate(entries):
        label = f'entry {index + 1}'  # Do not echo untrusted content or URLs.
        if not isinstance(entry, dict):
            errors.append(f'{label}: expected object')
            continue
        exercise, video = entry.get('exercise_id'), entry.get('video_id')
        if not isinstance(exercise, str) or not re.fullmatch(r'[a-z0-9_]+', exercise):
            errors.append(f'{label}: invalid exercise identifier')
            continue
        if not isinstance(video, str):
            errors.append(f'{label}: invalid video identifier')
            continue
        if video != f'{exercise}_demonstration' or exercise in seen_exercises or video in seen_videos:
            errors.append(f'{label}: duplicate or unstable identifier')
        seen_exercises.add(exercise)
        seen_videos.add(video)
        status = entry.get('status')
        if not isinstance(status, str) or status not in STATES:
            errors.append(f'{label}: unknown status')
            continue
        if type(entry.get('revision')) is not int or entry['revision'] < 1:
            errors.append(f'{label}: revision must be a positive integer')
        if not isinstance(entry.get('owner'), str) or not entry['owner'].strip():
            errors.append(f'{label}: missing accountable owner')
        required = release_package == entry.get('package_id')
        approved = status in {'approved', 'published'}
        if required and not approved:
            errors.append(f'{label}: required video is not approved')
        if not approved:
            if entry.get('public_url'):
                errors.append(f'{label}: unpublished media must not have a public URL')
            continue
        if entry.get('instruction_status') == 'blocked_missing_instructions':
            errors.append(f'{label}: source instructions are incomplete')
        if (not isinstance(entry.get('content_version'), str)
                or not entry['content_version'].strip()
                or entry.get('approved_content_version') != entry['content_version']):
            errors.append(f'{label}: approvals do not match current content version')
        refs = entry.get('approval_refs', {})
        if not isinstance(refs, dict) or any(not isinstance(refs.get(k), str) or not refs[k].strip() for k in APPROVALS):
            errors.append(f'{label}: missing content, rights, language or device approval record')
        if entry.get('delivery_profile') != 'silent-neutral-landscape-v1':
            errors.append(f'{label}: unsupported delivery profile')
        files = entry.get('files', {})
        if not isinstance(files, dict) or set(files) != FILES:
            errors.append(f'{label}: delivery requires video, poster and DE/EN captions/transcripts')
            continue
        for role, record in files.items():
            try:
                path = local_file(root, record.get('path'))
                size = path.stat().st_size
                limit = 50 * 1024 * 1024 if role == 'video' else 5 * 1024 * 1024
                if size == 0 or size > limit:
                    raise ValueError('empty or oversized file')
                with path.open('rb') as stream:
                    digest = hashlib.sha256()
                    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
                        digest.update(chunk)
                if record.get('sha256') != digest.hexdigest():
                    raise ValueError('SHA-256 checksum mismatch')
                if role == 'video':
                    if path.suffix.lower() != '.mp4':
                        raise ValueError('video must be MP4')
                    check_mp4(path, probe)
                elif role.startswith('captions'):
                    value = path.read_text(encoding='utf-8-sig')
                    if not value.startswith('WEBVTT') or '-->' not in value:
                        raise ValueError('caption file must contain WebVTT cues')
                elif role.startswith('transcript'):
                    if not path.read_text(encoding='utf-8').strip():
                        raise ValueError('transcript is empty')
                elif role == 'poster':
                    with path.open('rb') as stream:
                        signature = stream.read(8)
                    if not (signature.startswith(b'\xff\xd8\xff') or signature == b'\x89PNG\r\n\x1a\n'):
                        raise ValueError('poster must be JPEG or PNG')
            except (ValueError, OSError, KeyError, AttributeError, TypeError, ZeroDivisionError,
                    subprocess.SubprocessError, struct.error):
                errors.append(f'{label}: invalid {role} file, checksum or encoding')
        if status == 'published':
            revision = entry['revision']
            expected_suffix = f'/storage/v1/object/public/exercise-media/exercises/{exercise}/v{revision}/video.mp4'
            from urllib.parse import urlsplit
            try:
                url = urlsplit(entry.get('public_url', ''))
                if url.scheme != 'https' or not url.hostname or url.username or url.password or url.query or url.fragment or url.path != expected_suffix:
                    raise ValueError('invalid published URL')
            except (ValueError, TypeError):
                errors.append(f'{label}: published URL must be immutable public HTTPS without credentials/query')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest', type=Path, default=Path('docs/media/exercise_video_manifest.v1.json'))
    parser.add_argument('--delivery-root', type=Path, default=Path('.'))
    parser.add_argument('--release-package', help='Fail unless every video in this package is approved and delivered')
    args = parser.parse_args()
    try:
        manifest = json.loads(args.manifest.read_text(encoding='utf-8'))
        errors = validate(manifest, args.delivery_root, args.release_package)
    except (OSError, ValueError, AttributeError, TypeError):
        errors = ['manifest is unreadable or malformed']
    if errors:
        for error in errors:
            print(f'FAIL: {error}', file=sys.stderr)
        return 1
    print(f"Inventory valid: {len(manifest['videos'])} entries. " +
          ('Delivery gate passed.' if args.release_package else 'This does not certify production footage.'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
