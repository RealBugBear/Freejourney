#!/usr/bin/env python3

import unittest

from scripts.i18n_audit import (
    categorize,
    extract_strings,
    is_detection_literal,
    is_exception_literal,
    is_http_header_literal,
    is_log_literal,
    is_query_projection_literal,
    is_regexp_literal,
    is_technical,
)


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


class TechnicalClassificationTest(unittest.TestCase):
    def test_internal_asset_suffix_is_technical(self):
        self.assertTrue(is_technical("_duo"))
        self.assertTrue(is_technical("Bootstrap Debug.txt"))
        self.assertTrue(is_technical("Bootstrap Debug.log"))
        self.assertFalse(is_technical("_ Try again"))
        self.assertFalse(is_technical("Read the log"))

    def test_technical_patterns_keep_visible_counterexamples(self):
        cases = [
            ("SQLite sidecar", "-wal", "- Try again"),
            ("Android resource", "@mipmap/ic_launcher", "@alex"),
            (
                "channel namespace",
                "corejourney/timezone",
                "reflexjourney.app/datenschutz.",
            ),
            ("realtime channel", "typing:⟦…⟧", "Status: ready"),
            ("calendar URL", "calshow:⟦…⟧", "Calendar: today"),
            ("dotenv file", ".env.prod", "Environment: production"),
            (
                "Sentry release",
                "reflexjourney@⟦…⟧+⟦…⟧",
                "support@example.com",
            ),
            (
                "Sentry fallback release",
                "reflexjourney@unknown",
                "Release unknown",
            ),
            ("Dart VM pragma", "vm:entry-point", "Entry point unavailable"),
            (
                "iCalendar UID",
                "reflexjourney-⟦…⟧-⟦…⟧@reflexjourney.app",
                "Appointment ID: 42",
            ),
            (
                "iCalendar UTC value",
                "⟦…⟧⟦…⟧⟦…⟧T⟦…⟧⟦…⟧⟦…⟧Z",
                "Today at 10:00 UTC",
            ),
            ("log field", "for=⟦…⟧", "For today"),
            ("auth value", "Bearer ⟦…⟧", "Bearer access"),
            (
                "scoped setting",
                "settings.themeMode_⟦…⟧",
                "Settings: Dark",
            ),
            ("date pattern", "EEE, d. MMM · HH:mm", "Today at 10:00"),
            ("file date pattern", "yyyyMMdd_HHmm", "Report from today"),
        ]

        for label, technical, visible in cases:
            with self.subTest(label=label, direction="positive"):
                self.assertTrue(is_technical(technical))
            with self.subTest(label=label, direction="negative"):
                self.assertFalse(is_technical(visible))

    def test_date_pattern_tokens_do_not_hide_visible_words(self):
        self.assertTrue(is_technical("EEE, d. MMM · HH:mm"))
        self.assertFalse(is_technical("May"))
        self.assertFalse(is_technical("Today"))

    def test_query_projection_is_technical_but_ui_copy_is_not(self):
        query = "client.from('profiles').select('*, owner(display_name)');"
        ui = "return Text('Choose a profile');"

        query_literal = next(
            start for _, text, start in extract_strings(query) if text.startswith("*")
        )
        ui_literal = next(
            start for _, text, start in extract_strings(ui) if text == "Choose a profile"
        )

        self.assertTrue(is_query_projection_literal(query, query_literal))
        self.assertFalse(is_query_projection_literal(ui, ui_literal))

    def test_regexp_is_technical_but_matching_ui_copy_is_not(self):
        regex = "value.split(RegExp(r'[^A-Za-z0-9]+'));"
        ui = "return Text('[Letters and numbers only]');"

        regex_literal = extract_strings(regex)[0][2]
        ui_literal = extract_strings(ui)[0][2]

        self.assertTrue(is_regexp_literal(regex, regex_literal))
        self.assertFalse(is_regexp_literal(ui, ui_literal))

    def test_http_header_context_does_not_hide_visible_authorization_copy(self):
        request = "invoke(headers: {'Authorization': 'Bearer $token'});"
        labels = "final labels = {'Authorization': 'Required'};"
        ui = "return Text('Authorization');"

        request_literal = extract_strings(request)[0]
        labels_literal = extract_strings(labels)[0]
        ui_literal = extract_strings(ui)[0]

        self.assertTrue(
            is_http_header_literal(request_literal[1], request, request_literal[2])
        )
        self.assertFalse(
            is_http_header_literal(labels_literal[1], labels, labels_literal[2])
        )
        self.assertFalse(is_http_header_literal(ui_literal[1], ui, ui_literal[2]))

    def test_project_debug_helpers_only_classify_their_own_literals_as_logs(self):
        log_sources = [
            "appLogger.i('Application diagnostic');",
            "logger.warning('Service diagnostic');",
            "log.d('Repository diagnostic');",
            "_dbg('Notification initialization started');",
            "dev.log('Unhandled platform error');",
            "debugPrint('Bootstrap failed');",
            "print('Debug fallback');",
            "_debugFile.writeAsString('BOOTSTRAP START');",
            "Sentry.captureException(error, hint: 'capture hint');",
            "SentryService.captureException(error, context: 'capture context');",
            "final crumb = Breadcrumb(message: 'navigation crumb');",
            "NotificationService.instance.disable('profile safe mode');",
        ]

        for src in log_sources:
            literal = extract_strings(src)[0]
            with self.subTest(src=src):
                self.assertTrue(is_log_literal(src, literal[2]))

        ui_after_log = (
            "appLogger.e('Video engine failed');\n"
            "return Text('Video call could not start');"
        )
        ui_literal = next(
            item
            for item in extract_strings(ui_after_log)
            if item[1] == "Video call could not start"
        )
        sentry_ui = "return Text('Sentry is inactive');"
        sentry_literal = extract_strings(sentry_ui)[0]
        ordinary_file_write = "reportFile.writeAsString('Visible report content');"
        ordinary_file_literal = extract_strings(ordinary_file_write)[0]

        self.assertFalse(is_log_literal(ui_after_log, ui_literal[2]))
        self.assertFalse(is_log_literal(sentry_ui, sentry_literal[2]))
        self.assertFalse(
            is_log_literal(ordinary_file_write, ordinary_file_literal[2])
        )
        self.assertEqual(
            categorize(
                "core/services/notification_service.dart",
                "Text('Visible notification copy')",
                [],
            ),
            "c-push",
        )

    def test_multiline_log_fragments_keep_log_context(self):
        src = (
            "appLogger.i(\n"
            "  'Pulled $enrollments enrollments, '\n"
            "  '$sessions training sessions, '\n"
            "  '$entries journal entries',\n"
            ");"
        )

        for _, _, start in extract_strings(src):
            self.assertTrue(is_log_literal(src, start))

    def test_bare_logger_methods_are_limited_to_logger_service(self):
        src = "info('User action: $action');"
        literal = extract_strings(src)[0]

        self.assertTrue(
            is_log_literal(
                src,
                literal[2],
                "lib/core/logging/logger_service.dart",
            )
        )
        self.assertFalse(
            is_log_literal(
                src,
                literal[2],
                "lib/features/profile/presentation/profile_screen.dart",
            )
        )

    def test_exception_context_does_not_hide_following_ui_error(self):
        src = (
            "throw StateError('Internal invariant failed');\n"
            "return Text('Something went wrong');"
        )
        internal = next(
            item for item in extract_strings(src) if item[1] == "Internal invariant failed"
        )
        visible = next(
            item for item in extract_strings(src) if item[1] == "Something went wrong"
        )

        self.assertTrue(is_exception_literal(src, internal[2]))
        self.assertFalse(is_exception_literal(src, visible[2]))


if __name__ == "__main__":
    unittest.main()
