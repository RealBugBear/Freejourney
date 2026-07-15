import 'reflex_questionnaire.dart';

final childParentQuestionnaireV1 = ReflexQuestionnaireDefinition(
  id: 'child_parent_reflex_profile',
  version: 'child_parent_v2_2026_05',
  type: ReflexQuestionnaireType.childParentReport,
  titleDe: 'Reflexprofil für Kinder',
  titleEn: 'Reflex Profile for Children',
  screenTitleDe: 'Reflexprofil',
  screenTitleEn: 'Reflex Profile',
  scoring: const ReflexScoringDefinition(
    strongPercent: 100,
    elevatedPercent: 80,
    indicationPercent: 50,
  ),
  questions: [
    _q(1, m.pregnancyBirth,
        textDe: 'Gab es während der Schwangerschaft gesundheitliche Probleme?',
        reflexes: [r.delay, r.flr, r.moro]),
    _q(2, m.pregnancyBirth,
        textDe: 'Hattest du während der Schwangerschaft persönliche Probleme?',
        reflexes: [r.delay, r.flr, r.moro]),
    _q(3, m.pregnancyBirth,
        textDe: 'Musstest du während der Schwangerschaft lange liegen?',
        reflexes: [r.delay]),
    _context(4, m.pregnancyBirth,
        textDe: 'Gab es Schwierigkeiten bei der Geburt?'),
    _q(5, m.pregnancyBirth,
        textDe: 'Lag dein Kind bei der Geburt in Beckenendlage?',
        reflexes: [r.flr, r.moro, r.spinalGalant, r.atnr, r.stnr]),
    _q(6, m.pregnancyBirth,
        textDe: 'Wurde dein Kind zu früh geboren? (Bsp.: Frühchen)',
        reflexes: [r.delay]),
    _q(7, m.pregnancyBirth,
        textDe: 'Gab es einen Notkaiserschnitt?',
        reflexes: [r.spinalGalant, r.atnr]),
    _q(8, m.pregnancyBirth,
        textDe: 'Wurde dein Kind durch einen Wunschkaiserschnitt geboren?',
        reflexes: [r.spinalGalant, r.atnr]),
    _q(9, m.pregnancyBirth,
        textDe: 'War der Geburtsvorgang ungewöhnlich kurz? (Bsp.: Sturzgeburt)',
        reflexes: [r.spinalGalant, r.atnr, r.stnr]),
    _q(10, m.pregnancyBirth,
        textDe: 'War der Geburtsvorgang ungewöhnlich lang?',
        reflexes: [r.atnr, r.stnr]),
    _q(11, m.pregnancyBirth,
        textDe: 'Gab es während der Geburt wehenfördernde Maßnahmen?',
        reflexes: [r.spinalGalant, r.atnr, r.stnr]),
    _q(12, m.pregnancyBirth,
        textDe: 'Bekamst du während der Geburt wehenhemmende Medikamente?',
        reflexes: [r.flr, r.moro, r.spinalGalant, r.atnr, r.stnr]),
    _q(13, m.posturePerception,
        textDe:
            'Lag dein Kind in den ersten Monaten überwiegend auf dem Rücken?',
        reflexes: [r.landau]),
    _q(14, m.posturePerception,
        textDe: 'Steht dein Kind oft mit nach innen gedrehten Füßen da?',
        reflexes: [r.flr, r.babinski]),
    _q(15, m.posturePerception,
        textDe: 'Leidet dein Kind unter Nackenverspannungen?',
        reflexes: [r.tlr, r.landau, r.babkin]),
    _q(16, m.posturePerception,
        textDe:
            'Wenn sich dein Kind in Bauchlage auf die Unterarme stützt, den Oberkörper und Kopf anhebt, faustet es dann die Hände?',
        reflexes: [r.babkin, r.palmar, r.righting]),
    _q(17, m.posturePerception,
        textDe: 'Rollt dein Kind die Zehen immer wieder ein?',
        reflexes: [r.plantar]),
    _q(18, m.posturePerception,
        textDe: 'Kann dein Kind mind. 10 Sekunden auf einem Bein stehen?',
        reflexes: [r.moro, r.tlr, r.atnr, r.babinski]),
    _q(19, m.posturePerception,
        textDe:
            'Kann dein Kind mind. 10 Sekunden mit geschlossenen Augen auf einem Bein stehen?',
        reflexes: [r.moro, r.tlr, r.atnr, r.babinski]),
    _q(20, m.posturePerception,
        textDe: 'Sitzt dein Kind gerne auf einem oder beiden Füßen?',
        reflexes: [r.stnr]),
    _q(21, m.posturePerception,
        textDe: 'Schlingt dein Kind beim Sitzen seine Beine um die Stuhlbeine?',
        reflexes: [r.stnr]),
    _q(22, m.posturePerception,
        textDe:
            'Neigt dein Kind den Kopf oft nach unten, der Blick geht aber von unten nach oben? (Misstrauischer Blick)',
        reflexes: [r.stnr],
        helpTextDe:
            'Gemeint ist die beobachtbare Kopf- und Blickhaltung, nicht eine Bewertung des Verhaltens.'),
    _q(23, m.posturePerception,
        textDe:
            'Hat dein Kind seinen Kopf oft nach oben geneigt, schaut aber von oben herab? (Hochnäsiger Blick)',
        reflexes: [r.stnr],
        helpTextDe:
            'Gemeint ist die beobachtbare Kopf- und Blickhaltung, nicht eine Bewertung des Verhaltens.'),
    _q(24, m.posturePerception,
        textDe:
            'Hat dein Kind Schwierigkeiten, über längere Zeit still zu sitzen?',
        reflexes: [r.spinalGalant, r.stnr]),
    _q(25, m.posturePerception,
        textDe: 'Lehnt sich dein Kind kaum oder selten an den Stuhllehnen an?',
        reflexes: [r.spinalGalant]),
    _context(26, m.posturePerception,
        textDe: 'Sitzt dein Kind häufig im W-Sitz'),
    _q(27, m.posturePerception,
        textDe: 'Ist dein Kind übermäßig kitzelig an den Füßen?',
        reflexes: [r.babinski]),
    _q(28, m.posturePerception,
        textDe: 'Ist dein Kind übermäßig kitzelig am Körper?',
        reflexes: [r.spinalGalant]),
    _q(29, m.posturePerception,
        textDe: 'Hat dein Kind X-Beine?', reflexes: [r.babinski]),
    _q(30, m.posturePerception,
        textDe: 'Hat dein Kind O-Beine?', reflexes: [r.babinski]),
    _q(31, m.motorSkills,
        textDe: 'Hat dein Kind das Krabbeln ausgelassen?', reflexes: [r.stnr]),
    _context(32, m.motorSkills,
        textDe: 'Wenn nein, ab wann ist dein Kind gekrabbelt?',
        answerType: ReflexAnswerType.monthsNumber,
        followUpOf: 'q031'),
    _context(33, m.motorSkills,
        textDe: 'Wann ist dein Kind das erste Mal gelaufen?',
        answerType: ReflexAnswerType.monthsNumber),
    _q(34, m.motorSkills,
        textDe: 'Neigt dein Kind dazu, auf den Zehenspitzen zu gehen?',
        reflexes: [r.tlr, r.stnr, r.landau, r.plantar]),
    _q(35, m.motorSkills,
        textDe: 'Hat dein Kind einen schiefen Gang?',
        reflexes: [r.spinalGalant]),
    _q(36, m.motorSkills,
        textDe: 'Fällt es deinem Kind schwer, eine feste Faust zu machen?',
        reflexes: [r.babkin]),
    _q(37, m.motorSkills,
        textDe: 'Zieht dein Kind Strümpfe und Schuhe umständlich an?',
        reflexes: [r.plantar]),
    _q(38, m.motorSkills,
        textDe:
            'Stützt dein Kind beim Sitzen am Tisch häufig den Kopf mit einem oder beiden Armen ab?',
        reflexes: [r.tlr, r.stnr, r.landau]),
    _q(39, m.motorSkills,
        textDe:
            'Räkelt und streckt sich dein Kind häufig beim Sitzen (Kopf nach hinten, Beine nach vorne)?',
        reflexes: [r.tlr, r.stnr]),
    _q(40, m.motorSkills,
        textDe: 'Hat dein Kind Probleme, einen Ball zu fangen?',
        reflexes: [r.moro, r.tlr, r.stnr]),
    _q(41, m.motorSkills,
        textDe:
            'Hat oder hatte dein Kind Probleme beim Schwimmenlernen, vor allem beim Brustschwimmen?',
        reflexes: [r.stnr, r.landau]),
    _q(42, m.motorSkills,
        textDe: 'Kann sich dein Kind schlecht oder gar nicht orientieren?',
        reflexes: [r.tlr, r.atnr]),
    _q(43, m.behaviorEmotion,
        textDe: 'War dein Kind in den ersten Monaten ein Schreikind?',
        reflexes: [r.delay, r.flr, r.moro, r.landau]),
    _q(44, m.behaviorEmotion,
        textDe: 'Ist dein Kind sehr empfindlich auf Geräusche?',
        reflexes: [r.flr, r.moro]),
    _q(45, m.behaviorEmotion,
        textDe: 'Ist dein Kind sehr empfindlich auf Licht oder Helligkeit?',
        reflexes: [r.flr, r.moro]),
    _q(46, m.behaviorEmotion,
        textDe: 'Ist dein Kind sehr empfindlich auf Berührung?',
        reflexes: [r.flr, r.moro]),
    _q(47, m.behaviorEmotion,
        textDe: 'Ist dein Kind überdurchschnittlich ängstlich?',
        reflexes: [r.flr, r.moro]),
    _q(48, m.behaviorEmotion,
        textDe: 'Leidet dein Kind unter Trennungsangst?',
        reflexes: [r.flr, r.moro]),
    _q(49, m.behaviorEmotion,
        textDe: 'Ist dein Kind oft weinerlich?', reflexes: [r.moro]),
    _q(50, m.behaviorEmotion,
        textDe: 'Ist dein Kind leicht reizbar bzw. schnell wütend?',
        reflexes: [r.moro, r.atnr]),
    _q(51, m.behaviorEmotion,
        textDe: 'Wirkt dein Kind oft unorganisiert?',
        reflexes: [r.spinalGalant]),
    _q(52, m.behaviorEmotion,
        textDe: 'Ist dein Kind oft vergesslich?', reflexes: [r.spinalGalant]),
    _q(53, m.behaviorEmotion,
        textDe: 'Liebt dein Kind Routine?', reflexes: [r.moro]),
    _q(54, m.behaviorEmotion,
        textDe: 'Ist dein Kind gerne in einer Fantasiewelt?',
        reflexes: [r.moro],
        helpTextDe:
            'Gemeint ist nicht normales Fantasiespiel, sondern ein starkes Zurückziehen in Fantasie oder Tagträume, wenn dadurch Alltagssituationen schwerer gelingen.'),
    _q(55, m.behaviorEmotion,
        textDe: 'Steht sich dein Kind häufig selbst im Weg?',
        reflexes: [r.moro],
        helpTextDe:
            'Gemeint ist z. B., dass dein Kind bei bekannten Aufgaben blockiert wirkt, sich schwer organisiert, vermeidet oder durch Unsicherheit, Frust oder Durcheinander ausgebremst wird.'),
    _q(56, m.behaviorEmotion,
        textDe: 'Ist dein Kind leicht ablenkbar?', reflexes: [r.moro]),
    _q(57, m.behaviorEmotion,
        textDe: 'Hat dein Kind ADHS oder ADS?',
        reflexes: [r.flr, r.moro, r.spinalGalant, r.tlr, r.landau, r.babinski],
        trainerFlagLabelDe: 'ADHS / ADS'),
    _context(58, m.behaviorEmotion,
        textDe: 'Hat dein Kind ein erhöhtes Schmerzempfinden?'),
    _context(59, m.behaviorEmotion,
        textDe: 'Hat dein Kind ein geringes Schmerzempfinden?'),
    _q(60, m.speech,
        textDe: 'Trägt oder trug dein Kind eine Zahnspange?',
        reflexes: [r.babkin, r.rootingSucking]),
    _q(61, m.speech,
        textDe:
            'Hat dein Kind eine deutliche Zahnfehlstellung oder einen gotischen Gaumen?',
        reflexes: [r.babkin, r.rootingSucking]),
    _q(62, m.speech,
        textDe: 'Knirscht dein Kind mit den Zähnen?', reflexes: [r.babkin]),
    _q(63, m.speech,
        textDe:
            'Hat dein Kind sehr lange am Daumen gelutscht oder einen Schnuller gehabt?',
        reflexes: [r.babkin, r.rootingSucking]),
    _q(64, m.speech,
        textDe: 'Hat dein Kind einen übermäßig starken Speichelfluss?',
        reflexes: [r.babkin, r.rootingSucking]),
    _q(65, m.speech,
        textDe: 'Macht dein Kind beim Schreiben oder Malen Mundbewegungen?',
        reflexes: [r.babkin, r.plantar, r.palmar]),
    _q(66, m.speech,
        textDe:
            'Beißt dein Kind oft die Zähne fest zusammen, besonders wenn es sich konzentriert?',
        reflexes: [r.babkin, r.plantar, r.palmar]),
    _q(67, m.speech,
        textDe:
            'Spricht dein Kind eher undeutlich (z. B. Nuscheln, falsche Aussprache von Lauten)?',
        reflexes: [r.stnr, r.babkin, r.plantar, r.palmar, r.rootingSucking]),
    _q(68, m.speech,
        textDe:
            'Neigt dein Kind zur Schwatzhaftigkeit bzw. redet es unablässig?',
        reflexes: [r.spinalGalant]),
    _q(69, m.drawingWriting,
        textDe: 'Hält dein Kind den Stift verkrampft?',
        reflexes: [r.babkin, r.palmar, r.righting]),
    _q(70, m.drawingWriting,
        textDe:
            'Hält dein Kind den Stift beim Malen oder Schreiben in einer Faust?',
        reflexes: [r.babkin, r.palmar]),
    _q(71, m.drawingWriting,
        textDe:
            'Drückt dein Kind den Stift beim Schreiben oder Malen sehr stark auf?',
        reflexes: [r.palmar, r.righting]),
    _q(72, m.drawingWriting,
        textDe: 'Hat dein Kind wenig Lust zu malen oder schreiben?',
        reflexes: [r.stnr, r.palmar, r.righting]),
    _q(73, m.drawingWriting,
        textDe: 'Ermüdet dein Kind sehr schnell beim Malen oder Schreiben?',
        reflexes: [r.stnr, r.palmar, r.righting]),
    _q(74, m.drawingWriting,
        textDe: 'Verdreht dein Kind Buchstaben, wie zum Beispiel b und d?',
        reflexes: [r.tlr, r.stnr]),
    _q(75, m.drawingWriting,
        textDe: 'Schreibt dein Kind in Spiegelschrift?',
        reflexes: [r.tlr, r.stnr]),
    _q(76, m.drawingWriting,
        textDe:
            'Hat dein Kind ein gutes mündliches Wissen, kann es aber nicht aufs Papier bringen?',
        reflexes: [r.stnr, r.babkin]),
    _q(77, m.drawingWriting,
        textDe:
            'Hat dein Kind eine unleserliche Schrift, vor allem bei der Schreibschrift?',
        reflexes: [r.spinalGalant, r.stnr, r.babkin, r.righting]),
    _q(78, m.drawingWriting,
        textDe:
            'Legt dein Kind beim Malen oder Schreiben das Blatt im 90-Grad-Winkel vor sich?',
        reflexes: [r.atnr]),
    _q(79, m.drawingWriting,
        textDe:
            'Fällt es deinem Kind schwer, die Linien beim Schreiben einzuhalten?',
        reflexes: [r.atnr]),
    _q(80, m.school,
        textDe:
            'Hat dein Kind Angst vor der Schule (Bauchschmerzen, Übelkeit etc.)?',
        reflexes: [r.flr, r.moro]),
    _q(81, m.school,
        textDe:
            'Hat dein Kind Schwierigkeiten, von der Tafel abzuschreiben (langsam, anstrengend etc.)?',
        reflexes: [r.tlr]),
    _q(82, m.school,
        textDe: 'Arbeitet dein Kind eher zu langsam?', reflexes: [r.tlr]),
    _q(83, m.school,
        textDe: 'Hat dein Kind Schwierigkeiten in der Rechtschreibung?',
        reflexes: [r.tlr, r.atnr, r.stnr, r.righting]),
    _q(84, m.school,
        textDe: 'Hat dein Kind Schwierigkeiten in der Grammatik?',
        reflexes: [r.tlr, r.atnr, r.stnr]),
    _q(85, m.school,
        textDe: 'Hat dein Kind Schwierigkeiten im Rechnen?',
        reflexes: [r.tlr, r.atnr, r.stnr]),
    _q(86, m.school,
        textDe: 'Ist dein Kind schlecht im Diktat?', reflexes: [r.flr, r.stnr]),
    _q(87, m.school,
        textDe: 'Hat dein Kind eine Lese-Rechtschreibschwäche?',
        reflexes: [
          r.flr,
          r.moro,
          r.tlr,
          r.atnr,
          r.stnr,
          r.babkin,
          r.plantar,
          r.palmar,
          r.righting,
          r.rootingSucking
        ]),
    _q(88, m.school,
        textDe: 'Hat dein Kind Dyskalkulie?',
        helpTextDe:
            'Dyskalkulie ist eine Rechenschwäche, bei der das Verstehen von Zahlen und mathematischen Zusammenhängen trotz normaler Intelligenz dauerhaft schwerfällt. Im Alltag zeigt sich das z. B. durch: Schwierigkeiten beim Wechselgeld zählen, Uhr lesen, Zahlen merken, Mengen schätzen oder bei einfachen Rechenaufgaben immer wieder neu anfangen müssen.',
        reflexes: [
          r.flr,
          r.moro,
          r.tlr,
          r.atnr,
          r.stnr,
          r.babkin,
          r.plantar,
          r.palmar,
          r.righting,
          r.rootingSucking
        ]),
    _q(89, m.school,
        textDe: 'Lässt dein Kind beim Lesen oft Buchstaben oder Wörter aus?',
        reflexes: [r.flr, r.stnr]),
    _q(90, m.school,
        textDe: 'Ermüdet dein Kind schnell beim Lesen?',
        reflexes: [r.flr, r.moro, r.stnr]),
    _q(91, m.school,
        textDe:
            'Hat dein Kind Leseschwierigkeiten (z. B. zu langsam, Wörter auslassen etc.)?',
        reflexes: [r.flr, r.atnr, r.stnr]),
    _q(92, m.school,
        textDe:
            'Kann dein Kind gut vorlesen, weiß aber nicht, was es vorgelesen hat?',
        reflexes: [r.flr, r.spinalGalant, r.atnr]),
    _q(93, m.school, textDe: 'Hat dein Kind Lernschwierigkeiten?', reflexes: [
      r.flr,
      r.moro,
      r.spinalGalant,
      r.tlr,
      r.atnr,
      r.stnr,
      r.landau,
      r.babinski,
      r.babkin,
      r.plantar,
      r.palmar,
      r.righting,
      r.rootingSucking
    ]),
    _q(94, m.school,
        textDe: 'Kann sich dein Kind schlecht konzentrieren?',
        reflexes: [r.flr, r.moro, r.landau]),
    _q(95, m.other,
        textDe: 'Fragt dein Kind oft nach oder sagt oft "was"?',
        reflexes: [r.tlr, r.atnr, r.stnr]),
    _q(96, m.other,
        textDe: 'Leidet dein Kind unter Reiseübelkeit?',
        reflexes: [r.flr, r.moro, r.tlr]),
    _q(97, m.other,
        textDe:
            'Hat dein Kind mit 5 Jahren oder später noch nachts eingenässt?',
        reflexes: [r.spinalGalant]),
    _q(98, m.other,
        textDe:
            'Hat dein Kind mit 5 Jahren oder später noch tagsüber eingenässt?',
        reflexes: [r.spinalGalant]),
    _q(99, m.other,
        textDe: 'Mag dein Kind keine enge Kleidung?',
        reflexes: [r.spinalGalant]),
    _q(100, m.other,
        textDe: 'Trägt dein Kind eine Brille?',
        reflexes: [r.flr, r.tlr, r.atnr, r.stnr]),
    _context(101, m.other, textDe: 'Schielt dein Kind?'),
    _q(102, m.other,
        textDe: 'Hat dein Kind ein schlechtes Zeitgefühl?', reflexes: [r.tlr]),
    _q(103, m.other,
        textDe: 'Leidet dein Kind an Asthma?', reflexes: [r.flr, r.moro]),
    _q(104, m.other,
        textDe: 'Leidet dein Kind an Allergien?', reflexes: [r.flr, r.moro]),
    _q(105, m.other,
        textDe: 'Leidet dein Kind an häufigen Infekten?',
        reflexes: [r.flr, r.moro]),
    _warning(106,
        textDe: 'Hat dein Kind Epilepsie?',
        trainerFlagLabelDe: 'Epilepsie',
        reflexes: [r.flr]),
    _warning(107,
        textDe:
            'Wurde bei deinem Kind eine Autismus-Spektrum-Diagnose gestellt oder befindet sich dies in Abklärung?',
        trainerFlagLabelDe: 'Autismus-Spektrum-Diagnose',
        reflexes: [r.flr]),
    _warning(108,
        textDe: 'Hat dein Kind Trisomie 21 (Downsyndrom)?',
        trainerFlagLabelDe: 'Trisomie 21 / Downsyndrom'),
    _warning(109,
        textDe:
            'Ist dein Kind in psychologischer oder psychiatrischer Behandlung?',
        trainerFlagLabelDe: 'Psychologische / psychiatrische Behandlung',
        reflexes: [r.flr, r.moro]),
  ],
);

