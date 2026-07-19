#!/usr/bin/env python3

from __future__ import annotations

import io
import json
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

from scripts.i18n_quality_check import check_catalogs, main


def catalogs(en_values: dict[str, str]) -> tuple[dict, dict]:
    de = {"@@locale": "de"}
    en = {"@@locale": "en"}
    for key, value in en_values.items():
        de[key] = f"Deutscher Wert fuer {key}"
        en[key] = value
    return de, en


def allowlist(
    *,
    identical: dict | None = None,
    claims: dict | None = None,
) -> dict:
    return {
        "identical_values": identical or {},
        "claim_terms": claims or {},
    }


class GlossaryAndSpellingTest(unittest.TestCase):
    def test_reports_unit_terms_but_not_substrings_or_simple_placeholders(self):
        de, en = catalogs(
            {
                "singular": "Complete this unit.",
                "plural": "Your units are ready.",
                "substring": "Join the community for this opportunity.",
                "placeholder": "Completed {unit} today.",
            }
        )

        issues = check_catalogs(de, en)

        self.assertEqual(
            issues,
            [
                "[glossary-unit:plural] forbidden term 'units'; use 'session'",
                "[glossary-unit:singular] forbidden term 'unit'; use 'session'",
            ],
        )

    def test_reports_relevant_british_spellings_with_us_replacements(self):
        de, en = catalogs(
            {
                "cancel": "The programme was cancelled.",
                "style": "Choose your favourite colour.",
            }
        )

        issues = check_catalogs(de, en)

        self.assertEqual(
            issues,
            [
                "[en-us-spelling:cancel] British spelling 'cancelled'; use 'canceled'",
                "[en-us-spelling:cancel] British spelling 'programme'; use 'program'",
                "[en-us-spelling:style] British spelling 'colour'; use 'color'",
                "[en-us-spelling:style] British spelling 'favourite'; use 'favorite'",
            ],
        )


class RegulatoryClaimTest(unittest.TestCase):
    def test_reports_claim_words_and_inflections_without_flagging_health(self):
        de, en = catalogs(
            {
                "claims": (
                    "Clinically proven therapy can diagnose, treat, cure, and heal "
                    "medical conditions."
                ),
                "safe": "Track healthy daily habits.",
            }
        )

        issues = check_catalogs(de, en)

        claim_terms = {
            issue.split("'")[1]
            for issue in issues
            if issue.startswith("[regulatory-claim:claims]")
        }
        self.assertEqual(
            claim_terms,
            {
                "clinically proven",
                "treat",
                "cure",
                "heal",
                "therapy",
                "diagnose",
                "medical",
            },
        )
        self.assertFalse(any(":safe]" in issue for issue in issues))

    def test_accepts_only_typed_exact_claim_exceptions(self):
        de, en = catalogs(
            {
                "legal": "This does not replace medical care.",
                "source": "Movements That Heal",
            }
        )
        exceptions = allowlist(
            claims={
                "legal": {
                    "kind": "lawyer-owned",
                    "reason": "Reviewed safety disclaimer.",
                },
                "source": {
                    "kind": "source-title",
                    "reason": "Verbatim publication title.",
                },
            }
        )

        self.assertEqual(check_catalogs(de, en, exceptions), [])

    def test_lawyer_owned_exception_preserves_legacy_unit_wording(self):
        de, en = catalogs(
            {"legal": "These units do not replace medical treatment."}
        )
        exceptions = allowlist(
            claims={
                "legal": {
                    "kind": "lawyer-owned",
                    "reason": "Exact legal wording requires counsel review.",
                }
            }
        )

        self.assertEqual(check_catalogs(de, en, exceptions), [])

    def test_invalid_claim_exception_does_not_suppress_the_claim(self):
        de, en = catalogs({"claim": "This therapy treats pain."})
        invalid = allowlist(
            claims={
                "claim": {
                    "kind": "marketing-approved",
                    "reason": "Not a permitted exception type.",
                }
            }
        )

        issues = check_catalogs(de, en, invalid)

        self.assertIn(
            "[allowlist:claim_terms:claim] kind must be one of: "
            "lawyer-owned, source-title",
            issues,
        )
        self.assertTrue(
            any(issue.startswith("[regulatory-claim:claim]") for issue in issues)
        )


