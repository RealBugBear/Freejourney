BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path = public, extensions;
SELECT no_plan();
INSERT INTO auth.users(id,email,raw_user_meta_data)
VALUES ('96000000-0000-4000-8000-000000000001','queue-recovery@example.invalid','{}');
INSERT INTO public.notification_jobs(id,user_id,type,scheduled_for,local_date,timezone,idempotency_key)
VALUES ('96000000-0000-4000-8000-000000000011','96000000-0000-4000-8000-000000000001',
  'training_soft',now()-interval '1 minute',current_date,'UTC','local-recovery-test');
SELECT is((SELECT count(*)::int FROM public.claim_due_notification_jobs(1)),1,'pending job claimed');
SELECT is((SELECT attempt_count FROM public.notification_jobs WHERE idempotency_key='local-recovery-test'),1,'attempt incremented');
SELECT is((SELECT count(*)::int FROM public.claim_due_notification_jobs(1)),0,'live lease cannot be claimed twice');
UPDATE public.notification_jobs SET updated_at=now()-interval '11 minutes' WHERE idempotency_key='local-recovery-test';
SELECT is((SELECT count(*)::int FROM public.claim_due_notification_jobs(1)),1,'expired worker recovered');
SELECT is((SELECT attempt_count FROM public.notification_jobs WHERE idempotency_key='local-recovery-test'),2,'recovery receives new fence');
UPDATE public.notification_jobs SET status='sent' WHERE idempotency_key='local-recovery-test' AND attempt_count=1;
SELECT is((SELECT status FROM public.notification_jobs WHERE idempotency_key='local-recovery-test'),'sending','stale fence cannot finalize job');
UPDATE public.notification_jobs SET status='failed',updated_at=now() WHERE idempotency_key='local-recovery-test';
SELECT is((SELECT count(*)::int FROM public.claim_due_notification_jobs(1)),0,'transient retry respects backoff');
UPDATE public.notification_jobs SET updated_at=now()-interval '5 minutes' WHERE idempotency_key='local-recovery-test';
SELECT is((SELECT count(*)::int FROM public.claim_due_notification_jobs(1)),1,'transient failure eventually retried');
UPDATE public.notification_jobs SET status='sending',attempt_count=5,updated_at=now()-interval '11 minutes' WHERE idempotency_key='local-recovery-test';
SELECT is((SELECT count(*)::int FROM public.claim_due_notification_jobs(1)),0,'retry count is bounded');
SELECT is((SELECT status FROM public.notification_jobs WHERE idempotency_key='local-recovery-test'),'failed','exhausted crashed worker becomes actionable failed status');
SELECT ok(NOT has_function_privilege('authenticated','public.claim_due_notification_jobs(int)','EXECUTE'),'client cannot claim or recover jobs');
SELECT * FROM finish();
ROLLBACK;
