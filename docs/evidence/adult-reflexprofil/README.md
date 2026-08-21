# Adult Reflexprofil — Evidence (Phase 7)

## §10.4 live query (read-only)

```sql
select questionnaire_version, scoring_version, status, count(*)
from public.reflex_profile_assessments
where questionnaire_type = 'adult_self_report'
group by 1, 2, 3;
```

**Result (2026-08-21):** `[]` — zero rows. Legacy branch kept as guardrail.

## Screenshots (widget capture of real Flutter widgets)

| File | Content |
|------|---------|
| `01_adult_result_light.png` | Adult_v3 result, light theme |
| `02_adult_result_dark.png` | Adult_v3 result, dark theme |
| `03_adult_result_legacy.png` | Legacy-method notice |
| `04_adult_answer_grid_2x2.png` | Four-way answer grid (Ja/Nein/?/n.z.) |
| `adult_result_invite_placement.png` | Result with invite slot below export actions (§10.2a) |
| `adult_result_invite_placement_mock.png` | Earlier layout mock (kept for comparison) |

Regenerate: `flutter test test/evidence/adult_reflexprofil_evidence_test.dart`
