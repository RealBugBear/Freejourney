import copy
import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest

from validate_exercise_videos import validate, APPROVALS


class VideoDeliveryGateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.entry = {
            'exercise_id': 'moro_ex1', 'video_id': 'moro_ex1_demonstration',
            'package_id': 'moro', 'revision': 1, 'status': 'approved',
            'owner': 'test fixture', 'delivery_profile': 'silent-neutral-landscape-v1',
            'instruction_status': 'requires_filming_review',
            'content_version': 'test-content-v1', 'approved_content_version': 'test-content-v1',
            'approval_refs': {k: 'test-only-approval' for k in APPROVALS}, 'files': {},
        }
        fixtures = {
            'video': ('video.mp4', struct.pack('>I4s', 8, b'moov') + struct.pack('>I4s', 8, b'mdat')),
            'poster': ('poster.png', b'\x89PNG\r\n\x1a\nfixture'),
            'captions_de': ('de.vtt', b'WEBVTT\n\n00:00.000 --> 00:01.000\nTest\n'),
            'captions_en': ('en.vtt', b'WEBVTT\n\n00:00.000 --> 00:01.000\nTest\n'),
            'transcript_de': ('de.txt', b'Test fixture'),
            'transcript_en': ('en.txt', b'Test fixture'),
        }
        for role, (name, data) in fixtures.items():
            (self.root / name).write_bytes(data)
            self.entry['files'][role] = {'path': name, 'sha256': hashlib.sha256(data).hexdigest()}
        self.manifest = {'schema_version': 1, 'videos': [self.entry]}
        self.probe_result = {
            'streams': [{'codec_type': 'video', 'codec_name': 'h264', 'pix_fmt': 'yuv420p',
                         'width': 1280, 'height': 720, 'avg_frame_rate': '25/1'}],
            'format': {'duration': '30', 'bit_rate': '2000000'},
        }

    def check(self, package='moro'):
        return validate(self.manifest, self.root, package, probe=lambda _: self.probe_result)

    def test_complete_delivery_passes_with_injected_media_probe(self):
        self.assertEqual(self.check(), [])

    def test_actual_inventory_is_honest_but_not_releasable(self):
        manifest = json.loads(Path('docs/media/exercise_video_manifest.v1.json').read_text())
        self.assertEqual(validate(manifest, Path('.')), [])
        self.assertEqual(sum('not approved' in e for e in validate(manifest, Path('.'), 'moro')), 7)

    def test_unknown_or_empty_release_package_fails(self):
        self.assertIn('release package has no videos', self.check('missing'))
        self.manifest['videos'] = []
        self.assertTrue(self.check())

    def test_missing_approval_and_incomplete_guidance_block_delivery(self):
        del self.entry['approval_refs']['rights']
        self.entry['instruction_status'] = 'blocked_missing_instructions'
        self.assertEqual(len(self.check()), 2)

    def test_changed_content_invalidates_previous_approval(self):
        self.entry['content_version'] = 'test-content-v2'
        self.assertTrue(any('content version' in e for e in self.check()))

    def test_malformed_entries_fail_without_uncaught_errors(self):
        for key in ['video_id', 'status']:
            saved = self.entry[key]
            self.entry[key] = []
            self.assertTrue(self.check())
            self.entry[key] = saved
        self.assertTrue(validate([], self.root))

    def test_duplicate_ids_and_bad_revisions_fail(self):
        self.manifest['videos'].append(copy.deepcopy(self.entry))
        self.entry['revision'] = True
        self.assertTrue(any('identifier' in e for e in self.check()))
        self.assertTrue(any('revision' in e for e in self.check()))

    def test_corrupt_or_missing_file_is_rejected(self):
        (self.root / 'video.mp4').write_bytes(b'corrupt')
        (self.root / 'en.txt').unlink()
        self.assertEqual(len(self.check()), 2)

    def test_path_traversal_and_symlink_escape_are_rejected(self):
        self.entry['files']['video']['path'] = '../video.mp4'
        self.assertTrue(self.check())
        (self.root / 'escape').symlink_to('/etc/hosts')
        self.entry['files']['video']['path'] = 'escape'
        self.assertTrue(self.check())

    def test_unsupported_audio_resolution_and_rate_fail(self):
        self.probe_result['streams'].append({'codec_type': 'audio'})
        self.assertTrue(self.check())
        self.probe_result['streams'].pop()
        self.probe_result['streams'][0]['width'] = 4000
        self.assertTrue(self.check())
        self.probe_result['streams'][0]['width'] = 1280
        self.probe_result['streams'][0]['avg_frame_rate'] = '0/0'
        self.assertTrue(self.check())

    def test_non_faststart_mp4_is_rejected(self):
        data = struct.pack('>I4s', 8, b'mdat') + struct.pack('>I4s', 8, b'moov')
        (self.root / 'video.mp4').write_bytes(data)
        self.entry['files']['video']['sha256'] = hashlib.sha256(data).hexdigest()
        self.assertTrue(self.check())

    def test_unpublished_urls_and_mutable_or_secret_published_urls_fail(self):
        self.entry['status'] = 'editing'
        self.entry['public_url'] = 'https://example.test/unreviewed.mp4'
        self.assertTrue(self.check())
        self.entry['status'] = 'published'
        base = 'https://example.test/storage/v1/object/public/exercise-media/exercises/moro_ex1/v1/video.mp4'
        self.entry['public_url'] = base
        self.assertEqual(self.check(), [])
        for value in [base + '?token=private', base.replace('/v1/', '/current/'), base.replace('https:', 'http:')]:
            self.entry['public_url'] = value
            self.assertTrue(self.check())


if __name__ == '__main__':
    unittest.main()
