# MindFox – Größenoptimierung

Stand: 2026-10-25

## Ergebnis

Die Laufzeitdaten wurden nicht verändert. Fragen, Geheimmissionen, aktive UI-Assets, Avatare, Fonts, Netzwerkcode und WebSocket-Fallback bleiben vollständig erhalten.

Die Android-/AAB-/Web-Exports schließen nun nachweislich nicht benötigte Dateien aus:

- generierte Exportordner und Testausgaben
- `site/`
- `reference_screens/`
- historische Designkonzepte und Referenzdateien
- alte Intro-Renderings
- alte `mindfuck*`-Wortmarken
- nicht verwendete `assets/mindfox_party/visuals/`
- nicht verwendete `assets/mindfox_party/motion/`
- Entwicklungswerkzeuge und Provenance-Dateien

Diese Dateien bleiben im vollständigen Quellprojekt erhalten, werden aber nicht in die App gepackt. Dadurch wird kein benötigtes Laufzeit-Asset gelöscht.

## Nicht gelöscht

`.godot/` und `dist/` sind generierte lokale Artefakte und werden nicht in das vollständige ZIP aufgenommen. Die Quelldateien und Dokumentation bleiben enthalten.

## APK-Status

Die aktuelle Test-APK wurde mit dem Preset `Android Test` erfolgreich exportiert. Sie ist 67 MB groß und wurde mit APK Signature Scheme v2/v3 verifiziert. Die aktuelle Datei heißt `MindFox-v1.4.0-scroll-fix-test.apk`. Der SHA-256-Hash lautet:

`8b387823ea61d7f41baf624ab1d6443f94b97bca5e30ce1871c552515e59ece1`

Die APK enthält die aktuellen Fragen, Geheimmissionen, den Lobby-Schalter, den kontinuierlichen Scroll-Fix, den einzelnen Bot-Hinzufügen-Button und die optimierten Exportfilter.
