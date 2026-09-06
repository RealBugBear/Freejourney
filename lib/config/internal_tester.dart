/// Who may access Dev Tools and other internal-only UI during beta.
///
/// Default: `@reflexjourney.de` team accounts. Add founder/beta emails to
/// [kInternalTesterBetaAllowlist] until TestFlight internal testing is set up.
bool isInternalTesterEmail(String email) {
  final normalized = email.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  if (normalized.endsWith('@reflexjourney.de')) return true;
  return kInternalTesterBetaAllowlist.contains(normalized);
}

/// Closed-beta founder/test emails — compile-time allowlist only.
const Set<String> kInternalTesterBetaAllowlist = {
  'vowef83133@neowd.com',
};
