import copy
import json
import unittest

from prepare_exercise_video_release import prepare
import test_validate_exercise_videos as fixtures


class ReleasePlanTest(unittest.TestCase):
    def setUp(self):
        self.fixture = fixtures.VideoDeliveryGateTest()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)
        self.current = [{'id': 'moro_ex1', 'video_url': None, 'image_url': None}]

    def build(self, current=None, origin='https://example.test'):
        f = self.fixture
        return prepare(f.manifest, self.current if current is None else current, f.root, 'moro', origin,
                       probe=lambda _: f.probe_result)

    def test_prepares_upload_mapping_and_guarded_reverse_without_mutation(self):
        before = copy.deepcopy(self.fixture.manifest)
        outputs = self.build()
        self.assertEqual(set(outputs), {'uploads.json', 'mapping.json', 'apply.sql', 'rollback.sql'})
        uploads = json.loads(outputs['uploads.json'])['uploads']
        self.assertEqual(len(uploads), 2)
        self.assertTrue(all(u['upsert'] is False for u in uploads))
        self.assertEqual(uploads[1]['object_key'], 'exercises/moro_ex1/v1/poster.png')
        self.assertIn('AND video_url IS NOT DISTINCT FROM NULL', outputs['apply.sql'])
        self.assertIn('SET video_url = NULL', outputs['rollback.sql'])
        self.assertIn("IF changed <> 1 THEN RAISE EXCEPTION", outputs['apply.sql'])
        self.assertIn('END;\n$media_release$;\nCOMMIT;', outputs['apply.sql'])
        self.assertEqual(self.fixture.manifest, before)

    def test_exact_previous_mapping_required(self):
        for current in [[], self.current * 2, [{'id': 'other_ex1', 'video_url': None, 'image_url': None}],
                        [{**self.current[0], 'extra': 'must not include user data'}]]:
            with self.assertRaises(ValueError):
                self.build(current)

    def test_rejects_pending_assets_before_producing_sql(self):
        self.fixture.entry['status'] = 'editing'
        with self.assertRaises(ValueError):
            self.build()

    def test_rejects_reusing_published_revision(self):
        url = 'https://example.test/storage/v1/object/public/exercise-media/exercises/moro_ex1/v1/video.mp4'
        self.current[0]['video_url'] = url
        with self.assertRaises(ValueError):
            self.build()

    def test_rejects_untrusted_origin_or_secret_urls(self):
        for origin in ['http://example.test', 'https://secret@example.test', 'https://example.test/path',
                       'https://example.test?secret=value', 'https://example.test:443']:
            with self.assertRaises(ValueError):
                self.build(origin=origin)
        self.current[0]['video_url'] = 'https://example.test/old.mp4?secret=value'
        with self.assertRaises(ValueError):
            self.build()

    def test_old_url_quote_and_dollar_delimiter_cannot_escape_sql(self):
        self.current[0]['video_url'] = "https://example.test/old'$media_release$.mp4"
        sql = self.build()['apply.sql']
        self.assertIn("old''$media_release$.mp4'", sql)
        self.assertIn('DO $media_release_$', sql)


if __name__ == '__main__':
    unittest.main()
