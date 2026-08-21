# Lessons Learned

Patterns and rules captured after corrections — updated by Claude after any mistake.

---

## 2026-07-02 — `git mv` stages immediately; check the index before every commit

`git mv` puts the rename into the index right away. A later `git add <file> &&
git commit` then sweeps the staged rename into that unrelated commit (had to
soft-reset and recommit). Rule: immediately before any commit, run
`git diff --cached --name-status` and confirm the staged list contains exactly
the files named in the commit plan — nothing inherited from earlier commands.

## 2026-07-04 — Never write an evidence reference before the evidence exists

While drafting a plan in todo.md, a commit hash was written into a ticked
checkbox before the commit was made (caught and reverted in-session). Rule:
evidence notes (hashes, test counts, "verified" claims) are written only
AFTER the referenced action ran — draft plans use unchecked boxes and
placeholders, never invented identifiers.

## 2026-07-02 — Don't chain mutating git commands with long-running ones

A combined `git mv … && supabase db reset` was rejected by the founder; run
repo mutations as single-purpose commands so each step is individually
auditable, then run the long verification step separately.

## 2026-08-21 — Founder-Entscheidungen zur Darstellung gehören in den Plan, nicht nur in den Chat

Der Founder hatte in einer früheren Sitzung entschieden, dass der
Amphibienreflex ohne Rechtfertigungstext dargestellt wird — schlicht eine
andere Anzeigeform, kein Absatz über zu wenige Merkmale. Diese Entscheidung
landete nirgends im Plan; dort stand an drei Stellen weiter „Pflicht-Zusatztext"
aus dem Quelldokument. Beim Review von Phase 7 habe ich das Fehlen des Satzes
als Fehler gemeldet und ihn einbauen lassen — also genau die Vorgabe
durchgesetzt, die der Founder abgelehnt hatte. Kostete zwei Runden.

Rule: Jede Founder-Entscheidung, die von einem Quelldokument abweicht, wird
sofort an der Stelle im Plan festgehalten, die sonst das Gegenteil verlangt —
mit Begründung und mit einem Eintrag in der Blocker-Liste, damit die spätere
Fachprüfung sie als Entscheidung sieht und nicht als Versehen. Ein Quelldokument
schlägt nie eine Founder-Entscheidung.

## 2026-08-21 — Vor Umsetzungs-Prompts erst in einfachen Worten beschreiben und bestätigen lassen

Mehrere Prompts an Cursor gingen raus, ohne dass der Founder vorher wusste, was
konkret gebaut wird — er sieht das Ergebnis erst nach der Umsetzung, und
Korrekturen kosten dann eine volle Runde. Rule: vor jedem Umsetzungsauftrag drei
bis sechs Sätze Alltagssprache, keine Dateinamen, keine Paragraphenverweise,
dann auf das Go warten.
