#!/usr/bin/env python3

import unittest

from scripts.i18n_audit import extract_strings, is_detection_literal


class DetectionLiteralTest(unittest.TestCase):
    def _classification(self, src: str) -> dict[str, bool]:
        return {
            text: is_detection_literal(src, start)
            for _, text, start in extract_strings(src)
        }

    def test_contains_does_not_hide_visible_copy_on_same_line(self):
        result = self._classification(
            "if (value.contains('@')) return 'Kein @ erlaubt';"
        )

        self.assertTrue(result["@"])
        self.assertFalse(result["Kein @ erlaubt"])

    def test_ternary_only_ignores_compared_literal(self):
        result = self._classification(
            "label: code == 'de' ? 'Deutsch' : 'English',"
        )

        self.assertTrue(result["de"])
        self.assertFalse(result["Deutsch"])
        self.assertFalse(result["English"])

    def test_case_label_is_detection_but_return_value_is_visible(self):
        result = self._classification("case 'done': return 'Fertig';")

        self.assertTrue(result["done"])
        self.assertFalse(result["Fertig"])


if __name__ == "__main__":
    unittest.main()
