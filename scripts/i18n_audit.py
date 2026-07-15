#!/usr/bin/env python3
"""i18n audit: find hardcoded (German) user-visible strings in lib/**.

Extracts every string literal from the Dart sources (comment-aware, handles
raw/triple-quoted strings and ${...} interpolation), filters out technical
strings (asset paths, routes, keys, URLs, SQL, format patterns), flags German
text, and categorizes each finding:

  a-ui      user-visible UI text
  b-error   error message / snackbar / dialog
  c-push    push / local notification text
  d-log     log / Sentry / debug / exception text (unify to English, no ARB key)
  e-legal   legal / consent copy (lawyer-owned: flag only, never auto-translate)
  g-format  hardcoded German locale in date/number formatting (code, not string)

Usage:
  python3 scripts/i18n_audit.py                     # summary to stdout
  python3 scripts/i18n_audit.py --tsv out.tsv       # full detail dump
  python3 scripts/i18n_audit.py --gate              # exit 1 if user-visible
                                                    # German strings remain
                                                    # (categories a/b/c)

Allowlist (for deliberate exceptions, e.g. proper nouns): each line of
scripts/i18n_audit_allowlist.txt is TAB-separated `<path-or-*>\t<exact string>`.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
LIB_DIR = REPO_ROOT / "lib"
ALLOWLIST_FILE = REPO_ROOT / "scripts" / "i18n_audit_allowlist.txt"

SKIP_DIR_PARTS = {"l10n"}
SKIP_FILE_SUFFIXES = (".g.dart", ".freezed.dart", ".gr.dart")
SKIP_FILE_NAMES = {"firebase_options.dart"}

INTERP_MARK = "⟦…⟧"  # ⟦…⟧ placeholder for ${...} / $ident


# --------------------------------------------------------------------------
# Dart tokenizer: yields (line_number, literal_text_with_interp_placeholders)
# --------------------------------------------------------------------------

def extract_strings(src: str):
    results = []
    i = 0
    n = len(src)
    line = 1

    def peek(offset=0):
        j = i + offset
        return src[j] if j < n else ""

    # context stack: each entry is ("code", brace_depth) or a string context
    # ("str", quote, triple, raw, buf, start_line)
    stack = [["code", 0]]

    while i < n:
        ch = src[i]
        top = stack[-1]

        if ch == "\n":
            line += 1

        if top[0] == "code":
            # line comment
            if ch == "/" and peek(1) == "/":
                while i < n and src[i] != "\n":
                    i += 1
                continue
            # block comment (Dart block comments nest)
            if ch == "/" and peek(1) == "*":
                depth = 1
                i += 2
                while i < n and depth:
                    if src[i] == "\n":
                        line += 1
                    if src[i] == "/" and peek(1) == "*":
                        depth += 1
                        i += 2
                    elif src[i] == "*" and peek(1) == "/":
                        depth -= 1
                        i += 2
                    else:
                        i += 1
                continue
            # string start (with optional r prefix)
            raw = False
            qpos = i
            if ch == "r" and peek(1) in ("'", '"'):
                raw = True
                qpos = i + 1
            if src[qpos : qpos + 1] in ("'", '"'):
                quote = src[qpos]
                triple = src[qpos : qpos + 3] == quote * 3
                i = qpos + (3 if triple else 1)
                stack.append(["str", quote, triple, raw, [], line])
                continue
            # interpolation close?
            if ch == "}" and len(stack) > 1:
                if top[1] == 0:
                    stack.pop()  # back to enclosing string
                    stack[-1][4].append(INTERP_MARK)
                    i += 1
                    continue
                top[1] -= 1
            elif ch == "{":
                top[1] += 1
            i += 1
            continue

        # ---- inside a string ----
        _, quote, triple, raw, buf, start_line = top
        closer = quote * 3 if triple else quote
        if src.startswith(closer, i):
            text = "".join(buf)
            stack.pop()
            results.append((top[5], text))
            i += len(closer)
            continue
        if not raw:
            if ch == "\\":
                nxt = peek(1)
                buf.append({"n": "\n", "t": "\t"}.get(nxt, nxt))
                i += 2
                continue
            if ch == "$":
                if peek(1) == "{":
                    stack.append(["code", 0])
                    i += 2
                    continue
                j = i + 1
                while j < n and (src[j].isalnum() or src[j] == "_"):
                    j += 1
                if j > i + 1:
                    buf.append(INTERP_MARK)
                    i = j
                    continue
        if not triple and ch == "\n":
            # unterminated single-line string (syntax error in source) — bail out
            stack.pop()
            results.append((top[5], "".join(buf)))
            continue
        buf.append(ch)
        i += 1

    return results


# --------------------------------------------------------------------------
# Filters
# --------------------------------------------------------------------------

TECH_PATTERNS = [
    re.compile(r"^(https?|mailto|tel|sms|package|dart|file)[:/]"),
    re.compile(r"^assets?/"),
    re.compile(r".*\.(png|jpe?g|svg|gif|webp|json|arb|ttf|otf|mp3|wav|mp4|mov|riv|pdf|html?|css|js|dart|sql|yaml|env)$", re.I),
    re.compile(r"^/[A-Za-z0-9_\-/:.⟦…⟧]*$"),             # route paths (incl. interp)
    re.compile(r"^[a-z0-9⟦…⟧]+(?:[_.\-][a-z0-9⟦…⟧]+)+$"),  # snake.case keys, table names
    re.compile(r"^[a-z]+[A-Z][A-Za-z0-9]*$"),            # camelCase identifier
    re.compile(r"^[A-Z0-9_]{2,}$"),                      # SCREAMING_SNAKE / env names
    re.compile(r"^#?[0-9a-fA-F]{6,8}$"),                 # hex colors
    re.compile(r"^[\d\s.,:;+\-*/%()\[\]{}<>=!?|&^~#@'\"´`§$€⟦…⟧°]*$"),  # no real words
    re.compile(r"^(select|insert|update|delete|create|alter|drop|grant|with)\s", re.I),  # SQL
    re.compile(r"^[dMyHhmsEQL]{1,6}([.,:\-/\s]+[dMyHhmsEQL]{1,6})*$"),  # DateFormat patterns
    re.compile(r"^(application|text|image|audio|video|multipart)/[a-z0-9.+\-]+$"),  # MIME
    re.compile(r"^[A-Za-z0-9+/=_\-]{24,}$"),             # tokens/base64-ish
    re.compile(r"^\w+(\.\w+)+$"),                        # dotted identifiers
]

# lone lowercase token (map key, json field, locale code) — technical unless
# it is an unambiguous German word
LOWER_TOKEN = re.compile(r"^[a-z][a-z0-9_\-]*$")

TECH_EXTRA = [
    re.compile(r"^[a-z_]+(\s*,\s*[a-z_]+)+$"),           # SQL column lists
    re.compile(r"^[a-z]{2}([_-][A-Z]{2})?$"),            # locale codes de, de_DE
]

# Single capitalized ASCII token that is NOT a known German word => class name etc.
SINGLE_TOKEN = re.compile(r"^[A-Za-z][A-Za-z0-9]*$")

UMLAUT = re.compile(r"[äöüÄÖÜß]")

STRONG_DE = re.compile(
    r"\b(aber|abbrechen|abgeschlossen|abmelden|abschließen|achtung|aktiv|aktualisieren|alle[nrs]?|"
    r"andere[nrs]?|anmelden|antworten|anzeigen|auswählen|beenden|beim|bearbeiten|beginnen|behalten|"
    r"bereit|bestätigen|bitte|bleiben|brauchst|dabei|damit|danach|danke|dann|dauer|dein[e]?[mnrs]?|"
    r"diese[mnrs]?|dir|doch|drücke|durch|eigene[ns]?|eingeben|einloggen|eintrag|einträge|einträgen|"
    r"einstellungen|empfohlen|entfernen|erfolgreich|erneut|erstellen|erstellt|fehlgeschlagen|fehler|"
    r"fertig|fortfahren|fortschritt|fortsetzen|frage|fragen|geändert|gefunden|gehts|gelöscht|gemacht|"
    r"geschafft|gespeichert|gestartet|heute|hinweis|hinzufügen|ich|ihr[e]?|jetzt|kannst|keine?[nrs]?|"
    r"klicke|konnte[n]?|kurz|laden|lädt|leider|löschen|mehr|melde|mindestens|möchtest|morgen|nächste[nrs]?|"
    r"nein|neue[nrs]?|nicht|nichts|noch|nutzen|oder|öffnen|okay|pausieren|prüfen|schließen|sehen|sehr|"
    r"sekunden|senden|sitzung|speichern|später|starten|startet|suche[n]?|synchronisiert|tage[n]?|"
    r"teilen|tippe|trage|trainiere|training[s]?|übernehmen|überspringen|übung|übungen|und|ungültig|"
    r"unterstützt|verbunden|vergessen|verlauf|verlängern|verstanden|versuche[n]?|vielen|vorbei|"
    r"warten|wähle|während|weiter|wenn|werden|wieder|wiederholen|wird|woche[n]?|wurde[n]?|zeigt|"
    r"zuletzt|zurück|zwischen|dauerhaft|nutzung|geräte?|kalender|standort|benachrichtigung(en)?|"
    r"klient(en|in|innen)?|begleitung|eltern(teil)?|kind(er|es)?|monat(e|en)?|jahr(e|en)?|"
    r"stunde[n]?|minute[n]?|termin[e]?|verbindung|übersicht|verfügbar|mit|vom|zum|zur)\b",
    re.I,
)

WEAK_DE = re.compile(
    r"\b(an|auf|aus|bei|bis|das|dem|den|der|des|die|du|ein|eine[mnrs]?|es|für|hat|im|in|ist|kann|"
    r"man|mit|nach|nur|ohne|sich|sie|sind|so|um|uns|van|vom|von|vor|war|was|wie|wir|zu|zum|zur)\b",
    re.I,
)


def load_allowlist():
    allow = set()
    if ALLOWLIST_FILE.exists():
        for raw in ALLOWLIST_FILE.read_text(encoding="utf-8").splitlines():
            if not raw.strip() or raw.startswith("#"):
                continue
            parts = raw.split("\t", 1)
            if len(parts) == 2:
                allow.add((parts[0].strip(), parts[1]))
    return allow


def is_technical(text: str) -> bool:
    t = text.strip()
    if len(t) < 2:
        return True
    for pat in TECH_PATTERNS:
        if pat.match(t):
            return True
    for pat in TECH_EXTRA:
        if pat.match(t):
            return True
    if LOWER_TOKEN.match(t) and not STRONG_DE.search(t):
        return True
    visible = t.replace(INTERP_MARK, "")
    if not re.search(r"[A-Za-zÄÖÜäöüß]{2,}", visible):
        return True
    return False


def is_german(text: str) -> bool:
    t = text.replace(INTERP_MARK, " ")
    if UMLAUT.search(t):
        return True
    if STRONG_DE.search(t):
        return True
    weak = {m.lower() for m in WEAK_DE.findall(t)}
    return len(weak) >= 2


CTX_LOG = re.compile(r"appLogger|logger\.|\blog\.|debugPrint|\bprint\s*\(|Sentry|breadcrumb|\.severe\(|\.warning\(|\.info\(|\.fine\(|\.\b[diwef]\(", re.I)
CTX_THROW = re.compile(r"\bthrow\b|Exception\(|StateError\(|ArgumentError\(|UnsupportedError\(|FormatException\(|assert\(")
CTX_PUSH = re.compile(r"Notification|notification|NotificationDetails|AndroidNotification|flutterLocalNotifications")
CTX_ERROR = re.compile(r"SnackBar|showSnack|showError|AlertDialog|showDialog|errorMessage|failureMessage|\berror\b|\bfehler\b", re.I)
CTX_SEMANTICS = re.compile(r"[Ss]emantic|tooltip|Tooltip|hintText|labelText|helperText")

LEGAL_PATH = re.compile(r"consent|legal|privacy|datenschutz|impressum|terms|agb")
PUSH_PATH = re.compile(r"notification|push|fcm|reminder")

# bilingual-by-design content fields (exercise.dart pattern): a literal that sits
# under a `...De:` / `...En:` field or `_defaultDe =`-style assignment is part of
# a DE/EN pair and rendered locale-aware — not a hardcoding finding.
BILINGUAL_FIELD = re.compile(r"\b[A-Za-z_]*(De|En)\s*[:=]")


def categorize(rel_path: str, ctx: str, back_lines: list[str]) -> str:
    p = rel_path.lower()
    if LEGAL_PATH.search(p):
        return "e-legal"
    for bl in reversed(back_lines):
        if BILINGUAL_FIELD.search(bl):
            return "ok-bilingual"
    if CTX_LOG.search(ctx):
        return "d-log"
    if PUSH_PATH.search(p) or CTX_PUSH.search(ctx):
        return "c-push"
    if CTX_THROW.search(ctx):
        return "d-log"
    if CTX_ERROR.search(ctx):
        return "b-error"
    return "a-ui"


# hardcoded German locale in formatting code
FORMAT_LOCALE = re.compile(r"DateFormat\s*(\.\w+\s*)?\([^)]*['\"]de(_DE)?['\"]|Intl\.defaultLocale|initializeDateFormatting\(\s*['\"]de", )


def audit(gate: bool, tsv_path: str | None):
    allow = load_allowlist()
    findings = []
    format_findings = []

    for path in sorted(LIB_DIR.rglob("*.dart")):
        rel = path.relative_to(REPO_ROOT).as_posix()
        parts = set(path.relative_to(LIB_DIR).parts)
        if parts & SKIP_DIR_PARTS or path.name in SKIP_FILE_NAMES:
            continue
        if path.name.endswith(SKIP_FILE_SUFFIXES):
            continue
        src = path.read_text(encoding="utf-8")
        lines = src.splitlines()

        for m in FORMAT_LOCALE.finditer(src):
            ln = src.count("\n", 0, m.start()) + 1
            format_findings.append((rel, ln, lines[ln - 1].strip()))

        for ln, text in extract_strings(src):
            src_line = lines[ln - 1].lstrip() if ln <= len(lines) else ""
            if src_line.startswith(("import ", "export ", "part ")):
                continue
            if is_technical(text):
                continue
            german = is_german(text)
            back = lines[max(0, ln - 8) : ln]
            ctx = " ".join(lines[max(0, ln - 4) : ln])
            cat = categorize(rel, ctx, back)
            allowed = (rel, text) in allow or ("*", text) in allow
            findings.append(
                {"file": rel, "line": ln, "cat": cat, "german": german,
                 "allowed": allowed, "text": text}
            )

    # Gate scope: EVERY user-visible hardcoded string (categories a/b/c) that is
    # not explicitly allowlisted — German or not. At the end of the i18n task
    # nothing user-visible may live outside the ARB files.
    gate_visible = [
        f for f in findings
        if not f["allowed"] and f["cat"] in ("a-ui", "b-error", "c-push")
    ]
    german_visible = [f for f in gate_visible if f["german"]]

    # ---- output ----
    by_file: dict[str, dict] = {}
    for f in findings:
        d = by_file.setdefault(f["file"], {"total": 0, "german": 0, "cats": {}})
        d["total"] += 1
        if f["german"]:
            d["german"] += 1
            d["cats"][f["cat"]] = d["cats"].get(f["cat"], 0) + 1

    print(f"Dateien mit nicht-technischen String-Literalen: {len(by_file)}")
    print(f"Nicht-technische Literale gesamt:               {len(findings)}")
    print(f"Davon deutsch:                                  {sum(1 for f in findings if f['german'])}")
    print(f"Nutzersichtbar gesamt (a/b/c, ohne Allowlist):  {len(gate_visible)}")
    print(f"Deutsch + nutzersichtbar (a/b/c, ohne Allow):   {len(german_visible)}")
    if format_findings:
        print(f"Hartcodierte de-Locale-Formatierung (g-format): {len(format_findings)}")
    print()
    print(f"{'Datei':<78} {'DE':>4} {'ges.':>5}  Kategorien")
    for file, d in sorted(by_file.items(), key=lambda kv: -kv[1]["german"]):
        if d["german"] == 0:
            continue
        cats = ", ".join(f"{k}:{v}" for k, v in sorted(d["cats"].items()))
        print(f"{file:<78} {d['german']:>4} {d['total']:>5}  {cats}")

    if tsv_path:
        with open(tsv_path, "w", encoding="utf-8") as fh:
            fh.write("file\tline\tcategory\tgerman\tallowed\ttext\n")
            for f in findings:
                clean = f["text"].replace("\t", " ").replace("\n", "\\n")
                fh.write(f"{f['file']}\t{f['line']}\t{f['cat']}\t{int(f['german'])}\t{int(f['allowed'])}\t{clean}\n")
            for rel, ln, ctx in format_findings:
                fh.write(f"{rel}\t{ln}\tg-format\t1\t0\t{ctx}\n")
        print(f"\nDetail-Dump: {tsv_path}")

    if gate:
        if gate_visible or format_findings:
            print(f"\nGATE FAILED: {len(gate_visible)} nutzersichtbare hartcodierte Strings "
                  f"(davon {len(german_visible)} deutsch), "
                  f"{len(format_findings)} hartcodierte de-Locale-Formatierungen.")
            for f in gate_visible[:40]:
                print(f"  {f['file']}:{f['line']}  [{f['cat']}]  {f['text'][:80]}")
            return 1
        print("\nGATE OK: keine nutzersichtbaren hartcodierten Strings gefunden.")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--tsv", help="write full findings dump to this TSV file")
    ap.add_argument("--gate", action="store_true", help="exit 1 if user-visible German strings remain")
    args = ap.parse_args()
    sys.exit(audit(args.gate, args.tsv))


if __name__ == "__main__":
    main()