final demoChildShortQuestionnaireV1 = ReflexQuestionnaireDefinition(
  id: 'demo_child_short_reflex_profile',
  version: 'demo_child_short_v2_2026_05',
  type: ReflexQuestionnaireType.demoChildShort,
  titleDe: 'Reflexprofil Kurztest',
  titleEn: 'Reflex Profile Quick Check',
  screenTitleDe: 'Reflexprofil Kurztest',
  screenTitleEn: 'Reflex Profile Quick Check',
  scoring: const ReflexScoringDefinition(
    strongPercent: 100,
    elevatedPercent: 80,
    indicationPercent: 50,
  ),
  questions: [
    _demo('demo_delay', 6, m.pregnancyBirth,
        textDe: 'Wurde dein Kind zu früh geboren? (Bsp.: Frühchen)',
        reflexes: [r.delay]),
    _demo('demo_flr', 47, m.behaviorEmotion,
        textDe: 'Ist dein Kind überdurchschnittlich ängstlich?',
        reflexes: [r.flr, r.moro]),
    _demo('demo_moro', 56, m.behaviorEmotion,
        textDe: 'Ist dein Kind leicht ablenkbar?', reflexes: [r.moro]),
    _demo('demo_spinal_galant', 35, m.motorSkills,
        textDe: 'Hat dein Kind einen schiefen Gang?',
        reflexes: [r.spinalGalant]),
    _demo('demo_tlr', 81, m.school,
        textDe: 'Hat dein Kind Schwierigkeiten, von der Tafel abzuschreiben?',
        reflexes: [r.tlr]),
    _demo('demo_atnr', 79, m.drawingWriting,
        textDe:
            'Fällt es deinem Kind schwer, die Linien beim Schreiben einzuhalten?',
        reflexes: [r.atnr]),
    _demo('demo_stnr', 31, m.motorSkills,
        textDe: 'Hat dein Kind das Krabbeln ausgelassen?', reflexes: [r.stnr]),
    _demo('demo_landau', 41, m.motorSkills,
        textDe:
            'Hat oder hatte dein Kind Probleme beim Schwimmenlernen, besonders beim Brustschwimmen?',
        reflexes: [r.stnr, r.landau]),
    _demo('demo_babinski', 27, m.posturePerception,
        textDe: 'Ist dein Kind übermäßig kitzelig an den Füßen?',
        reflexes: [r.babinski]),
    _demo('demo_babkin', 62, m.speech,
        textDe: 'Knirscht dein Kind mit den Zähnen?', reflexes: [r.babkin]),
    _demo('demo_plantar', 37, m.motorSkills,
        textDe: 'Zieht dein Kind Strümpfe und Schuhe umständlich an?',
        reflexes: [r.plantar]),
    _demo('demo_palmar', 71, m.drawingWriting,
        textDe:
            'Drückt dein Kind den Stift beim Schreiben oder Malen sehr stark auf?',
        reflexes: [r.palmar, r.righting]),
    _demo('demo_righting', 73, m.drawingWriting,
        textDe: 'Ermüdet dein Kind sehr schnell beim Malen oder Schreiben?',
        reflexes: [r.stnr, r.palmar, r.righting]),
    _demo('demo_rooting_sucking', 64, m.speech,
        textDe: 'Hat dein Kind einen übermäßig starken Speichelfluss?',
        reflexes: [r.babkin, r.rootingSucking]),
  ],
);

