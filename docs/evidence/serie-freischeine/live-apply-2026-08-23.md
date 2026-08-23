# streak_credits — Live-Anwendung 2026-08-23

Founder-Freigabe erteilt am 2026-08-23. Angewendet wurde ausschließlich
`supabase/migrations/2026082301_streak_credits.sql`.

**Bewusst NICHT `supabase db push` verwendet.** Der Vergleich vorher zeigte neun
Tabellen, die nur im Repo existieren — acht davon gehören zu Vorhaben, die
absichtlich nicht live sind (Gutscheine, Berechtigungen, Rollout-Schalter,
Empfehlungsprogramm). Ein `push` hätte alle mit angelegt. Stattdessen wurde die
eine Datei direkt ausgeführt.

## Vorher (read-only)

- 39 Tabellen live, `streak_credits` nicht vorhanden
- keine Tabelle live, die im Repo fehlt
- zwei Spalten-Abweichungen (beide inzwischen behoben, siehe unten)

## Anwendung

Antwort der Query-API: `[]` — kein Fehler, keine Rückgabezeilen.

## Nachher (read-only verifiziert)

| Prüfung | Ergebnis |
|---|---|
| Spalten | 8 — id text NOT NULL, user_id uuid NOT NULL, subject_profile_id uuid NOT NULL, available integer NOT NULL, progress_to_next integer NOT NULL, last_counted_day date, rescued_days ARRAY NOT NULL, updated_at timestamptz NOT NULL |
| Row Level Security | aktiv (`true`) |
| Policies | 2 (`all own` für den Eigentümer, `trainer read` über aktive Beziehung) |
| Fremdschlüssel | 2 (profiles, reflex_subject_profiles — beide ON DELETE CASCADE) |
| Zeilen | 0 |

## Reichweite und Rücknahme

Additiv. Keine bestehende Zeile gelesen, geändert oder gelöscht, keine
bestehende Spalte angefasst. Rücknahme: `DROP TABLE public.streak_credits;`

## Restliche Drift — behoben am selben Tag

`2026082302_journal_day_key_and_profile_anonymous_default.sql` schließt die
letzten beiden Abweichungen. Sie waren unterschiedlicher Natur:

- `journal_entries.day_key` **fehlte nicht**. Die Basis-Migration legt sie als
  `integer` an, live steht `bigint`. Der erste Vergleich listete Name **und**
  Typ, deshalb sah es nach einer fehlenden Spalte aus. Funktional harmlos
  (Epochentag, weit innerhalb des Wertebereichs), jetzt trotzdem angeglichen.
- `profiles.is_anonymous_default` fehlte tatsächlich — keine Migration legt sie
  an, obwohl `Profile.fromJson/toJson` sie liest und schreibt.

**Ergebnis des erneuten Vollvergleichs:** Keine einzige Spalte existiert mehr
live, die das Repo nicht beschreibt. Der verbleibende Unterschied (498 lokal
gegen 414 live) sind ausschließlich die acht Tabellen, die absichtlich nicht
live sind.

## Offen

`2026072300_exercise_columns_and_moro_seed.sql` und
`2026082302_journal_day_key_and_profile_anonymous_default.sql` sind **nicht**
live angewendet —
dort ist sie ohnehin ein No-op (alles `IF NOT EXISTS` / `ON CONFLICT DO NOTHING`).
Sie fehlt damit in der Migrationshistorie der Live-Datenbank; das ist bei einem
späteren `db push` zu berücksichtigen.
