# MindFox – aktueller Übergabestatus

Stand: 2026-10-24

## Produktfluss

MindFox ist auf einen lokalen Handy-Only-Flow ausgerichtet. Ein Android-Gerät hostet die Runde, alle weiteren Geräte treten über den nativen WebSocket-Client bei. Lobby, Ready-Gate, Antwort, Voting, Reveal, Scoreboard, Podium und Rematch bleiben erhalten.

Die frühere TV-Stage, der TV-Browser, TV-Assets und der separate Node-WebSocket-Fallback sind aus dem aktiven Projekt entfernt. `web/client/` ist nur noch ein optionaler Browser-Controller ohne TV-Abhängigkeit.

## Relevante Komponenten

- `scripts/main.gd`: Host-State-Machine, Lobby, Regeln, Scoring und native Client-Ereignisse.
- `scripts/embedded_lan_server.gd`: eingebetteter HTTP-/WebSocket-/Discovery-Dienst für Host und native Controller.
- `scripts/native_player_client.gd`: nativer Mitspieler-Client mit Heartbeat, Discovery-TTL, Profilpersistenz und Resume-Reconnect.
- `web/client/`: optionaler Browser-Controller mit eigener Audiohilfe `audio.js`.
- `data/questions.json`: 1100 valide Fragen (800 Wissen, 300 Schätzung) ohne doppelte IDs.
- `data/challenge_tasks.json`: Geheimaufgabenbestand.

## Netzwerk und Reconnect

- Der Host broadcastet ausschließlich an authentifizierte native Spieler.
- Ein Disconnect pausiert den Spieler 45 Sekunden; Liege, Vote, Punktestand und Rolle bleiben erhalten.
- Ein Reconnect verwendet persistierte Spieler-ID und Session-Token und erhält den aktuellen Phasen-Snapshot.
- Bei App-Resume versucht der native Client nur mit vorhandenen letzten Verbindungsdaten eine kontrollierte Wiederverbindung.
- Discovery-Beacons verfallen nach 4,5 Sekunden und werden aus der Lobby entfernt.
- Ready-Gates blockieren nicht durch einen pausierten Spieler.

## Prüfungen

- Godot-Dateiimport/Parserlauf ohne Projekt-Parsefehler.
- `node --check web/client/app.js` erfolgreich.
- `node --check web/client/audio.js` erfolgreich.
- JSON-Validierung erfolgreich: 1100 Fragen, keine doppelten IDs, Pflichtfelder vorhanden; zusätzlich 300 neue Geheimmissionen.

Hinweis: Ein separater Node-Server-Test ist nach Entfernung des Legacy-Web-/TV-Fallbacks nicht mehr Bestandteil des Projekts.
