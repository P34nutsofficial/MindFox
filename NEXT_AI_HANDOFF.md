# MindFox – Übergabe an die nächste KI

Stand: 2026-10-26, Play-Uploadversion 1.0, Android-Versioncode 1.

## Produkt

MindFox ist ein natives deutsches Android-Partyspiel für 2–8 Handys im selben WLAN oder Host-Hotspot. Ein Handy hostet den eingebetteten LAN-Dienst, weitere Handys treten über die native WebSocket-Verbindung bei. Der aktive Produktfluss ist ausschließlich Handy-Only; TV-Stage, TV-Routen und der separate Node-Server sind nicht mehr Bestandteil des Produkts.

Der Spielfluss ist: Lobby → Ready-Gate → falsche Antwort → Abstimmung → Reveal → Scoreboard → Ready-Gate → nächste Runde; am Ende folgen Podium und Rematch. Die bestehende Punktewertung, Showrunner-Direktiven, Geheimaufgaben, Schätzrunden und Avatar-UI bleiben erhalten.

## Technischer Stand

`project.godot` meldet Version 1.0 und Build 1. Die Android-Presets verwenden Versioncode 1 und Version 1.0, Paket-ID `com.p34nutsofficial.mindfox`, Hochformat und Netzwerkberechtigungen. Der Host liegt in `scripts/main.gd`, der eingebettete Dienst in `scripts/embedded_lan_server.gd`, der native Client in `scripts/native_player_client.gd`.

Reconnects verwenden Spieler-ID und Session-Token. Ein kurzzeitiger Disconnect pausiert einen Spieler 45 Sekunden; Bluff, Vote, Rolle, Avatar und Punktestand bleiben erhalten. Discovery-Einträge verfallen nach 4,5 Sekunden. App-Resume löst höchstens eine kontrollierte Wiederverbindung über die gespeicherten letzten Verbindungsdaten aus.

Der optionale Browser-Controller in `web/client/` ist unabhängig von TV-Funktionen und verwendet `audio.js`; native Spielerkommunikation bleibt der primäre Pfad.

## Monetarisierung

`addons/GodotGooglePlayBilling/` bindet Play Billing 3.3 ein. `data/topics.json` definiert drei Themen: „Bizarres Halbwissen & Kuriose Gesetze“ ist gratis; „Verrückte Tierwelt & Natur“ und „Absurde Geschichte & Erfindungen“ sind nicht-verbrauchbare Produkte `mindfox_topic_animals_099` und `mindfox_topic_history_099` (je 0,99 €). „Geben Alles“ mischt ausschließlich freigeschaltete Themen. Käufe werden wiederhergestellt; AdMob wird außerhalb Android nicht initialisiert.

## Daten

`data/questions.json` enthält 1100 Fragen: 800 Wissensfragen und 300 Schätzfragen. Jede Frage hat acht eindeutige `fallbackDecoys`, Pflichtfelder und ein `reveal`-Feld; Schätzfragen haben Wert und Einheit. Die 400 neu importierten Wissensfragen wurden mit eindeutigen Projekt-IDs ergänzt. `data/challenge_tasks.json` enthält die 300 neuen Geheimmissionen.

## Prüfpfad

Der zentrale Prüfpfad ist `tools/verify.sh`. Er prüft Projektidentität, Version, Android-Metadaten, Ressourcen-Audit, Godot-Import, deterministische Regeln, Browser-Audio, Handy-Only-Mehrgerätefluss und den nativen vollständigen Runden-Smoke-Test. `tools/verify_exported_pack.gd` prüft Bluff-&-Trivia-Ressourcen und Daten und enthält keine Pong-/Multiplayer-Paddle-Assertions.

Nach Änderungen ausführen:

```bash
cd /home/ubuntu/MindFox-upload/MindFox
./tools/verify.sh
```

Ein APK oder Testergebnis darf nur dokumentiert werden, wenn es in dieser Umgebung tatsächlich gebaut bzw. ausgeführt wurde.