const _childQuestionTextEn = <int, ({String textEn})>{
  1: (textEn: 'Were there any health concerns during the pregnancy?'),
  2: (
    textEn: 'Did you experience any personal difficulties during the pregnancy?'
  ),
  3: (
    textEn:
        'Did you have to remain on bed rest for an extended period during the pregnancy?'
  ),
  4: (textEn: 'Were there any complications during the birth?'),
  5: (textEn: 'Was your child in a breech position at birth?'),
  6: (
    textEn:
        'Was your child born prematurely (for example, as a preterm infant)?'
  ),
  7: (textEn: 'Was there an emergency C-section?'),
  8: (textEn: 'Was your child born by a planned elective C-section?'),
  9: (
    textEn: 'Was the labor unusually short (for example, a precipitous birth)?'
  ),
  10: (textEn: 'Was the labor unusually long?'),
  11: (textEn: 'Were any measures taken to stimulate labor during the birth?'),
  12: (
    textEn: 'Were you given medication to slow or stop labor during the birth?'
  ),
  13: (
    textEn:
        'Did your child spend most of the first few months lying on their back?'
  ),
  14: (textEn: 'Does your child often stand with their feet turned inward?'),
  15: (textEn: 'Does your child experience tension in the neck?'),
  16: (
    textEn:
        'When your child props themselves up on their forearms while lying on their stomach and lifts their upper body and head, do they clench their hands into fists?'
  ),
  17: (textEn: 'Does your child repeatedly curl their toes under?'),
  18: (textEn: 'Can your child stand on one leg for at least 10 seconds?'),
  19: (
    textEn:
        'Can your child stand on one leg with their eyes closed for at least 10 seconds?'
  ),
  20: (textEn: 'Does your child like to sit on one or both feet?'),
  21: (
    textEn:
        'Does your child wrap their legs around the chair legs while sitting?'
  ),
  22: (
    textEn:
        'Does your child often tilt their head downward while looking up from below? (A wary-looking gaze)'
  ),
  23: (
    textEn:
        'Does your child often tilt their head upward while looking downward? (A looking-down-the-nose gaze)'
  ),
  24: (
    textEn: 'Does your child have difficulty sitting still for longer periods?'
  ),
  25: (textEn: 'Does your child rarely lean against the back of a chair?'),
  26: (textEn: 'Does your child frequently sit in a W-sitting position?'),
  27: (textEn: 'Is your child unusually ticklish on their feet?'),
  28: (textEn: 'Is your child unusually ticklish across their body?'),
  29: (textEn: 'Does your child have knock-knees?'),
  30: (textEn: 'Does your child have bowlegs?'),
  31: (textEn: 'Did your child skip the crawling stage?'),
  32: (textEn: 'If not, at what age in months did your child begin crawling?'),
  33: (textEn: 'At what age in months did your child first walk?'),
  34: (textEn: 'Does your child tend to walk on their tiptoes?'),
  35: (textEn: 'Does your child have an uneven gait?'),
  36: (textEn: 'Does your child find it difficult to make a tight fist?'),
  37: (textEn: 'Does your child have difficulty putting on socks and shoes?'),
  38: (
    textEn:
        'Does your child often rest their head on one or both arms while sitting at a table?'
  ),
  39: (
    textEn:
        'Does your child often stretch and squirm while sitting (head back, legs forward)?'
  ),
  40: (textEn: 'Does your child have difficulty catching a ball?'),
  41: (
    textEn:
        'Does your child have, or have they had, difficulty learning to swim, especially breaststroke?'
  ),
  42: (
    textEn:
        'Does your child have difficulty finding their way around or orienting themselves?'
  ),
  43: (textEn: 'Did your child cry excessively during the first few months?'),
  44: (textEn: 'Is your child very sensitive to sounds?'),
  45: (textEn: 'Is your child very sensitive to light or brightness?'),
  46: (textEn: 'Is your child very sensitive to touch?'),
  47: (textEn: 'Is your child unusually anxious?'),
  48: (textEn: 'Does your child experience separation anxiety?'),
  49: (textEn: 'Is your child often tearful?'),
  50: (textEn: 'Is your child easily irritated or quick to become angry?'),
  51: (textEn: 'Does your child often seem disorganized?'),
  52: (textEn: 'Is your child often forgetful?'),
  53: (textEn: 'Does your child enjoy routines?'),
  54: (textEn: 'Does your child like spending time in a fantasy world?'),
  55: (textEn: 'Does your child often get in their own way?'),
  56: (textEn: 'Is your child easily distracted?'),
  57: (textEn: 'Does your child have ADHD or ADD?'),
  58: (textEn: 'Does your child have heightened sensitivity to pain?'),
  59: (textEn: 'Does your child have reduced sensitivity to pain?'),
  60: (textEn: 'Does your child wear, or have they worn, braces?'),
  61: (
    textEn:
        'Does your child have a noticeable dental misalignment or a high-arched palate?'
  ),
  62: (textEn: 'Does your child grind their teeth?'),
  63: (
    textEn:
        'Did your child suck their thumb or use a pacifier for a very long time?'
  ),
  64: (textEn: 'Does your child drool excessively?'),
  65: (
    textEn: 'Does your child make mouth movements while writing or drawing?'
  ),
  66: (
    textEn:
        'Does your child often clench their teeth, especially when concentrating?'
  ),
  67: (
    textEn:
        'Does your child tend to speak unclearly (for example, mumbling or pronouncing sounds incorrectly)?'
  ),
  68: (
    textEn: 'Is your child very talkative or do they talk almost continuously?'
  ),
  69: (textEn: 'Does your child grip a pencil very tightly?'),
  70: (
    textEn: 'Does your child hold a pencil in a fist while drawing or writing?'
  ),
  71: (
    textEn:
        'Does your child press down very hard with a pencil when writing or drawing?'
  ),
  72: (textEn: 'Does your child show little interest in drawing or writing?'),
  73: (textEn: 'Does your child tire very quickly when drawing or writing?'),
  74: (textEn: 'Does your child reverse letters, such as b and d?'),
  75: (textEn: 'Does your child use mirror writing?'),
  76: (
    textEn:
        'Does your child have good verbal knowledge but struggle to put it on paper?'
  ),
  77: (
    textEn:
        'Is your child\'s handwriting difficult to read, especially their cursive writing?'
  ),
  78: (
    textEn:
        'Does your child position the page at a 90-degree angle when drawing or writing?'
  ),
  79: (
    textEn:
        'Does your child find it difficult to stay within the lines when writing?'
  ),
  80: (
    textEn:
        'Does your child experience anxiety about school (stomachaches, nausea, etc.)?'
  ),
  81: (
    textEn:
        'Does your child have difficulty copying from the board (for example, because it is slow or tiring)?'
  ),
  82: (textEn: 'Does your child tend to work too slowly?'),
  83: (textEn: 'Does your child have difficulty with spelling?'),
  84: (textEn: 'Does your child have difficulty with grammar?'),
  85: (textEn: 'Does your child have difficulty with arithmetic?'),
  86: (textEn: 'Does your child struggle with spelling dictation exercises?'),
  87: (textEn: 'Does your child have a reading and spelling difficulty?'),
  88: (textEn: 'Does your child have dyscalculia?'),
  89: (textEn: 'Does your child often skip letters or words while reading?'),
  90: (textEn: 'Does your child tire quickly while reading?'),
  91: (
    textEn:
        'Does your child have difficulty reading (for example, reading too slowly or skipping words)?'
  ),
  92: (
    textEn: 'Can your child read aloud well but not recall what they have read?'
  ),
  93: (textEn: 'Does your child have learning difficulties?'),
  94: (textEn: 'Does your child have difficulty concentrating?'),
  95: (
    textEn:
        'Does your child often ask people to repeat themselves or often say "what"?'
  ),
  96: (textEn: 'Does your child experience motion sickness?'),
  97: (textEn: 'Did your child still wet the bed at night at age 5 or older?'),
  98: (
    textEn:
        'Did your child still wet themselves during the day at age 5 or older?'
  ),
  99: (textEn: 'Does your child dislike tight-fitting clothing?'),
  100: (textEn: 'Does your child wear glasses?'),
  101: (textEn: 'Do your child\'s eyes sometimes turn inward or outward?'),
  102: (textEn: 'Does your child have a poor sense of time?'),
  103: (textEn: 'Does your child have asthma?'),
  104: (textEn: 'Does your child have allergies?'),
  105: (textEn: 'Does your child have frequent infections?'),
  106: (textEn: 'Does your child have epilepsy?'),
  107: (
    textEn:
        'Has your child been diagnosed with an autism spectrum condition, or are they currently being evaluated for one?'
  ),
  108: (textEn: 'Does your child have trisomy 21 (Down syndrome)?'),
  109: (
    textEn:
        'Is your child currently receiving psychological or psychiatric care?'
  ),
};

