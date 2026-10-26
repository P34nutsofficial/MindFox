# MindFox – Die Lügenrunde

Lokales Android-Partyspiel für 2–8 Spieler im selben WLAN. Die App nutzt AdMob-Banner und Interstitial-Werbung, automatische Sprach-/Inhaltsauswahl mit Englisch als Fallback und keine Kamerafunktion.

## Google Play

- Paket-ID: `com.p34nutsofficial.mindfox` (nach dem ersten Play-Upload nicht mehr änderbar).
- „Bizarres Halbwissen & Kuriose Gesetze“ ist gratis.
- „Verrückte Tierwelt & Natur“ und „Absurde Geschichte & Erfindungen“ sind nicht-verbrauchbare In-App-Käufe für je 0,99 €.
- Die Produkt-IDs stehen in `data/topics.json`: `mindfox_topic_animals_099` und `mindfox_topic_history_099`.
- „Geben Alles“ mischt nur gratis verfügbare oder gekaufte Themen. Google-Play-Käufe werden wiederhergestellt.
- Billing-Integration: `addons/GodotGooglePlayBilling/` (GodotGooglePlayBilling 3.3).

## Android-Build

Das Godot-Android-Exporttemplate wird aus Platz- und GitHub-Kompatibilitätsgründen nicht mit versioniert. In Godot 4.7.2 einmalig **Editor → Manage Export Templates → Download and Install** ausführen; danach kann das Android-Preset aus `export_presets.cfg` verwendet werden. Das Play-Preset heißt `Android AAB`, verwendet ARM64, Target SDK 36 und Versioncode 1.

Ein Release-AAB muss mit dem privaten Google-Play-Upload-Key signiert werden. Den Keystore und sein Passwort sicher sichern, niemals in dieses Repository committen und den Versioncode für jedes weitere Play-Update erhöhen. AdMob-Kernbibliotheken liegen unter `addons/admob/android/bin/ads`; optionale Mediation-Adapter wurden bewusst entfernt.
