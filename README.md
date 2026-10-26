# MindFox – Die Lügenrunde



Lokale Android-Partyshow für 2–8 Spieler im selben WLAN. Die App enthält AdMob-Banner und Interstitial-Werbung, automatische Sprach-/Inhaltsauswahl mit Englisch als Fallback und keine Kamerafunktion.



## Android-Build

Das Godot-Android-Exporttemplate wird aus Platz- und GitHub-Kompatibilitätsgründen nicht mit versioniert. In Godot 4.7.2 einmalig **Editor → Manage Export Templates → Download and Install** ausführen oder das Android-Gradle-Template im Projekt installieren. Danach kann das Android-Preset aus `export_presets.cfg` exportiert werden.

Die App ist für ARM64-Android exportiert. Die AdMob-Kernbibliotheken liegen unter `addons/admob/android/bin/ads`; optionale Mediation-Adapter wurden bewusst entfernt.