const _childQuestionHelpTextEn = <int, ({String textEn})>{
  22: (
    textEn:
        'This refers to the observable position of the head and eyes, not a judgment about your child\'s behavior.'
  ),
  23: (
    textEn:
        'This refers to the observable position of the head and eyes, not a judgment about your child\'s behavior.'
  ),
  54: (
    textEn:
        'This does not refer to ordinary imaginative play. It refers to withdrawing deeply into fantasy or daydreaming when this makes everyday situations more difficult.'
  ),
  55: (
    textEn:
        'For example, your child may seem blocked during familiar tasks, have difficulty organizing, avoid the task, or be held back by uncertainty, frustration, or confusion.'
  ),
  88: (
    textEn:
        'Dyscalculia refers to a persistent difficulty understanding numbers and mathematical relationships despite typical intelligence. In everyday life, this may appear as difficulty counting change, telling time, remembering numbers, estimating quantities, or repeatedly having to start over on simple calculations.'
  ),
};

const _childQuestionTrainerFlagLabelEn = <int, ({String textEn})>{
  57: (textEn: 'ADHD / ADD'),
  106: (textEn: 'Epilepsy'),
  107: (textEn: 'Autism spectrum diagnosis'),
  108: (textEn: 'Trisomy 21 / Down syndrome'),
  109: (textEn: 'Psychological / psychiatric care'),
};

