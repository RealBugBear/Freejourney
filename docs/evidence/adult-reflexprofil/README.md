# Adult Reflexprofil — Evidence (Phase 7)

## §10.4 live query (read-only)

```sql
select questionnaire_version, scoring_version, status, count(*)
from public.reflex_profile_assessments
where questionnaire_type = 'adult_self_report'
group by 1, 2, 3;
```

**Result (2026-08-21):** `[]` — zero rows. Legacy branch kept as guardrail.

## Invite placement (§10.2a)

`adult_result_invite_placement.png` — schematic of the adult result layout:
horizontal bars → amphibian block → PDF/Dashboard → divider →
**InviteImpulseI1Slot at page end** (not between reflex values).

Widget test `invite placement is below export actions` asserts the divider
Y-position is below the PDF action. Founder confirms final position against
this image.
