import type { SupportedLocale } from './notification_copy.ts';

export type ReminderType = 'training_soft' | 'streak_warning' | 'comeback';
export type WeeklyGoalSource = 'curriculum' | 'user_setting' | 'default';

export interface TrainingReminderCopy {
  title: string;
  body: string;
}

export function buildTrainingReminderCopy(
  type: ReminderType,
  streakDaysOrWeeks?: number | null,
  weeklyGoal?: number | null,
  weeklyGoalSource: WeeklyGoalSource = 'default',
  locale: SupportedLocale = 'de',
): TrainingReminderCopy {
  const canUseWeeklyGoal =
    weeklyGoal != null &&
    weeklyGoal > 0 &&
    (weeklyGoalSource === 'curriculum' || weeklyGoalSource === 'user_setting');

  const streak = streakDaysOrWeeks != null && streakDaysOrWeeks > 0
    ? Math.floor(streakDaysOrWeeks)
    : null;

  if (type === 'training_soft') {
    if (locale === 'en') {
      const sessionLabel = weeklyGoal === 1 ? 'session' : 'sessions';
      return {
        title: 'Time for Your Session',
        body: canUseWeeklyGoal
          ? `Now is a good time for your next session. Your weekly goal: ${weeklyGoal} ${sessionLabel}.`
          : "There's still time for your session today.",
      };
    }

    return {
      title: 'Zeit fuer deine Einheit',
      body: canUseWeeklyGoal
        ? `Heute ist ein guter Moment fuer deine naechste Einheit. Dein Wochenziel: ${weeklyGoal} Einheiten.`
        : 'Heute ist noch Zeit fuer deine Einheit.',
    };
  }

  if (type === 'streak_warning') {
    if (locale === 'en') {
      return {
        title: 'Training Reminder',
        body: streak != null
          ? `You're on a ${streak}-day streak. There's still time for a short session today.`
          : "There's still time for a short session today.",
      };
    }

    return {
      title: 'Training-Erinnerung',
      body: streak != null
        ? `Deine Serie laeuft seit ${streak} Tagen. Heute ist noch Zeit fuer eine kurze Einheit.`
        : 'Heute ist noch Zeit fuer eine kurze Einheit.',
    };
  }

  if (locale === 'en') {
    return {
      title: 'Get Back Into It',
      body: streak != null
        ? `After ${streak} strong days, today is a good time to get back into it.`
        : 'Today is a good time to get back into it.',
    };
  }

  return {
    title: 'Wieder einsteigen',
    body: streak != null
      ? `Nach ${streak} starken Tagen ist heute ein guter Moment, wieder einzusteigen.`
      : 'Heute ist ein guter Moment, wieder einzusteigen.',
  };
}
