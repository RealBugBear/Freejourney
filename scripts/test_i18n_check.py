#!/usr/bin/env python3

import io
import json
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

from scripts.i18n_check import (
    check_catalogs,
    check_files,
    discover_target_catalogs,
    extract_placeholders,
    main,
)


def catalog(locale: str, greeting: str = "Hello {name}") -> dict:
    return {
        "@@locale": locale,
        "title": "Reflex Journey",
        "greeting": greeting,
        "@greeting": {
            "description": f"{locale} description may be localized",
            "placeholders": {"name": {"type": "String"}},
        },
        "inbox": (
            "{count, plural, one{One message} "
            "other{{count} messages for {name}}}"
        ),
        "@inbox": {
            "placeholders": {
                "count": {"type": "int"},
                "name": {"type": "String"},
            }
        },
    }


class PlaceholderExtractionTest(unittest.TestCase):
    def test_parses_nested_icu_arguments_without_treating_branch_copy_as_keys(self):
        message = (
            "{count, plural, one{Ready} "
            "other{{count} results for {name}}}"
        )

        self.assertEqual(extract_placeholders(message), {"count", "name"})

    def test_ignores_escaped_braces_and_keeps_contractions(self):
        message = "It doesn't show '{ignored}', but it shows {name}."

        self.assertEqual(extract_placeholders(message), {"name"})


class CatalogCheckTest(unittest.TestCase):
    def test_accepts_complete_catalogs_with_localized_descriptions(self):
        self.assertEqual(check_catalogs(catalog("de"), catalog("en")), [])

    def test_reports_message_and_metadata_key_parity(self):
        de = catalog("de")
        en = catalog("en")
        del en["title"]
        del en["@greeting"]

        issues = check_catalogs(de, en)

        self.assertIn("[en:title] message key is missing", issues)
        self.assertIn("[en:@greeting] metadata key is missing", issues)

    def test_reports_empty_and_non_string_values(self):
        de = catalog("de")
        en = catalog("en")
        de["title"] = "  "
        en["title"] = None

        issues = check_catalogs(de, en)

        self.assertIn("[de:title] value is empty", issues)
        self.assertIn("[en:title] value must be a string, got NoneType", issues)

    def test_reports_placeholder_set_difference(self):
        de = catalog("de", "Hallo {name}")
        en = catalog("en", "Hello {firstName}")

        issues = check_catalogs(de, en)

        self.assertTrue(
            any("[greeting] placeholder sets differ" in issue for issue in issues)
        )

    def test_reports_placeholder_metadata_missing_from_message(self):
        de = catalog("de")
        en = catalog("en")
        del en["@greeting"]["placeholders"]["name"]

        issues = check_catalogs(de, en)

        self.assertIn(
            "[en:greeting] placeholder metadata differs from message: "
            "message=['name'], metadata=[]",
            issues,
        )
        self.assertIn(
            "[greeting] placeholder metadata differs between de and en",
            issues,
        )

    def test_reports_placeholder_metadata_definition_difference(self):
        de = catalog("de")
        en = catalog("en")
        en["@greeting"]["placeholders"]["name"]["type"] = "Object"

        issues = check_catalogs(de, en)

        self.assertIn(
            "[greeting] placeholder metadata differs between de and en",
            issues,
        )

    def test_reports_german_umlauts_in_english_message_values(self):
        de = catalog("de")
        en = catalog("en")
        en["title"] = "Zurück"

        issues = check_catalogs(de, en)

        self.assertIn(
            "[en:title] value contains a German umlaut or ß",
            issues,
        )

    def test_checks_umlauts_even_when_english_key_is_extra(self):
        de = catalog("de")
        en = catalog("en")
        en["englishOnly"] = "Später"

        issues = check_catalogs(de, en)

        self.assertIn(
            "[en:englishOnly] value contains a German umlaut or ß",
            issues,
        )


class FileCheckTest(unittest.TestCase):
    def test_reads_explicit_arb_paths(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            de_path = directory / "de.arb"
            en_path = directory / "en.arb"
            de_path.write_text(json.dumps(catalog("de")), encoding="utf-8")
            en_path.write_text(json.dumps(catalog("en")), encoding="utf-8")

            issues, key_count = check_files(de_path, en_path)

        self.assertEqual(issues, [])
        self.assertEqual(key_count, 3)


class MultiCatalogDiscoveryTest(unittest.TestCase):
    def _write(self, directory: Path, locale: str, data: dict) -> Path:
        path = directory / f"app_{locale}.arb"
        path.write_text(json.dumps(data), encoding="utf-8")
        return path

    def test_discovers_every_non_template_catalog_sorted(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            template = self._write(directory, "de", catalog("de"))
            self._write(directory, "fr", catalog("fr"))
            self._write(directory, "en", catalog("en"))
            (directory / "notes.txt").write_text("ignored", encoding="utf-8")

            targets = discover_target_catalogs(template)

        self.assertEqual(
            [(locale, path.name) for locale, path in targets],
            [("en", "app_en.arb"), ("fr", "app_fr.arb")],
        )

    def test_incomplete_extra_catalog_fails_the_gate_naming_the_file(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            template = self._write(directory, "de", catalog("de"))
            self._write(directory, "en", catalog("en"))
            incomplete_fr = catalog("fr")
            del incomplete_fr["title"]
            self._write(directory, "fr", incomplete_fr)

            stderr = io.StringIO()
            with redirect_stdout(io.StringIO()), redirect_stderr(stderr):
                result = main(["--template", str(template)])

        self.assertEqual(result, 1)
        self.assertIn("app_fr.arb", stderr.getvalue())
        self.assertIn("[fr:title] message key is missing", stderr.getvalue())

    def test_complete_extra_catalog_passes_the_gate(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            template = self._write(directory, "de", catalog("de"))
            self._write(directory, "en", catalog("en"))
            self._write(directory, "fr", catalog("fr"))

            stdout = io.StringIO()
            with redirect_stdout(stdout):
                result = main(["--template", str(template)])

        self.assertEqual(result, 0)
        self.assertIn("app_en.arb", stdout.getvalue())
        self.assertIn("app_fr.arb", stdout.getvalue())

    def test_umlaut_check_applies_to_every_non_german_catalog(self):
        de = catalog("de")
        fr = catalog("fr")
        fr["title"] = "Zurück"

        issues = check_catalogs(de, fr, "fr")

        self.assertIn(
            "[fr:title] value contains a German umlaut or ß",
            issues,
        )


if __name__ == "__main__":
    unittest.main()