const _demoQuestionTextEn = <String, ({String textEn})>{
  'demo_delay': (
    textEn:
        'Was your child born prematurely (for example, as a preterm infant)?'
  ),
  'demo_flr': (textEn: 'Is your child unusually anxious?'),
  'demo_moro': (textEn: 'Is your child easily distracted?'),
  'demo_spinal_galant': (textEn: 'Does your child have an uneven gait?'),
  'demo_tlr': (
    textEn: 'Does your child have difficulty copying from the board?'
  ),
  'demo_atnr': (
    textEn:
        'Does your child find it difficult to stay within the lines when writing?'
  ),
  'demo_stnr': (textEn: 'Did your child skip the crawling stage?'),
  'demo_landau': (
    textEn:
        'Does your child have, or have they had, difficulty learning to swim, especially breaststroke?'
  ),
  'demo_babinski': (textEn: 'Is your child unusually ticklish on their feet?'),
  'demo_babkin': (textEn: 'Does your child grind their teeth?'),
  'demo_plantar': (
    textEn: 'Does your child have difficulty putting on socks and shoes?'
  ),
  'demo_palmar': (
    textEn:
        'Does your child press down very hard with a pencil when writing or drawing?'
  ),
  'demo_righting': (
    textEn: 'Does your child tire very quickly when drawing or writing?'
  ),
  'demo_rooting_sucking': (textEn: 'Does your child drool excessively?'),
};

