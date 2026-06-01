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
