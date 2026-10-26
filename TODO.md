# MindFox – Ausbauphase

## Bereits geliefert

- [x] Drei Runden mit sichtbarer Dramaturgie: Spotlight, Bluff, Verdacht, Reveal und Zwischenstand.
- [x] Geheime Nebenrolle pro Spieler und Runde, ohne die Basisregeln zu brechen.
- [x] Confidence-Regler vor dem Voting und sichtbare Auswertung im persönlichen Reveal.
- [x] Bluff-DNA-Auszeichnungen nach jeder Runde und ein charakterstarkes Finale.
- [x] Kettenbluff-Modus als optionaler besonderer Spielmodus.
- [x] QR-LAN, Raumcode, Reconnect-Hinweis, Timeout, automatische Decoy-Antwort und Reduced-Motion-Fallback.

## Nächster großer Meilenstein: Showrunner-System

- [x] Eine gemeinsame, datengetriebene Showrunner-Konfiguration steuert Titel, Kategorie, Dramaturgie, Countdown, Spezialregel, Microcopy, Reveal-Cue und Punkte-Modifikator pro Runde. Host und Handys erhalten daraus denselben `SHOW_DIRECTIVE`-Inhalt.
- [x] Drei kuratierte Spezialrunden sind im Showrunner-Mix spielbar: **Kettenbluff**, **Doppelte Wahrheit** und **Heiße Spur**; zusätzlich bleibt die klassische Runde verfügbar. Jede Spezialrunde hat einen sichtbaren deutschen Hinweis und eine sichere Timeout-Regel.
- [x] Der Showrunner verteilt pro Runde eine kurze geheime Aufgabe an jeden Spieler, ohne Wahrheit, eigene Antwort oder eigene Stimme an andere Spieler zu verraten. Aufgaben bleiben auf Bonuspunkte oder Auszeichnungen begrenzt.
- [x] Der Showrunner erzeugt vor Input, Voting und Reveal sichtbare Cue-Pakete mit Phase-Label, Ansage, Spezialregel und statischem UI-Fallback.
- [x] Die native Handy-Ansicht zeigt Spezialrunden und Cues als große Live-Show-Momente und behält große Touch-Ziele.
- [x] Der Host kann in der Lobby zwischen klassischer Grundshow und Showrunner-Mix wechseln; die Auswahl wird beim Start der Runde festgelegt.
- [x] Der Showrunner bleibt vollständig offline-fähig: keine Live-KI, keine Konten, keine Cloud-Abhängigkeit und der lokale Fragenbestand mit Fallback-Decoys bleibt erhalten.

## Verbindung und Wiederaufnahme

- [x] Der eingebettete Dienst stellt optional den Browser-Controller bereit und synchronisiert native Handys über WebSocket auf Port 8081.
- [x] Das Protokoll unterstützt Capability-Felder für lokale und spätere native/Remote-Transporte.
- [ ] Reconnect erhält Spielername, Raum und laufende Phase sicher; bei abgelaufener Phase erklärt der Controller den nächsten gültigen Schritt.
- [x] Der Embedded-LAN-Smoke-Test deckt Discovery, WebSocket-Handshake, Join, Bluff, Voting und Reveal ab.

## Neuer Sprint: Autonomous Showrunner, Ready-Gates & Audio

- [x] Die native Host-/Handy-Ansicht führt Lobby, Input, Voting, Reveal und Scoreboard ohne externe Anzeige zeitgesteuert aus; Übergänge warten zusätzlich auf das Ready-Gate.
- [x] Die Handy-Ansicht zeigt Countdown, Antwortfortschritt, Moderator-Cues und Reveal-Schritte ohne externe Anzeige.
- [x] Native Android-Hostansicht zeigt während aktiver Runden nur die Player-1-Ansicht: eigene Eingabe, eigenes Voting und persönliches Ergebnis; Wahrheit und fremde Live-Antworten bleiben verborgen.
- [x] Lobby- und Rundenübergang besitzen einen echten „Alle auf GO!“-Gate; der Embedded-LAN-Server broadcastet GATE_UPDATE und schaltet beim letzten GO sofort weiter.
- [x] Host-Player bleibt intern Player 1; der Host besitzt einen diskreten Verwaltungsdrawer für Überspringen/Beenden und IP-Hinweis.
- [x] Der optionale Browser-Controller besitzt Web-Audio-Synthese, Nutzeraktivierungs-Overlay, Klick-/Ready-/Tick-/Buzzer-/Truth-/Punkte-Cues sowie Controller-Vibration.
- [x] Die gemeldete ungenutzte Template-Schrift pong_caption.tres wurde entfernt und die Altkomponente auf ui_regular umgestellt.
- [x] Debug-APK neu gebaut, signiert und mit nativen Ready-Gate-, Source-, JavaScript- und LAN-Tests validiert.

## Final Polish: mDNS, Tournament-Podium & Rematch

