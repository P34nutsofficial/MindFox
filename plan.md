# MindFox – Native Handy-Show

## Produktziel

MindFox wird zu einem reinen Handy-Partyspiel: Jede Person installiert dieselbe Android-App. Eine Person hostet das Spiel im lokalen WLAN, alle anderen treten über Host-IP und Raumcode bei. Browser, TV-Ansicht, URL-Eingabe und externe Web-Audio-Abhängigkeiten gehören nicht mehr zum Spielablauf.

## Designrichtung

**Design Movement:** Neon Game Show / Premium Party UI. Die App kombiniert dunkle Studioflächen, eine eigene Cyan-Gold-Violett-Palette, starke Showrunner-Microcopy und großzügige Touch-Ziele.

**Kernprinzipien:** Eine dominante Aktion je Screen; große lesbare Karten; jede Spielphase hat eine eigene emotionale Farbe; Feedback wird als Show-Moment und nicht als technische Fehlermeldung erzählt.

**Farbphilosophie:** Tiefes Nachtblau bildet die Bühne. Cyan signalisiert Verbindung und Fokus, Gold signalisiert Aktion und Punkte, Grün signalisiert Wahrheit und Erfolg, Violett signalisiert Rollen und Überraschung, Rot signalisiert Aufmerksamkeit ohne Alarmismus.

**Layout:** Hochformat, vertikale Dramaturgie mit Hero-Bühne oben, kompakter Statuszeile und einer zentralen großen Aktionskarte. Keine dichten Tabellen und keine gleichgewichteten Button-Reihen.

**Signatur-Elemente:** Showrunner-Cue-Karten, leuchtende Timer-Ringe und „versiegelt“-artige Antwortaktionen. Maskottchen und Badge werden als wiederkehrende Bühnenrequisiten eingesetzt.

**Interaktion:** Jede Eingabe bestätigt sich sofort visuell. Netzwerkzustände sind immer sichtbar. Wiederholbare Aktionen sind sicher; bei Wartephasen bleibt die nächste sinnvolle Aktion eindeutig.

**Animation:** Kurze, hochwertige Einblendungen, sanfte Glow-Pulse und Kartenbewegungen. Effekte unterstützen Aufmerksamkeit, blockieren aber nie den Touch-Flow. Reduced-Motion wird respektiert.

**Typografie:** UI-Regular für erklärende Texte, UI-Bold für Headlines, Punkte, Raumcode und CTAs. Headlines kurz, humorvoll und showartig; Hilfetexte beruhigend und direkt.

**Brand Essence:** Eine lokale deutsche Bluff-Spielshow für Freundeskreise, die Wissen, Täuschung und spontane Lacher in einer gemeinsamen Handy-Runde verbindet. Persönlich, frech, hochwertig.

## Block 1 – Native App-Einstieg

- Die App startet im Hochformat auf einer hochwertigen Startseite.
- Es gibt ausschließlich die Aktionen „Spiel hosten“ und „Spiel beitreten“.
- Host startet den lokalen LAN-Dienst, erzeugt Raumcode und zeigt Host-IP plus Code.
- Mitspieler verbinden sich nativ per WebSocket zur Host-IP und verwenden den Raumcode.
- Browser- und TV-Adressen erscheinen im Bedienfluss nicht mehr.
- Native Verbindungs-, Fehler- und Wartezustände sind sichtbar.

## Block 2 – Native Lobby

- Spielerliste, Host-Badge, Verbindungsstatus, Ready-Gate und Host-Start werden als hochwertige Handy-Lobby umgesetzt.
- Der Host sieht IP und Raumcode; Mitspieler sehen ihren Verbindungsstatus.

## Block 3 – Native Spielrunde

- Frage, Antwort, Countdown, Antwortbestätigung, Voting und Punkte werden vollständig nativ auf dem Handy gespielt.
- Eigene Antwort und fremde Antworten bleiben bis zum Reveal korrekt geschützt.

## Block 4 – Reveal und Finale