const m = _ModuleRefs();
const r = _ReflexRefs();

class _ModuleRefs {
  const _ModuleRefs();

  ReflexQuestionModule get pregnancyBirth =>
      ReflexQuestionModule.pregnancyBirth;
  ReflexQuestionModule get posturePerception =>
      ReflexQuestionModule.posturePerception;
  ReflexQuestionModule get motorSkills => ReflexQuestionModule.motorSkills;
  ReflexQuestionModule get behaviorEmotion =>
      ReflexQuestionModule.behaviorEmotion;
  ReflexQuestionModule get speech => ReflexQuestionModule.speech;
  ReflexQuestionModule get drawingWriting =>
      ReflexQuestionModule.drawingWriting;
  ReflexQuestionModule get school => ReflexQuestionModule.school;
  ReflexQuestionModule get other => ReflexQuestionModule.other;
}

class _ReflexRefs {
  const _ReflexRefs();

  PrimitiveReflex get delay => PrimitiveReflex.delay;
  PrimitiveReflex get flr => PrimitiveReflex.flr;
  PrimitiveReflex get moro => PrimitiveReflex.moro;
  PrimitiveReflex get spinalGalant => PrimitiveReflex.spinalGalant;
  PrimitiveReflex get tlr => PrimitiveReflex.tlr;
  PrimitiveReflex get atnr => PrimitiveReflex.atnr;
  PrimitiveReflex get stnr => PrimitiveReflex.stnr;
  PrimitiveReflex get landau => PrimitiveReflex.landau;
  PrimitiveReflex get babinski => PrimitiveReflex.babinski;
  PrimitiveReflex get babkin => PrimitiveReflex.babkin;
  PrimitiveReflex get plantar => PrimitiveReflex.plantar;
  PrimitiveReflex get palmar => PrimitiveReflex.palmar;
  PrimitiveReflex get righting => PrimitiveReflex.righting;
  PrimitiveReflex get rootingSucking => PrimitiveReflex.rootingSucking;
}