- [x] Der eingebettete Dienst leitet die optionale Browser-Controller-Route ausschließlich nach `/client`; der native Handy-Flow bleibt der Primärpfad.
- [x] Der Embedded-LAN-Responder beantwortet lokale `bluff.local`-A-Queries, ohne externe Cloud-Abhängigkeit.
- [x] Drei-Runden-Turnier mit normaler Punktewertung in Runde 1/2 und doppelter Wahrheit-/Bluff-Wertung im großen Finale von Runde 3.
- [x] Champion-Podium mit 1.–3. Platz, Konfetti, größtem Lügner, Meisterdetektiv und leichtgläubigstem Opfer.
- [x] Synchronisiertes „NOCHMAL SPIELEN“-Gate setzt Punkte und Runde zurück, behält Raumcode und Verbindungen bei.
- [x] Deterministischer Smoke-Test deckt Lobby-GO, Runde 1, Runde 2, Finale, Podium und Rematch bis zur Lobby ab.

## Inhalt und Qualität

- [x] Fragen besitzen kuratierte Wahrheit, Fallback-Decoys, Kategorie, Schwierigkeitsgrad und Reveal-Erklärung.
- [x] Humor bleibt deutsch, überraschend und familien-/party-tauglich, ohne Live-KI-Abhängigkeit.
- [ ] Ein echter Mehrgeräte-Wohnzimmer-Test prüft Host und mindestens zwei reale Handys nach dem Showrunner-Meilenstein.

## Delivery

- [x] Godot Source-Checks, nativer Buttonfluss und APK-Pack/Signaturchecks erfolgreich.
- [ ] Preview visuell auf Host und Controller abgenommen.
- [ ] Neuer verwalteter Checkpoint gespeichert, gepusht und zurückgelesen.

## Release Candidate v1.0.0-rc – Massive Content Expansion, Discovery & Juicy FX

- [x] UDP-Broadcast-Auto-Discovery auf Port 41234 sendet alle 1,5 Sekunden Raumcode, Hostname, Spielerzahl, WebSocket-Port, Kategorie und Host-IP; Join zeigt gefundene Spiele als animierte One-Tap-Liste und behält „Manuell eingeben“ als Fallback.
- [x] Der lokale Fragenkatalog enthält 1.100 deutsche Fragen: 270 zu „Bizarres Halbwissen & Kuriose Gesetze“, 269 zur „Verrückten Tierwelt & Natur“, 261 zu „Absurder Geschichte & Erfindungen“ und 300 Schätzfragen. „Geben Alles“ mischt nur Themen, die kostenlos verfügbar oder gekauft sind.
- [x] Host kann die aktive Kategorie in der Lobby wählen; Kategorie-Badge wird in Fragekarte und nativer Clientansicht angezeigt.
- [x] Join-Avatar-Creator bietet fünf prozedurale/vectorartige Figuren, fünf Farbtints und vier Ausdrücke; Profil wird im nativen Connect-Protokoll und in der Host-Lobby geführt.
- [x] Correct-Reveal-/Bluff-/Podium-Juice nutzt vorhandene prozedurale Partikel, Comic-Reactions, Audio-Harmonik und differenzierte Haptikmuster; Countdown besitzt einen optionalen prozeduralen Spannungspuls in den letzten zehn Sekunden.
- [x] Optionaler KI-Gastspieler-Schalter ist in der Lobby sichtbar und ergänzt bei zwei echten Spielern einen Bot.
- [x] Idle-Screens laufen mit 30 FPS, aktive Runden mit 60 FPS; Headless-/Reduced-Motion-Fallback bleibt erhalten.
- [x] Erweiterter Headless-Mehrgerätetest deckt Discovery-Vertrag, Avatarfelder, Kategorieauswahl, drei Runden, Podium und Rematch-Loop ab; Katalog- und Parse-Checks sind erfolgreich.
- [x] Screenshot-basiertes Mobile-Polish: Portrait-Letterbox reduziert, Cards erzwingen volle Breite, Antwortfelder sind native vollbreite LineEdits, Score-/Podium-Zeilen haben stabile Spalten, Kategoriebuttons stacken portraitfreundlich.
- [x] Fragenreihenfolge wird pro Match neu gemischt und im Headless-Test auf drei unterschiedliche IDs geprüft; Bot-Antworten verwenden wechselnde Decoys und Persona-Flair statt statischer Wiederholung.
- [x] Globaler Portrait-Layoutfix: Root-/Body-Container expandieren vollbreit, Labels haben Word-Wrapping und Mindestbreite, ScrollContainer folgt dem Fokus und sorgt das Antwortfeld sichtbar nach, LineEdit begrenzt Eingaben auf 75 Zeichen.
- [x] Spielumfang auf 8 Runden erweitert; Runde 3 und 6 sind 18-Sekunden-Schätzrunden mit numerischer Eingabe und Abstandswertung.
- [x] Bei Punktegleichstand nach Runde 8 startet der Host eine zusätzliche Schätzrunde ausschließlich für die zwei Erstplatzierten.
- [x] Scoreboard bietet dem Host „SOFORT WEITER“; der Host kann die Ready-Gate-Wartezeit zwischen Runden überspringen.
- [x] Bot-Antworten bestehen wieder ausschließlich aus der eigentlichen Antwort ohne verräterische Kommentarzusätze.
- [x] Zahlenpflicht auf echte Schätzrunden begrenzt; normale Bluffantworten dürfen wieder frei formuliert werden.
- [x] Reveal zeigt nach jeder Runde alle Spielerantworten, die ausgewählte Antwort pro Spieler und direkt darunter eine sortierte Rundentabelle.
- [x] Reveal zeigt die korrekte Antwort ganz oben; danach folgen Antworten, ausgewählte Antworten und die Rangliste. Der Wechsel wartet auf den Ready-Klick aller Spieler und läuft anschließend mit einem piepsenden 3-Sekunden-Countdown.
- [x] Schätz-Reveal zeigt alle abgegebenen Schätzwerte, den Punktegewinner mit „SCHÄTZKÖNIG“ und die Tabelle nach Abstand zum Richtwert.
- [x] Host kann direkt aus der Reveal-Phase zur nächsten Runde bzw. nach der letzten Runde zum Scoreboard weiterklicken.
- [x] Lobby-Scrollhöhe wird aus dem tatsächlichen Inhalt berechnet, sodass alle 8 Spieler auf kleinen Portraitdisplays erreichbar bleiben.

