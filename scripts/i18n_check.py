#!/usr/bin/env python3
"""Validate parity and basic quality constraints for the DE/EN ARB files.

The check is intentionally independent of Flutter so it can fail quickly in
local and CI release-readiness runs.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections.abc import Mapping
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DE_ARB = REPO_ROOT / "lib" / "l10n" / "app_de.arb"
DEFAULT_EN_ARB = REPO_ROOT / "lib" / "l10n" / "app_en.arb"

GERMAN_UMLAUT = re.compile(r"[äöüÄÖÜß]")
IDENTIFIER = re.compile(r"[A-Za-z][A-Za-z0-9_]*")
COMPLEX_FORMATS = {"plural", "select", "selectordinal"}

Catalog = Mapping[str, Any]


def _skip_space(message: str, index: int) -> int:
    while index < len(message) and message[index].isspace():
        index += 1
    return index


def _skip_icu_quote(message: str, index: int) -> int:
    """Skip an ICU apostrophe escape, leaving contractions untouched."""

    if index + 1 >= len(message):
        return index + 1
    if message[index + 1] == "'":
        return index + 2
    if message[index + 1] not in "{}":
        return index + 1

    index += 2
    while index < len(message):
        if message[index] != "'":
            index += 1
            continue
        if index + 1 < len(message) and message[index + 1] == "'":
            index += 2
            continue
        return index + 1
    return index


def extract_placeholders(message: str) -> set[str]:
    """Return ICU argument names used by *message*.

    Plural/select branch braces are parsed as message containers, so a branch
    such as ``one{Ready}`` does not incorrectly report ``Ready`` as an
    argument. Nested arguments inside those branches are still collected.
    """

    placeholders: set[str] = set()

    def parse_message(index: int, *, stop_at_closing_brace: bool) -> int:
        while index < len(message):
            char = message[index]
            if char == "'":
                index = _skip_icu_quote(message, index)
            elif char == "{":
                index = parse_argument(index)
            elif char == "}" and stop_at_closing_brace:
                return index + 1
            else:
                index += 1
        return index

    def parse_argument(index: int) -> int:
        opening_brace = index
        index = _skip_space(message, index + 1)
        match = IDENTIFIER.match(message, index)
        if match is None:
            return opening_brace + 1

        name = match.group(0)
        index = _skip_space(message, match.end())
        if index >= len(message):
            return opening_brace + 1
        if message[index] == "}":
            placeholders.add(name)
            return index + 1
        if message[index] != ",":
            return opening_brace + 1

        placeholders.add(name)
        index = _skip_space(message, index + 1)
        format_match = IDENTIFIER.match(message, index)
        if format_match is None:
            return opening_brace + 1

        format_name = format_match.group(0).lower()
        index = _skip_space(message, format_match.end())
        if format_name not in COMPLEX_FORMATS:
            depth = 1
            while index < len(message) and depth:
                if message[index] == "'":
                    index = _skip_icu_quote(message, index)
                elif message[index] == "{":
                    depth += 1
                    index += 1
                elif message[index] == "}":
                    depth -= 1
                    index += 1
                else:
                    index += 1
            return index

        if index < len(message) and message[index] == ",":
            index += 1

        # At this level every opening brace starts a plural/select branch.
        # Its body is a regular ICU message and can contain nested arguments.
        while index < len(message):
            if message[index] == "'":
                index = _skip_icu_quote(message, index)
            elif message[index] == "{":
                index = parse_message(
                    index + 1,
                    stop_at_closing_brace=True,
                )
            elif message[index] == "}":
                return index + 1
            else:
                index += 1
        return index

    parse_message(0, stop_at_closing_brace=False)
    return placeholders


def _message_keys(catalog: Catalog) -> set[str]:
    return {key for key in catalog if not key.startswith("@")}


def _metadata_keys(catalog: Catalog) -> set[str]:
    return {
        key[1:]
        for key in catalog
        if key.startswith("@") and not key.startswith("@@")
    }


def _placeholder_metadata(
    catalog: Catalog,
    key: str,
    locale: str,
    issues: list[str],
) -> dict[str, Any]:
    metadata = catalog.get(f"@{key}")
    if metadata is None:
        return {}
    if not isinstance(metadata, Mapping):
        issues.append(
            f"[{locale}:{key}] metadata must be an object, "
            f"got {type(metadata).__name__}"
        )
        return {}

    placeholders = metadata.get("placeholders", {})
    if not isinstance(placeholders, Mapping):
        issues.append(f"[{locale}:{key}] placeholder metadata must be an object")
        return {}
    return dict(placeholders)


def check_catalogs(de_catalog: Catalog, en_catalog: Catalog) -> list[str]:
    """Return deterministic, human-readable validation issues."""

    issues: list[str] = []
    de_keys = _message_keys(de_catalog)
    en_keys = _message_keys(en_catalog)

    for key in sorted(de_keys - en_keys):
        issues.append(f"[en:{key}] message key is missing")
    for key in sorted(en_keys - de_keys):
        issues.append(f"[de:{key}] message key is missing")

    de_metadata_keys = _metadata_keys(de_catalog)
    en_metadata_keys = _metadata_keys(en_catalog)
    for key in sorted(de_metadata_keys - en_metadata_keys):
        issues.append(f"[en:@{key}] metadata key is missing")
    for key in sorted(en_metadata_keys - de_metadata_keys):
        issues.append(f"[de:@{key}] metadata key is missing")

    for locale, catalog, keys in (
        ("de", de_catalog, de_keys),
        ("en", en_catalog, en_keys),
    ):
        for key in sorted(keys):
            value = catalog[key]
            if not isinstance(value, str):
                issues.append(
                    f"[{locale}:{key}] value must be a string, "
                    f"got {type(value).__name__}"
                )
            elif not value.strip():
                issues.append(f"[{locale}:{key}] value is empty")
            if (
                locale == "en"
                and isinstance(value, str)
                and GERMAN_UMLAUT.search(value)
            ):
                issues.append(f"[en:{key}] value contains a German umlaut or ß")

    for key in sorted(de_keys & en_keys):
        de_value = de_catalog[key]
        en_value = en_catalog[key]
        if not isinstance(de_value, str) or not isinstance(en_value, str):
            continue

        de_placeholders = extract_placeholders(de_value)
        en_placeholders = extract_placeholders(en_value)
        if de_placeholders != en_placeholders:
            issues.append(
                f"[{key}] placeholder sets differ: "
                f"de={sorted(de_placeholders)}, en={sorted(en_placeholders)}"
            )

        de_metadata = _placeholder_metadata(de_catalog, key, "de", issues)
        en_metadata = _placeholder_metadata(en_catalog, key, "en", issues)
        if set(de_metadata) != de_placeholders:
            issues.append(
                f"[de:{key}] placeholder metadata differs from message: "
                f"message={sorted(de_placeholders)}, "
                f"metadata={sorted(de_metadata)}"
            )
        if set(en_metadata) != en_placeholders:
            issues.append(
                f"[en:{key}] placeholder metadata differs from message: "
                f"message={sorted(en_placeholders)}, "
                f"metadata={sorted(en_metadata)}"
            )
        if de_metadata != en_metadata:
            issues.append(f"[{key}] placeholder metadata differs between de and en")

    return issues


def load_catalog(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as arb_file:
        catalog = json.load(arb_file)
    if not isinstance(catalog, dict):
        raise ValueError("ARB root must be a JSON object")
    return catalog


def check_files(de_path: Path, en_path: Path) -> tuple[list[str], int]:
    load_issues: list[str] = []
    catalogs: dict[str, dict[str, Any]] = {}
    for locale, path in (("de", de_path), ("en", en_path)):
        try:
            catalogs[locale] = load_catalog(path)
        except (OSError, json.JSONDecodeError, ValueError) as error:
            load_issues.append(f"[{locale}] could not read {path}: {error}")

    if load_issues:
        return load_issues, 0

    issues = check_catalogs(catalogs["de"], catalogs["en"])
    return issues, len(_message_keys(catalogs["de"]))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--de", type=Path, default=DEFAULT_DE_ARB)
    parser.add_argument("--en", type=Path, default=DEFAULT_EN_ARB)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    issues, key_count = check_files(args.de, args.en)
    if issues:
        print(f"i18n check failed with {len(issues)} issue(s):", file=sys.stderr)
        for issue in issues:
            print(f"- {issue}", file=sys.stderr)
        return 1

    print(f"i18n check passed: {key_count} DE/EN message keys are in parity.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
