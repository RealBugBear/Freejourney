import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

/// OSM-Tile-Usage-Policy verlangt sichtbare Attribution mit Link auf
/// openstreetmap.org/copyright — auf jeder Karte, die OSM-Kacheln lädt (T13).
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    // SimpleAttributionWidget stellt selbst "© " voran.
    return SimpleAttributionWidget(
      source: const Text('OpenStreetMap contributors'),
      onTap: () => launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
        mode: LaunchMode.externalApplication,
      ),
    );
  }
}
