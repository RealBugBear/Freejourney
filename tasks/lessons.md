# Lessons Learned

Patterns and rules captured after corrections — updated by Claude after any mistake.

---

## 2026-07-02 — `git mv` stages immediately; check the index before every commit

`git mv` puts the rename into the index right away. A later `git add <file> &&
git commit` then sweeps the staged rename into that unrelated commit (had to
soft-reset and recommit). Rule: immediately before any commit, run
`git diff --cached --name-status` and confirm the staged list contains exactly
the files named in the commit plan — nothing inherited from earlier commands.

## 2026-07-02 — Don't chain mutating git commands with long-running ones

A combined `git mv … && supabase db reset` was rejected by the founder; run
repo mutations as single-purpose commands so each step is individually
auditable, then run the long verification step separately.