ReflexQuestion _q(
  int number,
  ReflexQuestionModule module, {
  required String textDe,
  List<PrimitiveReflex> reflexes = const [],
  String? helpTextDe,
  String? trainerFlagLabelDe,
}) {
  return ReflexQuestion(
    id: _questionId(number),
    number: number,
    module: module,
    textDe: textDe,
    textEn: _childQuestionTextEn[number]!.textEn,
    answerType: ReflexAnswerType.yesNoUnknown,
    reflexes: reflexes,
    helpTextDe: helpTextDe,
    helpTextEn:
        helpTextDe == null ? null : _childQuestionHelpTextEn[number]!.textEn,
    trainerFlagLabelDe: trainerFlagLabelDe,
    trainerFlagLabelEn: trainerFlagLabelDe == null
        ? null
        : _childQuestionTrainerFlagLabelEn[number]!.textEn,
  );
}

ReflexQuestion _context(
  int number,
  ReflexQuestionModule module, {
  required String textDe,
  ReflexAnswerType answerType = ReflexAnswerType.yesNoUnknown,
  String? followUpOf,
}) {
  return ReflexQuestion(
    id: _questionId(number),
    number: number,
    module: module,
    textDe: textDe,
    textEn: _childQuestionTextEn[number]!.textEn,
    answerType: answerType,
    role: ReflexQuestionRole.context,
    followUpOf: followUpOf,
  );
}

