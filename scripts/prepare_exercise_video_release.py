#!/usr/bin/env python3
"""Prepare reviewable upload/SQL artifacts locally. No network or database writes."""
import argparse
import json
from pathlib import Path
import re
import sys
from urllib.parse import urlsplit

from validate_exercise_videos import validate, ffprobe, local_file


def sql_literal(value):
    if value is None:
        return 'NULL'
    return "'" + value.replace("'", "''") + "'"


def public_url(value):
    if value is None:
        return
    if not isinstance(value, str) or any(ord(c) < 32 for c in value):
        raise ValueError('invalid content URL')
    parsed = urlsplit(value)
    if parsed.scheme != 'https' or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise ValueError('content URL must be public HTTPS without credentials/query/fragment')


def guarded_sql(changes):
    tag = '$media_release$'
    while tag in json.dumps(changes):
        tag = tag[:-1] + '_$'
    lines = ['-- REVIEW REQUIRED: production execution needs explicit owner authorization.',
             '-- The complete batch rolls back if any expected old URL no longer matches.',
             'BEGIN;', f'DO {tag}', 'DECLARE changed integer;', 'BEGIN']
    for change in changes:
        lines.extend([
            '  UPDATE public.exercises',
            f"  SET video_url = {sql_literal(change['new_video_url'])},",
            f"      image_url = {sql_literal(change['new_image_url'])}",
            f"  WHERE id = {sql_literal(change['id'])}",
            f"    AND video_url IS NOT DISTINCT FROM {sql_literal(change['old_video_url'])}",
            f"    AND image_url IS NOT DISTINCT FROM {sql_literal(change['old_image_url'])};",
            '  GET DIAGNOSTICS changed = ROW_COUNT;',
            "  IF changed <> 1 THEN RAISE EXCEPTION 'Media mapping changed or exercise missing; batch cancelled'; END IF;",
        ])
    lines.extend(['END;', f'{tag};', 'COMMIT;', ''])
    return '\n'.join(lines)


def prepare(manifest, current, root, package, project_url, probe=ffprobe):
    errors = validate(manifest, root, release_package=package, probe=probe)
    if errors:
        raise ValueError('delivery validation failed: ' + '; '.join(errors))
    public_url(project_url)
    if project_url is None:
        raise ValueError('project URL is required')
    parsed = urlsplit(project_url)
    if parsed.path not in {'', '/'} or parsed.port is not None:
        raise ValueError('project URL must be an HTTPS origin without path/port')
    origin = f'https://{parsed.hostname}'
    if not isinstance(current, list):
        raise ValueError('current mapping must be a JSON array of content URL rows')
    rows = {}
    for row in current:
        if not isinstance(row, dict) or set(row) != {'id', 'video_url', 'image_url'}:
            raise ValueError('current row requires exactly id, video_url, image_url')
        if not isinstance(row['id'], str) or not re.fullmatch(r'[a-z0-9_]+', row['id']) or row['id'] in rows:
            raise ValueError('invalid or duplicate current exercise ID')
        public_url(row['video_url'])
        public_url(row['image_url'])
        rows[row['id']] = row
    selected = [entry for entry in manifest['videos'] if entry['package_id'] == package]
    if set(rows) != {entry['exercise_id'] for entry in selected}:
        raise ValueError('current mapping must cover exactly the selected package exercise IDs')
    uploads, changes = [], []
    for entry in selected:
        ex_id = entry['exercise_id']
        prefix = f"exercises/{ex_id}/v{entry['revision']}"
        urls = {}
        for role in ['video', 'poster']:
            record = entry['files'][role]
            path = local_file(root, record['path'])
            if role == 'video':
                name, mime = 'video.mp4', 'video/mp4'
            else:
                with path.open('rb') as stream:
                    is_png = stream.read(8) == b'\x89PNG\r\n\x1a\n'
                name, mime = ('poster.png', 'image/png') if is_png else ('poster.jpg', 'image/jpeg')
            key = f'{prefix}/{name}'
            urls[role] = f'{origin}/storage/v1/object/public/exercise-media/{key}'
            uploads.append({'exercise_id': ex_id, 'role': role, 'source': str(path),
                            'bucket': 'exercise-media', 'object_key': key, 'content_type': mime,
                            'cache_control_seconds': 31536000, 'upsert': False,
                            'sha256': record['sha256'], 'bytes': path.stat().st_size})
        old = rows[ex_id]
        if urls['video'] == old['video_url'] or urls['poster'] == old['image_url']:
            raise ValueError('new revision must not reuse currently published object URLs')
        changes.append({'id': ex_id, 'old_video_url': old['video_url'], 'old_image_url': old['image_url'],
                        'new_video_url': urls['video'], 'new_image_url': urls['poster']})
    reverse = [{**c, 'old_video_url': c['new_video_url'], 'old_image_url': c['new_image_url'],
                'new_video_url': c['old_video_url'], 'new_image_url': c['old_image_url']} for c in changes]
    return {'uploads.json': json.dumps({'status': 'prepared_not_uploaded', 'uploads': uploads}, indent=2) + '\n',
            'mapping.json': json.dumps(changes, indent=2) + '\n',
            'apply.sql': guarded_sql(changes), 'rollback.sql': guarded_sql(reverse)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest', type=Path, default=Path('docs/media/exercise_video_manifest.v1.json'))
    parser.add_argument('--current-mapping', type=Path, required=True)
    parser.add_argument('--delivery-root', type=Path, required=True)
    parser.add_argument('--package', required=True)
    parser.add_argument('--project-url', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        outputs = prepare(json.loads(args.manifest.read_text()), json.loads(args.current_mapping.read_text()),
                          args.delivery_root, args.package, args.project_url)
        args.output.mkdir(parents=True, exist_ok=False)
        for name, body in outputs.items():
            (args.output / name).write_text(body, encoding='utf-8')
    except (OSError, ValueError, TypeError, KeyError, AttributeError):
        print('Release preparation failed: check delivery gate, exact prior URL mapping, HTTPS origin, and unused output directory.', file=sys.stderr)
        return 1
    print('Prepared upload manifest, URL mapping, apply.sql and rollback.sql. Nothing uploaded or applied.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