## Native Handy-Show – neuer Umsetzungsplan

## UX- und Stabilitätssprint – 22.10.2026

- [x] Ready-Gate strikt machen: keine automatische Freigabe nach Wartezeit; nur nach allen Ready-Klicks oder explizit bestätigtem Host-Override weitergehen.
- [x] Reconnect sicher machen: persistente Spieler-ID und Wiederaufnahme von Name, Avatar, Runde, Score, Submit-/Vote-Status und Gate-Zustand.
- [x] Join neu ordnen: Name und Avatar vor Discovery auswählen; gefundene Räume verbinden mit dem gewählten Profil, manuelle IP-/Code-Eingabe bleibt Fallback.
- [x] Laufenden Fortschritt anzeigen: Host sieht während Antwort und Voting Anzahl sowie Namen von fertigen und noch wartenden Spielern; Disconnect/Timeout wird sichtbar markiert.
- [x] Basistests an den aktuellen Produktvertrag anpassen und grün halten; Timeout, Phantomantworten, Sichtbarkeit und Gate-Regel zusätzlich absichern.
- [x] Mobile Avatar-Assets auf passende Laufzeitgröße und Kompression reduzieren, ohne sichtbaren Qualitätsverlust.
- [x] Zentrale Spiellogik schrittweise aus `scripts/main.gd` in klar benannte Module auslagern, ohne den nativen Ablauf zu verändern.

- [x] Block 1: Native Startseite mit „Spiel hosten“ und „Spiel beitreten“ im Hochformat; Browser- und TV-Adressen dürfen im Bedienfluss nicht mehr erscheinen.
- [x] Block 1: Host startet den lokalen LAN-Dienst und zeigt Host-IP plus Raumcode; Mitspieler verbinden sich nativ per WebSocket über dieselbe Android-App.
- [x] Block 1: Native Verbindung, Fehler, Wartezustand und Touch-Feedback sind jederzeit verständlich sichtbar.
- [x] Block 2: Native Lobby mit Spielerliste, Host-Badge, Ready-Gate und hochwertigem Partyspiel-Layout.
- [x] Block 3: Native Frage-, Antwort-, Voting- und Antwortbestätigungs-Views mit sicherem Rundenwechsel.
- [x] Block 4: Native Reveal-, Punkte-, Award- und Finale-Dramaturgie.
- [x] Block 5: Native Mehrgeräte-Regressionslauf über drei Runden, Export, APK-Pack/Signatur/Alignment, ZIP-Integrität und Release-Check.

## AAA Visual Overhaul – native Qualitätsziele

- [x] Transparente 3D-SubViewport-Stage mit emissiven Frageblöcken, geglättetem Accelerometer/Gyro-Parallax und Ambient-Fallback hinter dem Hochformat-UI.
- [x] Leichtgewichtige Glass-, Neon- und Holographic-Foil-Shader auf aktiven Karten, Countdown und Champion-Reveal.
- [x] Juicy Touch-Feedback mit Spring-Press, Countdown-Tick/Haptik unter fünf Sekunden, Truth-Burst und Bluff-Schadensfreude-Reveal.
- [x] Emoji-Reaction-Cannon mit validierter Whitelist, maximal drei Events pro Sekunde und nativer Mehrgeräte-Synchronisation.
- [x] Native Synth-Cues für Click, Whoosh, Buzzer, Score und Fanfare sowie gerätesicheres Haptic-Mapping.
- [x] Native Performance-/Regression-Check für Sensor-Fallback, drei Runden, Emojis, Reveal, Podium, Export und APK-Integrität.
