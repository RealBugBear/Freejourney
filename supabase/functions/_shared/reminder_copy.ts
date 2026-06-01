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
): TrainingReminderCopy {
  const canUseWeeklyGoal =
    weeklyGoal != null &&
    weeklyGoal > 0 &&
    (weeklyGoalSource === 'curriculum' || weeklyGoalSource === 'user_setting');

  const streak = streakDaysOrWeeks != null && streakDaysOrWeeks > 0
    ? Math.floor(streakDaysOrWeeks)
    : null;

  if (type === 'training_soft') {
    return {
      title: 'Zeit fuer deine Einheit',
      body: canUseWeeklyGoal
        ? `Heute ist ein guter Moment fuer deine naechste Einheit. Dein Wochenziel: ${weeklyGoal} Einheiten.`
        : 'Heute ist noch Zeit fuer deine Einheit.',
    };
  }

  if (type === 'streak_warning') {
    return {
      title: 'Training-Erinnerung',
      body: streak != null
        ? `Deine Serie laeuft seit ${streak} Tagen. Heute ist noch Zeit fuer eine kurze Einheit.`
        : 'Heute ist noch Zeit fuer eine kurze Einheit.',
    };
  }

  return {
    title: 'Wieder einsteigen',
    body: streak != null
      ? `Nach ${streak} starken Tagen ist heute ein guter Moment, wieder einzusteigen.`
      : 'Heute ist ein guter Moment, wieder einzusteigen.',
  };
}
