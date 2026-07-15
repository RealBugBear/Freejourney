#!/usr/bin/env python3
"""Check English ARB copy against launch glossary and regulatory rules.

This gate complements ``i18n_check.py``. It deliberately does not validate
ARB parity, metadata, or ICU syntax; those checks already have one owner.
Only message values (keys that do not start with ``@``) are inspected here.
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
DEFAULT_ALLOWLIST = REPO_ROOT / "scripts" / "i18n_quality_allowlist.json"

Catalog = Mapping[str, Any]
Allowlist = Mapping[str, Any]

SIMPLE_PLACEHOLDER = re.compile(r"\{\s*[A-Za-z][A-Za-z0-9_]*\s*\}")
UNIT_TERM = re.compile(r"\bunits?\b", re.IGNORECASE)
WILDCARD_CHARACTERS = frozenset("*?[]")

BRITISH_TO_US = {
    "analyse": "analyze",
    "analysed": "analyzed",
    "analysing": "analyzing",
    "behaviour": "behavior",
    "behavioural": "behavioral",
    "behaviours": "behaviors",
    "cancelled": "canceled",
    "cancelling": "canceling",
    "centre": "center",
    "centred": "centered",
    "centres": "centers",
    "centring": "centering",
    "colour": "color",
    "coloured": "colored",
    "colouring": "coloring",
    "colours": "colors",
    "defence": "defense",
    "defences": "defenses",
    "favourite": "favorite",
    "favourited": "favorited",
    "favourites": "favorites",
    "favouriting": "favoriting",
    "fulfil": "fulfill",
    "fulfilment": "fulfillment",
    "fulfils": "fulfills",
    "grey": "gray",
    "labelled": "labeled",
    "labelling": "labeling",
    "licence": "license",
    "licenced": "licensed",
    "licences": "licenses",
    "licencing": "licensing",
    "offence": "offense",
    "offences": "offenses",
    "organisation": "organization",
    "organisations": "organizations",
    "organise": "organize",
    "organised": "organized",
    "organiser": "organizer",
    "organisers": "organizers",
    "organises": "organizes",
    "organising": "organizing",
    "practise": "practice",
    "practised": "practiced",
    "practises": "practices",
    "practising": "practicing",
    "programme": "program",
    "programmes": "programs",
    "recognise": "recognize",
    "recognised": "recognized",
    "recognises": "recognizes",
    "recognising": "recognizing",
    "travelled": "traveled",
    "traveller": "traveler",
    "travellers": "travelers",
    "travelling": "traveling",
}
BRITISH_TERM = re.compile(
    r"\b(?:"
    + "|".join(
        re.escape(term)
        for term in sorted(BRITISH_TO_US, key=len, reverse=True)
    )
    + r")\b",
    re.IGNORECASE,
)

CLAIM_PATTERNS = {
    "clinically proven": re.compile(r"\bclinically\s+proven\b", re.IGNORECASE),
    "treat": re.compile(r"\btreat(?:s|ed|ing)?\b", re.IGNORECASE),
    "cure": re.compile(r"\b(?:cure(?:s|d)?|curing)\b", re.IGNORECASE),
    "heal": re.compile(r"\bheal(?:s|ed|ing)?\b", re.IGNORECASE),
    "therapy": re.compile(
        r"\btherap(?:y|ies|eutic|eutics?)\b",
        re.IGNORECASE,
    ),
    "diagnose": re.compile(
        r"\bdiagnos(?:e|es|ed|ing|is|tic|tics)\b",
        re.IGNORECASE,
    ),
    "medical": re.compile(r"\bmedical\b", re.IGNORECASE),
}
CLAIM_EXCEPTION_KINDS = {"lawyer-owned", "source-title"}
ALLOWLIST_SECTIONS = {"identical_values", "claim_terms"}


def _message_values(catalog: Catalog) -> dict[str, str]:
    return {
        key: value
        for key, value in catalog.items()
        if not key.startswith("@") and isinstance(value, str)
    }


def _copy_text(value: str) -> str:
    """Mask simple ICU variables without parsing or duplicating ICU checks."""

    return SIMPLE_PLACEHOLDER.sub(" ", value)


def _has_wildcard(key: str) -> bool:
    return any(character in key for character in WILDCARD_CHARACTERS)


def _parse_allowlist(
    raw_allowlist: Allowlist,
) -> tuple[dict[str, str], dict[str, dict[str, str]], list[str]]:
    issues: list[str] = []
    identical: dict[str, str] = {}
    claims: dict[str, dict[str, str]] = {}

    unknown_sections = sorted(set(raw_allowlist) - ALLOWLIST_SECTIONS)
    for section in unknown_sections:
        issues.append(f"[allowlist:{section}] unknown section")

    raw_identical = raw_allowlist.get("identical_values", {})
    if not isinstance(raw_identical, Mapping):
        issues.append("[allowlist:identical_values] section must be an object")
    else:
        for key, reason in sorted(raw_identical.items()):
            if not isinstance(key, str) or not key.strip():
                issues.append(
                    "[allowlist:identical_values] every key must be a non-empty string"
                )
                continue
            if _has_wildcard(key):
                issues.append(
                    f"[allowlist:identical_values:{key}] wildcards are forbidden"
                )
                continue
            if not isinstance(reason, str) or not reason.strip():
                issues.append(
                    f"[allowlist:identical_values:{key}] reason must be non-empty"
                )
                continue
            identical[key] = reason.strip()

    raw_claims = raw_allowlist.get("claim_terms", {})
    if not isinstance(raw_claims, Mapping):
        issues.append("[allowlist:claim_terms] section must be an object")
    else:
        for key, exception in sorted(raw_claims.items()):
            if not isinstance(key, str) or not key.strip():
                issues.append(
                    "[allowlist:claim_terms] every key must be a non-empty string"
                )
                continue
            if _has_wildcard(key):
                issues.append(f"[allowlist:claim_terms:{key}] wildcards are forbidden")
                continue
            if not isinstance(exception, Mapping):
                issues.append(
                    f"[allowlist:claim_terms:{key}] exception must be an object"
                )
                continue

            kind = exception.get("kind")
            reason = exception.get("reason")
            if kind not in CLAIM_EXCEPTION_KINDS:
                allowed = ", ".join(sorted(CLAIM_EXCEPTION_KINDS))
                issues.append(
                    f"[allowlist:claim_terms:{key}] kind must be one of: {allowed}"
                )
                continue
            if not isinstance(reason, str) or not reason.strip():
                issues.append(f"[allowlist:claim_terms:{key}] reason must be non-empty")
                continue
            claims[key] = {"kind": str(kind), "reason": reason.strip()}

    return identical, claims, issues


def _claim_terms(value: str) -> list[str]:
    text = _copy_text(value)
    return [
        term
        for term, pattern in CLAIM_PATTERNS.items()
        if pattern.search(text)
    ]


def check_catalogs(
    de_catalog: Catalog,
    en_catalog: Catalog,
    raw_allowlist: Allowlist | None = None,
) -> list[str]:
    """Return deterministic quality issues without duplicating parity checks."""

    if raw_allowlist is None:
        raw_allowlist = {}
    identical_allowlist, claim_allowlist, issues = _parse_allowlist(raw_allowlist)

    de_values = _message_values(de_catalog)
    en_values = _message_values(en_catalog)

    for key in sorted(identical_allowlist):
        if key not in de_values or key not in en_values:
            issues.append(
                f"[allowlist:identical_values:{key}] key is missing from a catalog"
            )
        elif de_values[key] != en_values[key]:
            issues.append(
                f"[allowlist:identical_values:{key}] values are no longer identical"
            )

    for key in sorted(claim_allowlist):
        if key not in en_values:
            issues.append(f"[allowlist:claim_terms:{key}] key is missing from English")
        elif not _claim_terms(en_values[key]):
            issues.append(
                f"[allowlist:claim_terms:{key}] value no longer contains a claim term"
            )

    for key in sorted(en_values):
        text = _copy_text(en_values[key])

        # Lawyer-owned copy must remain byte-for-byte stable until legal review.
        # The exact typed exception therefore also protects legacy glossary
        # terms inside that legal text; ordinary product copy is never exempt.
        is_lawyer_owned = (
            claim_allowlist.get(key, {}).get("kind") == "lawyer-owned"
        )
        if not is_lawyer_owned:
            unit_matches = sorted(
                {match.group(0).lower() for match in UNIT_TERM.finditer(text)}
            )
            for term in unit_matches:
                issues.append(
                    f"[glossary-unit:{key}] forbidden term '{term}'; "
                    "use 'session'"
                )

        british_matches = sorted(
            {match.group(0).lower() for match in BRITISH_TERM.finditer(text)}
        )
        for term in british_matches:
            issues.append(
                f"[en-us-spelling:{key}] British spelling '{term}'; "
                f"use '{BRITISH_TO_US[term]}'"
            )

        if key not in claim_allowlist:
            for term in _claim_terms(en_values[key]):
                issues.append(
                    f"[regulatory-claim:{key}] prohibited claim term '{term}'; "
                    "only exact lawyer-owned or source-title exceptions are allowed"
                )

    for key in sorted(de_values.keys() & en_values.keys()):
        if de_values[key] == en_values[key] and key not in identical_allowlist:
            issues.append(
                f"[identical-value:{key}] DE and EN values are identical; "
                "allowlist this exact key with a reason or translate it"
            )

    return sorted(issues)


def load_json_object(path: Path, label: str) -> dict[str, Any]:
    with path.open(encoding="utf-8") as json_file:
        value = json.load(json_file)
    if not isinstance(value, dict):
        raise ValueError(f"{label} root must be a JSON object")
    return value


def check_files(
    de_path: Path,
    en_path: Path,
    allowlist_path: Path,
) -> tuple[list[str], int]:
    loaded: dict[str, dict[str, Any]] = {}
    load_issues: list[str] = []
    for label, path in (
        ("de", de_path),
        ("en", en_path),
        ("allowlist", allowlist_path),
    ):
        try:
            loaded[label] = load_json_object(path, label)
        except (OSError, json.JSONDecodeError, ValueError) as error:
            load_issues.append(f"[config:{label}] could not read {path}: {error}")

    if load_issues:
        return sorted(load_issues), 0

    issues = check_catalogs(loaded["de"], loaded["en"], loaded["allowlist"])
    return issues, len(_message_values(loaded["en"]))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--de", type=Path, default=DEFAULT_DE_ARB)
    parser.add_argument("--en", type=Path, default=DEFAULT_EN_ARB)
    parser.add_argument("--allowlist", type=Path, default=DEFAULT_ALLOWLIST)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    issues, key_count = check_files(args.de, args.en, args.allowlist)
    if issues:
        print(
            f"i18n quality check failed with {len(issues)} issue(s) "
            f"across {key_count} English message keys:",
            file=sys.stderr,
        )
        for issue in issues:
            print(f"- {issue}", file=sys.stderr)
        return 1

    print(f"i18n quality check passed: {key_count} English message keys checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