- Wahrheit, Bluffkarten, Stimmen, Punkte, Awards und Finale erhalten eine animierte Show-Dramaturgie.

## Block 5 – Qualität und Release

- Drei vollständige native Clients durchlaufen Host, Join, Ready, drei Runden, Punkte und Rematch automatisiert.
- Android-APK wird erst nach Source-, Netzwerk-, Export- und Installationschecks ausgeliefert.

## AAA-Erweiterung – Neon Arcade Show

Die Premium-Schicht baut auf dem bestehenden nativen Flow auf und bleibt creditsparend: prozedurale Godot-Effekte statt großer neuer Asset-Pakete, ein kleiner synthetischer Audio-Footprint und ein sicherer Fallback für Desktop/Headless-Geräte.

**3D-/Parallax-Fundament:** Eine transparente SubViewport-Stage rendert schwebende, emissive Frageblöcke hinter dem Hochformat-UI. Accelerometer/Gyro wird geglättet; bei fehlenden Sensoren übernimmt ein langsamer Ambient-Drift. Die FX-Schicht ignoriert Pointer und darf die Touch-Ziele nicht blockieren.

**Shader-System:** `glass_panel.gdshader` veredelt Karten mit Rim-Light und Soft-Glow, `neon_pulse.gdshader` betont aktive CTAs/Countdowns, `foil_holographic.gdshader` markiert Reveal-Wahrheit und Championkarte. Shader bleiben leichtgewichtig und werden nur auf große bzw. aktive Flächen gesetzt.

**Juice:** Buttons reagieren mit kurzer Back-/Elastic-Feder, Antwortversiegelung und Truth-Reveal erzeugen Burst-Partikel, Countdown unter fünf Sekunden erhöht Tick/Haptik, und der finale Podiumsmoment erhält einen gestaffelten Spotlight-/Scale-In.

**Live-Social:** Ein kleiner Emoji-Reaktionsriegel sendet maximal drei `EMOJI_PING`-Events pro Sekunde an den Host. Der Host verteilt nur validierte Whitelist-Emojis; jeder Client rendert die Reaktion lokal als kurze, nicht-blockierende Flugbahn.

**Audio/Haptik:** Ein nativer `AudioStreamGenerator` erzeugt kurze UI-, Tick-, Whoosh-, Buzzer-, Reward- und Fanfare-Cues ohne schwere Audiodateien. Alle Cues sind headless-sicher und Haptik wird nur auf echten Geräten ausgelöst.

## Release Candidate v1.0.0-rc

Der Release Candidate entfernt den letzten Setup-Bruch im lokalen Spiel: Der Host sendet über UDP-Port 41234 leichte JSON-Beacons, der Join-Client lauscht nur während des Join-Screens und bietet gefundene Räume als One-Tap-Karten an. IP und Raumcode bleiben als manuelle Fallback-Eingabe verfügbar. Das WebSocket-Protokoll übernimmt zusätzlich Avatarindex, Farbtint und Ausdruck.

Der lokale Fragenkatalog ist auf 108 Einträge angewachsen. Die Lobby wählt aus vier festen deutschen Kategorien; der Host filtert den Pool deterministisch pro Runde, während Kategorie und Schwierigkeit als Badge bis in die native Fragekarte synchronisiert werden. Avatare bleiben prozedural und asset-sparend: fünf Symbolkörper, fünf Tints und vier Ausdrücke werden als Datenprofil übertragen und als Lobby-Badge gerendert.

Die Release-Candidate-Polish-Schicht ergänzt eine subtile Spannungsklangfolge in den letzten zehn Sekunden, mehrstimmige Synth-Cues, Double-Pulse beim Absenden, Shudder bei erfolgreichem Bluff und eine Triumphfolge auf dem Podium. Das Laufzeitprofil begrenzt statische Screens auf 30 FPS und aktiviert 60 FPS während Runden und Animationen. Ein sichtbarer KI-Gastspieler-Schalter ergänzt bei zwei echten Spielern optional einen Bot.