ReflexQuestion _warning(
  int number, {
  required String textDe,
  required String trainerFlagLabelDe,
  List<PrimitiveReflex> reflexes = const [],
}) {
  return ReflexQuestion(
    id: _questionId(number),
    number: number,
    module: ReflexQuestionModule.other,
    textDe: textDe,
    textEn: _childQuestionTextEn[number]!.textEn,
    answerType: ReflexAnswerType.yesNoUnknown,
    role:
        reflexes.isEmpty ? ReflexQuestionRole.safety : ReflexQuestionRole.score,
    reflexes: reflexes,
    warningRule: ReflexWarningRule.professionalClearanceRequired,
    trainerFlagLabelDe: trainerFlagLabelDe,
    trainerFlagLabelEn: _childQuestionTrainerFlagLabelEn[number]!.textEn,
  );
}

ReflexQuestion _demo(
  String id,
  int sourceNumber,
  ReflexQuestionModule module, {
  required String textDe,
  required List<PrimitiveReflex> reflexes,
}) {
  return ReflexQuestion(
    id: id,
    number: sourceNumber,
    module: module,
    textDe: textDe,
    textEn: _demoQuestionTextEn[id]!.textEn,
    answerType: ReflexAnswerType.yesNoUnknown,
    reflexes: reflexes,
  );
}

String _questionId(int number) => 'q${number.toString().padLeft(3, '0')}';
