import {
  assert,
  assertEquals,
  assertStringIncludes,
} from 'https://deno.land/std@0.168.0/testing/asserts.ts';

import {
  buildTrainingReminderCopy,
} from '../_shared/reminder_copy.ts';
import {
  isPermanentTokenError,
} from '../_shared/fcm.ts';

Deno.test('training_soft with default source avoids X von Y copy', () => {
  const copy = buildTrainingReminderCopy('training_soft', null, 5, 'default');
  assert(!copy.body.includes('von'));
});

Deno.test('training_soft with reliable weekly goal may use the goal', () => {
  const copy = buildTrainingReminderCopy('training_soft', null, 5, 'curriculum');
  assertStringIncludes(copy.body, '5');
});

Deno.test('existing German reminder copy stays unchanged', () => {
  assertEquals(
    buildTrainingReminderCopy('training_soft', null, 5, 'curriculum'),
    {
      title: 'Zeit fuer deine Einheit',
      body:
        'Heute ist ein guter Moment fuer deine naechste Einheit. Dein Wochenziel: 5 Einheiten.',
    },
  );
  assertEquals(
    buildTrainingReminderCopy('streak_warning', 4, null, 'default'),
    {
      title: 'Training-Erinnerung',
      body:
        'Deine Serie laeuft seit 4 Tagen. Heute ist noch Zeit fuer eine kurze Einheit.',
    },
  );
  assertEquals(buildTrainingReminderCopy('comeback', 3, null, 'default'), {
    title: 'Wieder einsteigen',
    body:
      'Nach 3 starken Tagen ist heute ein guter Moment, wieder einzusteigen.',
  });
});

Deno.test('English training_soft handles singular and plural weekly goals', () => {
  const singular = buildTrainingReminderCopy(
    'training_soft',
    null,
    1,
    'user_setting',
    'en',
  );
  const plural = buildTrainingReminderCopy(
    'training_soft',
    null,
    3,
    'curriculum',
    'en',
  );

  assertStringIncludes(singular.body, '1 session.');
  assert(!singular.body.includes('1 sessions'));
  assertStringIncludes(plural.body, '3 sessions.');
});

Deno.test('streak_warning with streak count uses count', () => {
  const copy = buildTrainingReminderCopy('streak_warning', 4, null, 'default');
  assertStringIncludes(copy.body, '4');
});

Deno.test('streak_warning without streak count is neutral', () => {
  const copy = buildTrainingReminderCopy('streak_warning', null, null, 'default');
  assertEquals(copy.body, 'Heute ist noch Zeit fuer eine kurze Einheit.');
});

Deno.test('comeback after streak is supportive', () => {
  const copy = buildTrainingReminderCopy('comeback', 3, null, 'default');
  assertStringIncludes(copy.body, 'wieder einzusteigen');
});

Deno.test('all reminder types have natural English copy with counts', () => {
  const soft = buildTrainingReminderCopy(
    'training_soft',
    null,
    null,
    'default',
    'en',
  );
  const streak = buildTrainingReminderCopy(
    'streak_warning',
    4.9,
    null,
    'default',
    'en',
  );
  const comeback = buildTrainingReminderCopy(
    'comeback',
    3,
    null,
    'default',
    'en',
  );

  assertEquals(soft.body, "There's still time for your session today.");
  assertStringIncludes(streak.body, '4-day streak');
  assert(!streak.body.includes('4.9'));
  assertStringIncludes(comeback.body, 'After 3 strong days');
});

Deno.test('copy never includes undefined or null', () => {
  for (const type of ['training_soft', 'streak_warning', 'comeback'] as const) {
    const copy = buildTrainingReminderCopy(type, undefined, undefined, 'default');
    assert(!copy.title.includes('undefined'));
    assert(!copy.title.includes('null'));
    assert(!copy.body.includes('undefined'));
    assert(!copy.body.includes('null'));
  }
});

Deno.test('permanent token error classification is token-specific', () => {
  assertEquals(isPermanentTokenError('UNREGISTERED'), true);
  assertEquals(isPermanentTokenError('INVALID_ARGUMENT', 'Invalid value at message.token'), true);
  assertEquals(isPermanentTokenError('INVALID_ARGUMENT', 'Invalid value at message.notification'), false);
});
