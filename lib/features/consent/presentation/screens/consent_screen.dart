import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/consent_provider.dart';
import '../../../../core/l10n/app_languages.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../onboarding/presentation/widgets/pre_payoff_step_dots.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _agreed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Remote consent may exist without a local prefs flag (other device).
    // Skip the form if the async check says already done — no Dashboard hop.
    WidgetsBinding.instance.addPostFrameCallback((_) => _skipIfAlreadyConsented());
  }

  Future<void> _skipIfAlreadyConsented() async {
    final consented = await ref.read(hasConsentedProvider.future);
    if (!mounted || consented != true) return;
    context.go('/dashboard');
  }

  Future<void> _confirm() async {
    if (!_agreed || _saving) return;
    setState(() => _saving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
        );
        return;
      }

      // Write to Supabase for permanent audit trail.
      // Best-effort — if Supabase is unavailable, local cache is used.
      try {
        await Supabase.instance.client.from('user_consents').upsert({
          'user_id': userId,
          'consent_version': kConsentVersion,
          'consented_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (_) {}

      // Cache locally — this is the source of truth for day-to-day checks.
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(consentPrefKey(userId), true);

      ref.invalidate(hasConsentedProvider);

      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openDocumentSheet({
    required String title,
    required Widget body,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final height = MediaQuery.sizeOf(ctx).height * 0.88;
        return SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          title,
                          style:
                              Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lawyer-owned bilingual copy below stays untouched; only the language
    // switch is registry-driven (unsupported locales read the EN version).
    final isDE =
        ref.watch(settingsProvider).languageCode == AppLanguages.sourceCode;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PrePayoffStepDots(currentStep: 2),
                    const SizedBox(height: 28),
                    Text(
                      l10n.consentShortTitle,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.consentDiscoverLead,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 28),
                    _ConsentDocRow(
                      title: l10n.consentRowSafety,
                      hint: l10n.consentReadLinkHint,
                      onTap: () => _openDocumentSheet(
                        title: l10n.consentRowSafety,
                        body: _SafetyTab(isDE: isDE),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ConsentDocRow(
                      title: l10n.consentRowTerms,
                      hint: l10n.consentReadLinkHint,
                      onTap: () => _openDocumentSheet(
                        title: l10n.consentRowTerms,
                        body: _TermsTab(isDE: isDE),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ConsentDocRow(
                      title: l10n.consentRowPrivacy,
                      hint: l10n.consentReadLinkHint,
                      onTap: () => _openDocumentSheet(
                        title: l10n.consentRowPrivacy,
                        body: _PrivacyTab(isDE: isDE),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Agreement checkbox + discover CTA ──────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: const Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      l10n.consentCheckboxLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    key: const Key('consent_discover_cta'),
                    onPressed: (_agreed && !_saving) ? _confirm : null,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.consentDiscoverCta,
                            textAlign: TextAlign.center,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentDocRow extends StatelessWidget {
  const _ConsentDocRow({
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                hint,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 1: Safety & Medical Disclaimer ────────────────────────────────────────

class _SafetyTab extends StatelessWidget {
  final bool isDE;
  const _SafetyTab({required this.isDE});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: isDE ? _buildDE(context) : _buildEN(context),
    );
  }

  Widget _buildDE(BuildContext context) {
    return const _ConsentContent(
      title: 'Medizinische und psychologische Hinweise',
      intro:
          'Das Reflexintegrations-Programm ist eine intensive körperliche und psychische Arbeit. '
          'Es kann tiefgreifende Veränderungsprozesse in Gang setzen. '
          'Bitte lies die folgenden Hinweise sorgfältig durch.',
      points: [
        _ConsentPoint(
          icon: Icons.science_outlined,
          title: 'MVP-Prototyp — Testphase',
          body:
              'Diese App befindet sich in einer frühen Testphase. Du nimmst als freiwilliger '
              'Testnutzer teil. Es bestehen keine Garantien auf Datensicherheit oder dauerhaften Betrieb. '
              'Daten können zur Produktverbesserung verwendet werden. Du kannst die Nutzung jederzeit einstellen.',
        ),
        _ConsentPoint(
          icon: Icons.favorite_border,
          title: 'Kein Ersatz für medizinische Behandlung',
          body:
              'Dieses Programm ersetzt keine medizinische, therapeutische oder psychologische Behandlung. '
              'Bei ernsthaften Beschwerden, Trauma-Symptomen oder Unsicherheit wende dich an einen '
              'Arzt, Therapeuten oder eine Krisenhotline.',
        ),
        _ConsentPoint(
          icon: Icons.psychology_outlined,
          title: 'Emotionale und mentale Belastung',
          body:
              'Das Training kann Reizbarkeit, Stimmungsschwankungen oder vorübergehenden Stress auslösen. '
              'Das ist ein normaler Teil des Integrationsprozesses.',
        ),
        _ConsentPoint(
          icon: Icons.layers_outlined,
          title: 'Verdrängte Erlebnisse können auftauchen',
          body:
              'In manchen Fällen können tief liegende Erlebnisse oder Traumata an die Oberfläche kommen. '
              'Wir empfehlen psychologische Unterstützung während des Programms.',
        ),
        _ConsentPoint(
          icon: Icons.bedtime_outlined,
          title: 'Schlafveränderungen möglich',
          body:
              'Vorübergehende Schlafstörungen oder veränderte Schlafmuster können auftreten, '
              'besonders in intensiveren Programmphasen.',
        ),
        _ConsentPoint(
          icon: Icons.self_improvement_outlined,
          title: 'Deine Verantwortung',
          body: 'Nur du kennst deinen Körper und deine Grenzen. '
              'Mache Pausen wenn nötig und suche professionelle Hilfe bei Überforderung.',
        ),
      ],
      closing:
          'Indem du fortfährst, bestätigst du, dass du diese Hinweise gelesen und '
          'verstanden hast und freiwillig an diesem Programm teilnimmst.',
    );
  }

  Widget _buildEN(BuildContext context) {
    return const _ConsentContent(
      title: 'Medical and Psychological Disclaimer',
      intro:
          'The Reflex Integration Program involves intensive physical and psychological work. '
          'It can initiate profound processes of change. '
          'Please read the following information carefully.',
      points: [
        _ConsentPoint(
          icon: Icons.science_outlined,
          title: 'MVP Prototype — Test Phase',
          body:
              'This app is in an early test phase. You participate as a voluntary test user. '
              'There are no guarantees regarding data security or continued availability. '
              'Data may be used for product improvement. You may stop at any time.',
        ),
        _ConsentPoint(
          icon: Icons.favorite_border,
          title: 'Not a replacement for medical treatment',
          body:
              'This program does not replace medical, therapeutic, or psychological treatment. '
              'For serious distress or trauma symptoms, consult a doctor, therapist, or crisis helpline.',
        ),
        _ConsentPoint(
          icon: Icons.psychology_outlined,
          title: 'Emotional and mental stress',
          body:
              'The training may trigger irritability, mood changes, or heightened stress. '
              'This is a normal part of the integration process.',
        ),
        _ConsentPoint(
          icon: Icons.layers_outlined,
          title: 'Buried experiences may surface',
          body:
              'Deep-seated or suppressed experiences may come to the surface. '
              'We recommend having access to psychological support during the program.',
        ),
        _ConsentPoint(
          icon: Icons.bedtime_outlined,
          title: 'Sleep changes are possible',
          body: 'Temporary sleep disturbances may occur, '
              'especially during more intensive phases.',
        ),
        _ConsentPoint(
          icon: Icons.self_improvement_outlined,
          title: 'Your responsibility',
          body: 'Only you know your limits. Take breaks when needed and seek '
              'professional help if overwhelmed.',
        ),
      ],
      closing:
          'By continuing, you confirm that you have read and understood this information '
          'and are voluntarily participating in this program.',
    );
  }
}

// ── Tab 2: Nutzungsbedingungen / Terms of Use ─────────────────────────────────

class _TermsTab extends StatelessWidget {
  final bool isDE;
  const _TermsTab({required this.isDE});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: isDE ? _buildDE(context) : _buildEN(context),
    );
  }

  Widget _buildDE(BuildContext context) {
    return const _ConsentContent(
      title: 'Nutzungsbedingungen (vorläufig)',
      intro:
          'Diese vorläufigen Nutzungsbedingungen gelten für die Nutzung der Reflex Journey-App '
          'in der aktuellen Testphase. Sie werden vor einem öffentlichen Launch durch rechtsverbindliche '
          'Bedingungen ersetzt.',
      points: [
        _ConsentPoint(
          icon: Icons.gavel_outlined,
          title: '§ 1 Geltungsbereich',
          body:
              'Diese Bedingungen gelten zwischen dem Nutzer und dem Anbieter Alexander Messinger '
              '(nachfolgend „Anbieter") für die Nutzung der mobilen Anwendung Reflex Journey in der '
              'aktuellen Testphase. Mit der Registrierung akzeptierst du diese Bedingungen.',
        ),
        _ConsentPoint(
          icon: Icons.person_outlined,
          title: '§ 2 Nutzerberechtigung',
          body: 'Die App richtet sich an Erwachsene ab 18 Jahren. '
              'Du bestätigst, dass du das 18. Lebensjahr vollendet hast. '
              'Die Nutzung durch Minderjährige ist nur mit ausdrücklicher Einwilligung '
              'eines Erziehungsberechtigten gestattet.',
        ),
        _ConsentPoint(
          icon: Icons.build_outlined,
          title: '§ 3 Leistungsumfang & Verfügbarkeit',
          body:
              'Der Anbieter stellt die App im Rahmen einer Testphase kostenlos zur Verfügung. '
              'Es besteht kein Anspruch auf dauerhaften Betrieb, bestimmte Funktionen oder '
              'Fehlerfreiheit. Der Anbieter kann den Dienst jederzeit einstellen oder ändern.',
        ),
        _ConsentPoint(
          icon: Icons.copyright_outlined,
          title: '§ 4 Geistiges Eigentum',
          body:
              'Alle Inhalte der App (Texte, Grafiken, Übungen, Code) sind Eigentum des Anbieters '
              'und urheberrechtlich geschützt. Eine Vervielfältigung oder Weitergabe ohne '
              'ausdrückliche Genehmigung ist untersagt.',
        ),
        _ConsentPoint(
          icon: Icons.block_outlined,
          title: '§ 5 Verbotene Nutzung',
          body:
              'Du verpflichtest dich, die App nicht für rechtswidrige Zwecke zu nutzen, '
              'keine schädlichen Inhalte einzustellen und die technische Infrastruktur nicht '
              'zu beeinträchtigen.',
        ),
        _ConsentPoint(
          icon: Icons.balance_outlined,
          title: '§ 6 Haftungsausschluss',
          body:
              'Der Anbieter haftet nicht für Schäden, die durch die Nutzung der App entstehen, '
              'soweit diese nicht auf grober Fahrlässigkeit oder Vorsatz beruhen. '
              'Dies gilt insbesondere für gesundheitliche Folgen der Trainingsausführung.',
        ),
        _ConsentPoint(
          icon: Icons.flag_outlined,
          title: '§ 7 Anwendbares Recht',
          body: 'Es gilt das Recht der Bundesrepublik Deutschland. '
              'Gerichtsstand ist, soweit gesetzlich zulässig, der Sitz des Anbieters.',
        ),
      ],
      closing:
          'Diese Nutzungsbedingungen sind vorläufig und werden vor einem öffentlichen Release '
          'durch einen Rechtsanwalt geprüft und finalisiert.',
    );
  }

  Widget _buildEN(BuildContext context) {
    return const _ConsentContent(
      title: 'Terms of Use (Provisional)',
      intro:
          'These provisional Terms of Use apply to the use of the Reflex Journey app during '
          'the current test phase. They will be replaced by legally binding terms before '
          'a public launch.',
      points: [
        _ConsentPoint(
          icon: Icons.gavel_outlined,
          title: '§ 1 Scope',
          body:
              'These terms apply between the user and the provider Alexander Messinger '
              '(hereinafter "Provider") for use of the Reflex Journey mobile application during '
              'the test phase. By registering, you accept these terms.',
        ),
        _ConsentPoint(
          icon: Icons.person_outlined,
          title: '§ 2 Eligibility',
          body: 'The app is intended for adults aged 18 and over. '
              'You confirm that you are at least 18 years old. '
              'Use by minors is only permitted with the express consent of a parent or guardian.',
        ),
        _ConsentPoint(
          icon: Icons.build_outlined,
          title: '§ 3 Scope of Services & Availability',
          body:
              'The Provider makes the app available free of charge during the test phase. '
              'There is no entitlement to continued operation, specific features, or freedom from errors. '
              'The Provider may discontinue or modify the service at any time.',
        ),
        _ConsentPoint(
          icon: Icons.copyright_outlined,
          title: '§ 4 Intellectual Property',
          body:
              'All app content (texts, graphics, exercises, code) is the property of the Provider '
              'and is protected by copyright. Reproduction or distribution without express '
              'permission is prohibited.',
        ),
        _ConsentPoint(
          icon: Icons.block_outlined,
          title: '§ 5 Prohibited Use',
          body:
              'You agree not to use the app for unlawful purposes, not to post harmful content, '
              'and not to interfere with the technical infrastructure.',
        ),
        _ConsentPoint(
          icon: Icons.balance_outlined,
          title: '§ 6 Limitation of Liability',
          body:
              'The Provider is not liable for damages arising from the use of the app unless '
              'caused by gross negligence or intent. This applies in particular to health '
              'consequences of performing the exercises.',
        ),
        _ConsentPoint(
          icon: Icons.flag_outlined,
          title: '§ 7 Governing Law',
          body: 'The law of the Federal Republic of Germany applies. '
              'The place of jurisdiction is, to the extent permitted by law, the Provider\'s place of business.',
        ),
      ],
      closing:
          'These Terms of Use are provisional and will be reviewed and finalised by a lawyer '
          'before a public release.',
    );
  }
}

// ── Tab 3: Datenschutzerklärung / Privacy Policy ──────────────────────────────

/// T05 Stufe 2 (nach P0.6/Anwalt): auf `true` stellen, Anwalts-Formulierungen
/// in die _buildLaunchDraft*-Methoden einarbeiten und `kConsentVersion`
/// bumpen (Re-Consent-Mechanik existiert). Bis dahin bleibt die
/// Testphasen-Fassung aktiv — der Entwurf ist bewusst toter Code.
const bool kUsePrivacyLaunchDraft = false;

class _PrivacyTab extends StatelessWidget {
  final bool isDE;
  const _PrivacyTab({required this.isDE});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: isDE
          ? (kUsePrivacyLaunchDraft
              ? _buildLaunchDraftDE(context)
              : _buildDE(context))
          : (kUsePrivacyLaunchDraft
              ? _buildLaunchDraftEN(context)
              : _buildEN(context)),
    );
  }

  Widget _buildDE(BuildContext context) {
    return const _ConsentContent(
      title: 'Datenschutzerklärung (vorläufig)',
      intro:
          'Diese vorläufige Datenschutzerklärung informiert dich über die Verarbeitung '
          'personenbezogener Daten in der Reflex Journey-Testphase gemäß DSGVO.',
      points: [
        _ConsentPoint(
          icon: Icons.person_pin_outlined,
          title: 'Verantwortlicher',
          body: 'Verantwortlicher im Sinne der DSGVO: Alexander Messinger. '
              'Kontakt für Datenschutzanfragen: über die in der App hinterlegten Kontaktdaten.',
        ),
        _ConsentPoint(
          icon: Icons.storage_outlined,
          title: 'Erhobene Daten',
          body:
              'Wir erheben folgende Daten: E-Mail-Adresse und Passwort (für die Registrierung), '
              'Fortschrittsdaten (Trainingseinheiten, Intake-Assessment), '
              'Stimmungsdaten (Mood-Checkins, Journal-Einträge), '
              'deine optionale Angabe dazu, was dich hierher geführt hat (Einstiegsbereich), sowie '
              'Geräteinformationen (Betriebssystem, App-Version).',
        ),
        _ConsentPoint(
          icon: Icons.task_alt_outlined,
          title: 'Zweck der Verarbeitung',
          body:
              'Die Daten werden verwendet für: Bereitstellung und Verbesserung der App-Funktionen, '
              'Speicherung und Synchronisierung deines Trainingsfortschritts, '
              'Analyse zur Produktverbesserung (anonymisiert, soweit möglich) sowie '
              'Kommunikation im Rahmen der Testphase.',
        ),
        _ConsentPoint(
          icon: Icons.cloud_outlined,
          title: 'Datenverarbeitung & Speicherort',
          body:
              'Deine Daten werden verschlüsselt auf Servern von Supabase (EU-Region) gespeichert. '
              'Supabase ist ein zertifizierter Cloud-Anbieter und verarbeitet Daten gemäß DSGVO. '
              'Lokal auf deinem Gerät werden Daten für die Offline-Funktionalität in einer '
              'app-eigenen Datenbank gehalten, die nur diese App lesen kann, durch die '
              'Geräteverschlüsselung deines Betriebssystems geschützt ist und von '
              'Geräte-Backups ausgeschlossen wird.',
        ),
        _ConsentPoint(
          icon: Icons.share_outlined,
          title: 'Weitergabe an Dritte',
          body:
              'Deine Daten werden nicht an Dritte zu kommerziellen Zwecken verkauft oder weitergegeben. '
              'Eine Übermittlung erfolgt nur an technische Dienstleister (Supabase) im Rahmen '
              'der Auftragsverarbeitung gemäß Art. 28 DSGVO.',
        ),
        _ConsentPoint(
          icon: Icons.timer_outlined,
          title: 'Speicherdauer',
          body:
              'Deine Daten werden für die Dauer der Testphase und bis zu 6 Monate danach gespeichert. '
              'Auf Anfrage werden alle personenbezogenen Daten unverzüglich gelöscht.',
        ),
        _ConsentPoint(
          icon: Icons.verified_user_outlined,
          title: 'Deine Rechte (DSGVO)',
          body:
              'Du hast das Recht auf: Auskunft (Art. 15), Berichtigung (Art. 16), '
              'Löschung (Art. 17), Einschränkung der Verarbeitung (Art. 18), '
              'Datenübertragbarkeit (Art. 20) und Widerspruch (Art. 21). '
              'Zur Geltendmachung deiner Rechte kontaktiere uns über die App.',
        ),
        _ConsentPoint(
          icon: Icons.notifications_none_outlined,
          title: 'Push-Benachrichtigungen',
          body:
              'Wenn du Erinnerungen aktivierst, werden lokale Push-Benachrichtigungen '
              'auf deinem Gerät geplant. Diese Daten verlassen dein Gerät nicht.',
        ),
      ],
      closing:
          'Diese Datenschutzerklärung ist vorläufig und wird vor einem öffentlichen Release '
          'durch einen Datenschutzbeauftragten geprüft und gemäß DSGVO finalisiert. '
          'Durch die Nutzung stimmst du dieser vorläufigen Datenschutzerklärung zu.',
    );
  }

  Widget _buildEN(BuildContext context) {
    return const _ConsentContent(
      title: 'Privacy Policy (Provisional)',
      intro:
          'This provisional Privacy Policy informs you about the processing of personal data '
          'in the Reflex Journey test phase in accordance with GDPR.',
      points: [
        _ConsentPoint(
          icon: Icons.person_pin_outlined,
          title: 'Data Controller',
          body:
              'The data controller within the meaning of the GDPR: Alexander Messinger. '
              'For privacy inquiries, use the contact information provided in the app.',
        ),
        _ConsentPoint(
          icon: Icons.storage_outlined,
          title: 'Data Collected',
          body: 'We collect: email address and password (for registration), '
              'progress data (training sessions, intake assessment), '
              'mood data (mood check-ins, journal entries), '
              'your optional entry point selection (what brought you here), and '
              'device information (OS, app version).',
        ),
        _ConsentPoint(
          icon: Icons.task_alt_outlined,
          title: 'Purpose of Processing',
          body: 'Data is used for: providing and improving app features, '
              'storing and syncing your training progress, '
              'anonymised product analytics, and '
              'communication during the test phase.',
        ),
        _ConsentPoint(
          icon: Icons.cloud_outlined,
          title: 'Data Processing & Storage',
          body:
              'Your data is stored encrypted on Supabase servers (EU region). '
              'Supabase is a certified GDPR-compliant cloud provider. '
              'Locally on your device, data is held for offline functionality in an '
              'app-private database that only this app can read, is protected by your '
              'operating system\'s device encryption, and is excluded from device backups.',
        ),
        _ConsentPoint(
          icon: Icons.share_outlined,
          title: 'Third-Party Sharing',
          body:
              'Your data is not sold or shared with third parties for commercial purposes. '
              'Transmission occurs only to technical service providers (Supabase) '
              'under a data processing agreement per Art. 28 GDPR.',
        ),
        _ConsentPoint(
          icon: Icons.timer_outlined,
          title: 'Retention Period',
          body:
              'Your data is stored for the duration of the test phase and up to 6 months thereafter. '
              'On request, all personal data will be deleted without delay.',
        ),
        _ConsentPoint(
          icon: Icons.verified_user_outlined,
          title: 'Your Rights (GDPR)',
          body:
              'You have the right to: access (Art. 15), rectification (Art. 16), '
              'erasure (Art. 17), restriction of processing (Art. 18), '
              'data portability (Art. 20), and objection (Art. 21). '
              'To exercise your rights, contact us via the app.',
        ),
        _ConsentPoint(
          icon: Icons.notifications_none_outlined,
          title: 'Push Notifications',
          body:
              'If you enable reminders, local push notifications are scheduled on your device. '
              'This data does not leave your device.',
        ),
      ],
      closing:
          'This Privacy Policy is provisional and will be reviewed by a data protection officer '
          'and finalised in accordance with GDPR before a public release. '
          'By using the app, you agree to this provisional Privacy Policy.',
    );
  }

  // ═══ ENTWURF — Launch-Fassung (T05 Stufe 1, 2026-07-07) — NICHT AKTIV ═══
  //
  // Aktivierung (Stufe 2, nach P0.6): kUsePrivacyLaunchDraft=true,
  // Anwalts-Formulierungen einarbeiten, kConsentVersion bumpen.
  //
  // Beleg-Liste für den Anwalt — jede Tatsachenbehauptung ist im Code belegt:
  // • „Supabase, EU-Region“ → Backlog P0.4 ✅ 2026-07-02 (West EU/Irland).
  // • „app-eigene DB, Geräteverschlüsselung, von Backups ausgeschlossen“
  //   → P0.5, Commit c654998 (iOS backup-excluded local_store/,
  //   Android allowBackup=false).
  // • „Konto und Daten jederzeit in der App löschbar“ → P0.5-Verifikation:
  //   profile_screen `rpc('delete_user')` + `clearUserData()` wischt alle
  //   8 lokalen Nutzertabellen.
  // • „Standort nur auf Anfrage, nicht gespeichert“ + „OSMF erhält IP und
  //   Kartengebiet“ → docs/STANDORT_DATENFLUSS_T13.md (RPC `STABLE`,
  //   nutzerinitiierter CTA, kein Persistenzpfad).
  // • „Geräte-Token über Firebase Cloud Messaging“ → lib/core/push/,
  //   Live-Tabelle device_tokens (4 Policies).
  // • „Resend (System-E-Mails)“ → P1.4: Custom SMTP send.reflexjourney.de.
  // • „Kinderprofile durch Kontoinhaber“ → Tabelle reflex_subject_profiles
  //   (owner-scoped RLS, kein Kinder-Login).
  // • Kein Tracking/keine Analytics behauptet → pubspec enthält kein
  //   Analytics-/Ad-SDK (Firebase Analytics/Crashlytics nicht eingebunden).
  // • Agora bewusst NICHT genannt → Video-Calls deaktiviert (D2=A,
  //   kVideoCallsEnabled=false); vor Reaktivierung Consent erweitern
  //   (Merkposten R9 im Backlog).
  // • „Sentry (Absturzberichte)“ → T15: lib/core/monitoring/sentry_service.dart
  //   — sendDefaultPii=false, beforeSend strippt Request/User/Extra,
  //   HTTP-/Navigations-Breadcrumbs verworfen; nur Fehlertyp, Stacktrace,
  //   Geräte-/OS-Kontext; EU-Datenhaltung (Founder legt Projekt in
  //   EU-Region an, Entscheidung 8.6).

  Widget _buildLaunchDraftDE(BuildContext context) {
    return const _ConsentContent(
      title: 'Datenschutzerklärung',
      intro:
          'Diese Datenschutzerklärung informiert dich darüber, wie Reflex Journey '
          'personenbezogene Daten gemäß DSGVO verarbeitet.',
      points: [
        _ConsentPoint(
          icon: Icons.person_pin_outlined,
          title: 'Verantwortlicher',
          body: 'Verantwortlicher im Sinne der DSGVO: Alexander Messinger. '
              'Kontakt für Datenschutzanfragen: über die in der App hinterlegten '
              'Kontaktdaten.',
        ),
        _ConsentPoint(
          icon: Icons.storage_outlined,
          title: 'Erhobene Daten',
          body: 'Wir verarbeiten: E-Mail-Adresse und Passwort (Registrierung), '
              'Fortschrittsdaten (Trainingseinheiten, Einstiegsfragebogen), '
              'Stimmungs- und Journaldaten, deine optionale Angabe zum '
              'Einstiegsbereich, Geräteinformationen (Betriebssystem, App-Version) '
              'sowie — wenn du Mitteilungen aktivierst — ein Geräte-Token für '
              'Push-Nachrichten.',
        ),
        _ConsentPoint(
          icon: Icons.escalator_warning_outlined,
          title: 'Profile für Kinder',
          body: 'Profile für Kinder werden ausschließlich durch den '
              'erziehungsberechtigten Kontoinhaber angelegt und verwaltet. '
              'Die Daten des Kindes (z. B. Name, Geburtsdatum, '
              'Trainingsfortschritt) gehören zu deinem Konto und werden wie '
              'deine eigenen Daten geschützt.',
        ),
        _ConsentPoint(
          icon: Icons.near_me_outlined,
          title: 'Standort & Karte',
          body: 'Dein Standort wird nur auf deine Anfrage für die Trainer-Suche '
              'verwendet und nicht gespeichert. Beim Anzeigen der Karte werden '
              'Kartenkacheln von Servern der OpenStreetMap Foundation geladen; '
              'diese erhält dabei technisch bedingt deine IP-Adresse und das '
              'angezeigte Kartengebiet.',
        ),
        _ConsentPoint(
          icon: Icons.task_alt_outlined,
          title: 'Zweck der Verarbeitung',
          body: 'Bereitstellung der App-Funktionen, Speicherung und '
              'Synchronisierung deines Trainingsfortschritts, Zustellung von '
              'Mitteilungen und Erinnerungen sowie System-E-Mails zu deinem '
              'Konto (z. B. Registrierungs-Bestätigung, Passwort-Zurücksetzen).',
        ),
        _ConsentPoint(
          icon: Icons.cloud_outlined,
          title: 'Datenverarbeitung & Speicherort',
          body:
              'Deine Daten werden verschlüsselt auf Servern von Supabase (EU-Region) '
              'gespeichert. Lokal auf deinem Gerät werden Daten für die '
              'Offline-Funktionalität in einer app-eigenen Datenbank gehalten, die '
              'nur diese App lesen kann, durch die Geräteverschlüsselung deines '
              'Betriebssystems geschützt ist und von Geräte-Backups ausgeschlossen '
              'wird.',
        ),
        _ConsentPoint(
          icon: Icons.share_outlined,
          title: 'Auftragsverarbeiter & Empfänger',
          body: 'Deine Daten werden nicht verkauft. Eine Übermittlung erfolgt nur '
              'an technische Dienstleister im Rahmen der Auftragsverarbeitung '
              '(Art. 28 DSGVO): Supabase (Datenbank und Anmeldung, EU-Region), '
              'Google Firebase Cloud Messaging (Zustellung von Push-Nachrichten), '
              'Resend (Versand von System-E-Mails) und Sentry (anonymisierte '
              'Absturzberichte: Fehlertyp, technischer Ablauf, Gerätemodell — '
              'keine Inhalte, EU-Datenhaltung). Beim Kartenabruf in der '
              'Trainer-Suche ist die OpenStreetMap Foundation externer Empfänger '
              '(IP-Adresse, Kartengebiet).',
        ),
        _ConsentPoint(
          icon: Icons.notifications_none_outlined,
          title: 'Push-Benachrichtigungen',
          body: 'Erinnerungen können lokal auf deinem Gerät geplant werden. Für '
              'Mitteilungen (z. B. Nachrichten deines Trainers) wird ein '
              'Geräte-Token über Google Firebase Cloud Messaging verarbeitet. '
              'Mitteilungen kannst du in den Systemeinstellungen jederzeit '
              'deaktivieren.',
        ),
        _ConsentPoint(
          icon: Icons.timer_outlined,
          title: 'Speicherdauer',
          body: 'Deine Daten bleiben gespeichert, bis du dein Konto löschst. '
              'Konto und Daten kannst du jederzeit direkt in der App löschen; '
              'Details zur Speicherdauer einzelner Datenarten regelt die '
              'Datenschutzerklärung.',
        ),
        _ConsentPoint(
          icon: Icons.verified_user_outlined,
          title: 'Deine Rechte (DSGVO)',
          body: 'Du hast das Recht auf: Auskunft (Art. 15), Berichtigung (Art. 16), '
              'Löschung (Art. 17), Einschränkung der Verarbeitung (Art. 18), '
              'Datenübertragbarkeit (Art. 20) und Widerspruch (Art. 21). '
              'Zur Geltendmachung deiner Rechte kontaktiere uns über die App.',
        ),
      ],
      closing:
          'Die vollständige Datenschutzerklärung findest du jederzeit unter '
          'reflexjourney.app/datenschutz.',
    );
  }

  Widget _buildLaunchDraftEN(BuildContext context) {
    return const _ConsentContent(
      title: 'Privacy Policy',
      intro:
          'This Privacy Policy explains how Reflex Journey processes personal data '
          'in accordance with the GDPR.',
      points: [
        _ConsentPoint(
          icon: Icons.person_pin_outlined,
          title: 'Data Controller',
          body:
              'The data controller within the meaning of the GDPR: Alexander Messinger. '
              'For privacy inquiries, use the contact information provided in the app.',
        ),
        _ConsentPoint(
          icon: Icons.storage_outlined,
          title: 'Data We Process',
          body: 'We process: email address and password (registration), '
              'progress data (training sessions, intake questionnaire), '
              'mood and journal data, your optional entry-point selection, '
              'device information (OS, app version), and — if you enable '
              'notifications — a device token for push messages.',
        ),
        _ConsentPoint(
          icon: Icons.escalator_warning_outlined,
          title: 'Profiles for Children',
          body: 'Profiles for children are created and managed exclusively by '
              'the parent or guardian who owns the account. The child\'s data '
              '(e.g. name, date of birth, training progress) belongs to your '
              'account and is protected like your own data.',
        ),
        _ConsentPoint(
          icon: Icons.near_me_outlined,
          title: 'Location & Map',
          body: 'Your location is used only at your request for the trainer '
              'search and is never stored. When the map is shown, map tiles are '
              'loaded from servers of the OpenStreetMap Foundation, which '
              'technically receives your IP address and the displayed map area.',
        ),
        _ConsentPoint(
          icon: Icons.task_alt_outlined,
          title: 'Purpose of Processing',
          body: 'Providing app features, storing and syncing your training '
              'progress, delivering notifications and reminders, and sending '
              'account emails (e.g. sign-up confirmation, password reset).',
        ),
        _ConsentPoint(
          icon: Icons.cloud_outlined,
          title: 'Data Processing & Storage',
          body: 'Your data is stored encrypted on Supabase servers (EU region). '
              'Locally on your device, data is held for offline functionality in '
              'an app-private database that only this app can read, is protected '
              'by your operating system\'s device encryption, and is excluded '
              'from device backups.',
        ),
        _ConsentPoint(
          icon: Icons.share_outlined,
          title: 'Processors & Recipients',
          body: 'Your data is never sold. It is transmitted only to technical '
              'service providers under data processing agreements (Art. 28 GDPR): '
              'Supabase (database and authentication, EU region), Google Firebase '
              'Cloud Messaging (push delivery), Resend (system emails), and '
              'Sentry (anonymised crash reports: error type, technical trace, '
              'device model — no content, EU data residency). When the '
              'trainer-search map is displayed, the OpenStreetMap Foundation '
              'is an external recipient (IP address, map area).',
        ),
        _ConsentPoint(
          icon: Icons.notifications_none_outlined,
          title: 'Push Notifications',
          body: 'Reminders can be scheduled locally on your device. For messages '
              '(e.g. from your trainer), a device token is processed via Google '
              'Firebase Cloud Messaging. You can disable notifications in your '
              'system settings at any time.',
        ),
        _ConsentPoint(
          icon: Icons.timer_outlined,
          title: 'Retention Period',
          body: 'Your data is stored until you delete your account. You can '
              'delete your account and data at any time directly in the app; '
              'retention details for individual data types are set out in the '
              'Privacy Policy.',
        ),
        _ConsentPoint(
          icon: Icons.verified_user_outlined,
          title: 'Your Rights (GDPR)',
          body: 'You have the right to: access (Art. 15), rectification (Art. 16), '
              'erasure (Art. 17), restriction of processing (Art. 18), '
              'data portability (Art. 20), and objection (Art. 21). '
              'To exercise your rights, contact us via the app.',
        ),
      ],
      closing:
          'You can find the full Privacy Policy at any time at '
          'reflexjourney.app/datenschutz.',
    );
  }
}

// ── Shared layout widgets ─────────────────────────────────────────────────────

class _ConsentContent extends StatelessWidget {
  final String title;
  final String intro;
  final List<_ConsentPoint> points;
  final String closing;

  const _ConsentContent({
    required this.title,
    required this.intro,
    required this.points,
    required this.closing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Text(
          intro,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        ...points.map((p) => _PointCard(point: p)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            closing,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ConsentPoint {
  final IconData icon;
  final String title;
  final String body;
  const _ConsentPoint({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _PointCard extends StatelessWidget {
  final _ConsentPoint point;
  const _PointCard({required this.point});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(point.icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  point.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
