#!/usr/bin/env python3

import json
import re
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
IOS_RUNNER = ROOT / "ios" / "Runner"
PROJECT_FILE = ROOT / "ios" / "Runner.xcodeproj" / "project.pbxproj"
ANDROID_MANIFEST = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
ANDROID_GRADLE = ROOT / "android" / "app" / "build.gradle.kts"

USAGE_DESCRIPTION_KEYS = {
    "NSCalendarsUsageDescription",
    "NSCameraUsageDescription",
    "NSLocationAlwaysAndWhenInUseUsageDescription",
    "NSLocationWhenInUseUsageDescription",
    "NSMicrophoneUsageDescription",
}


def parse_strings_file(path: Path) -> dict[str, str]:
    contents = path.read_text(encoding="utf-8")
    entries = dict(
        re.findall(r'^"([^"\\]+)"\s*=\s*"([^"\\]*)";\s*$', contents, re.MULTILINE)
    )
    non_empty_lines = [line for line in contents.splitlines() if line.strip()]
    if len(entries) != len(non_empty_lines):
        raise AssertionError(f"Unsupported or malformed .strings entry in {path}")
    return entries


def parse_plist(path: Path) -> dict[str, object]:
    result = subprocess.run(
        ["plutil", "-convert", "json", "-o", "-", path],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


class IOSPlatformLocalizationTest(unittest.TestCase):
    def setUp(self):
        self.info_plist = parse_plist(IOS_RUNNER / "Info.plist")
        self.de = parse_strings_file(IOS_RUNNER / "de.lproj" / "InfoPlist.strings")
        self.en = parse_strings_file(IOS_RUNNER / "en.lproj" / "InfoPlist.strings")

    def test_localizes_exactly_the_existing_usage_descriptions(self):
        base_usage_keys = {
            key
            for key in self.info_plist
            if key.startswith("NS") and key.endswith("UsageDescription")
        }

        self.assertEqual(USAGE_DESCRIPTION_KEYS, base_usage_keys)
        self.assertEqual(USAGE_DESCRIPTION_KEYS, set(self.de))
        self.assertEqual(USAGE_DESCRIPTION_KEYS, set(self.en))

    def test_german_copy_preserves_the_info_plist_source(self):
        expected = {key: self.info_plist[key] for key in USAGE_DESCRIPTION_KEYS}

        self.assertEqual(expected, self.de)

    def test_english_copy_is_present_without_localizing_the_brand(self):
        for key in USAGE_DESCRIPTION_KEYS:
            self.assertTrue(self.en[key])
            self.assertNotEqual(self.de[key], self.en[key])
            self.assertIn("Reflex Journey", self.en[key])

        self.assertNotIn("CFBundleDisplayName", self.de)
        self.assertNotIn("CFBundleDisplayName", self.en)

    def test_xcode_project_packages_both_localizations(self):
        project = PROJECT_FILE.read_text(encoding="utf-8")
        known_regions_match = re.search(
            r"knownRegions = \((?P<regions>.*?)\);", project, re.DOTALL
        )

        self.assertIsNotNone(known_regions_match)
        regions = {
            region.strip().rstrip(",")
            for region in known_regions_match.group("regions").splitlines()
            if region.strip()
        }
        self.assertTrue({"de", "en", "Base"}.issubset(regions))
        self.assertIn("path = de.lproj/InfoPlist.strings", project)
        self.assertIn("path = en.lproj/InfoPlist.strings", project)
        self.assertIn("InfoPlist.strings in Resources", project)
        self.assertRegex(
            project,
            r"InfoPlist\.strings \*/ = \{\s*isa = PBXVariantGroup;",
        )


class AndroidPlatformLocalizationTest(unittest.TestCase):
    def test_system_dialogs_use_the_invariant_flavor_app_name(self):
        manifest = ANDROID_MANIFEST.read_text(encoding="utf-8")
        gradle = ANDROID_GRADLE.read_text(encoding="utf-8")

        self.assertIn('android:label="@string/app_name"', manifest)
        self.assertIn('resValue("string", "app_name", "Reflex Journey DEV")', gradle)
        self.assertIn(
            'resValue("string", "app_name", "Reflex Journey STAGING")', gradle
        )
        self.assertIn('resValue("string", "app_name", "Reflex Journey")', gradle)

        for strings_file in (ROOT / "android" / "app" / "src" / "main" / "res").glob(
            "values-*/strings.xml"
        ):
            self.assertNotIn('name="app_name"', strings_file.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
