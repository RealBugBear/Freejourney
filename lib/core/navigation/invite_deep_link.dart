/// Parsed invite deep link (`/einladung` or `/en/einladung`, optional `?c=`).
class InviteDeepLink {
  const InviteDeepLink({this.code});

  /// Raw query value; may be null/empty when the link has no `c`.
  final String? code;
}

/// Top-level so URL-shape matching can be unit-tested without Flutter bindings.
///
/// Matches:
/// - `https://reflexjourney.app/einladung?c=…`
/// - `https://reflexjourney.app/en/einladung?c=…`
/// - custom scheme `reflexjourney://einladung?c=…`
///
/// HTTPS links must use host `reflexjourney.app`. Other domains with the same
/// path are ignored.
InviteDeepLink? parseInviteDeepLink(Uri uri) {
  final path = uri.path;

  final httpsInvite = uri.scheme == 'https' &&
      uri.host == 'reflexjourney.app' &&
      (path == '/einladung' ||
          path == '/en/einladung' ||
          path.startsWith('/einladung/') ||
          path.startsWith('/en/einladung/'));

  final customSchemeInvite = uri.scheme == 'reflexjourney' &&
      (uri.host == 'einladung' ||
          path == '/einladung' ||
          path == 'einladung' ||
          path.endsWith('/einladung'));

  if (!httpsInvite && !customSchemeInvite) return null;

  final raw = uri.queryParameters['c'];
  return InviteDeepLink(code: raw);
}