class IdenticalValueAllowlistTest(unittest.TestCase):
    def test_requires_an_individual_reason_for_each_identical_key(self):
        de = {"@@locale": "de", "shared": "Dashboard", "missed": "Pause"}
        en = {"@@locale": "en", "shared": "Dashboard", "missed": "Pause"}
        exceptions = allowlist(
            identical={"shared": "Dashboard is identical in both languages."}
        )

        issues = check_catalogs(de, en, exceptions)

        self.assertEqual(
            issues,
            [
                "[identical-value:missed] DE and EN values are identical; "
                "allowlist this exact key with a reason or translate it"
            ],
        )

    def test_wildcards_are_rejected_and_do_not_suppress_exact_keys(self):
        de = {"@@locale": "de", "shared": "Dashboard"}
        en = {"@@locale": "en", "shared": "Dashboard"}
        invalid = allowlist(identical={"*": "Suppress all identical values."})

        issues = check_catalogs(de, en, invalid)

        self.assertIn(
            "[allowlist:identical_values:*] wildcards are forbidden",
            issues,
        )
        self.assertTrue(any(issue.startswith("[identical-value:shared]") for issue in issues))

    def test_reports_stale_or_unexplained_allowlist_entries(self):
        de = {"@@locale": "de", "changed": "Deutsch"}
        en = {"@@locale": "en", "changed": "English"}
        stale = allowlist(
            identical={
                "changed": "Used to be shared.",
                "missing": "No longer exists.",
                "noReason": "",
            }
        )

        issues = check_catalogs(de, en, stale)

        self.assertIn(
            "[allowlist:identical_values:changed] values are no longer identical",
            issues,
        )
        self.assertIn(
            "[allowlist:identical_values:missing] key is missing from a catalog",
            issues,
        )
        self.assertIn(
            "[allowlist:identical_values:noReason] reason must be non-empty",
            issues,
        )

    def test_metadata_is_out_of_scope_for_the_copy_quality_gate(self):
        de, en = catalogs({"safe": "Continue"})
        en["@safe"] = {
            "description": "A medical therapy programme after one unit"
        }

        self.assertEqual(check_catalogs(de, en), [])


class CliTest(unittest.TestCase):
    def test_cli_reports_keyed_failures_and_returns_one(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            de_path = directory / "de.arb"
            en_path = directory / "en.arb"
            allowlist_path = directory / "allowlist.json"
            de_path.write_text(
                json.dumps({"@@locale": "de", "copy": "Sitzung"}),
                encoding="utf-8",
            )
            en_path.write_text(
                json.dumps({"@@locale": "en", "copy": "One unit"}),
                encoding="utf-8",
            )
            allowlist_path.write_text(
                json.dumps(allowlist()),
                encoding="utf-8",
            )
            stderr = io.StringIO()
            with redirect_stderr(stderr):
                result = main(
                    [
                        "--de",
                        str(de_path),
                        "--en",
                        str(en_path),
                        "--allowlist",
                        str(allowlist_path),
                    ]
                )

        self.assertEqual(result, 1)
        self.assertIn("i18n quality check failed with 1 issue(s)", stderr.getvalue())
        self.assertIn("[glossary-unit:copy]", stderr.getvalue())

    def test_catalog_without_rules_is_skipped_with_a_notice_and_en_still_gated(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            de_path = directory / "app_de.arb"
            en_path = directory / "app_en.arb"
            fr_path = directory / "app_fr.arb"
            allowlist_path = directory / "allowlist.json"
            de_path.write_text(
                json.dumps({"@@locale": "de", "copy": "Sitzung"}),
                encoding="utf-8",
            )
            en_path.write_text(
                json.dumps({"@@locale": "en", "copy": "Session"}),
                encoding="utf-8",
            )
            fr_path.write_text(
                json.dumps({"@@locale": "fr", "copy": "Séance"}),
                encoding="utf-8",
            )
            allowlist_path.write_text(json.dumps(allowlist()), encoding="utf-8")
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                result = main(
                    [
                        "--de",
                        str(de_path),
                        "--en",
                        str(en_path),
                        "--allowlist",
                        str(allowlist_path),
                    ]
                )

        self.assertEqual(result, 0)
        self.assertIn(
            "app_fr.arb: no quality rules defined yet — "
            "add them when the language ships",
            stdout.getvalue(),
        )
        self.assertIn("i18n quality check passed", stdout.getvalue())


if __name__ == "__main__":
    unittest.main()
