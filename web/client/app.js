(() => {
  'use strict';
  const $ = (id) => document.getElementById(id);
  const views = ['join','wait','gate','input','vote','result'];
  const state = { socket:null, playerId:localStorage.getItem('bluffPlayerId') || '', sessionToken:localStorage.getItem('bluffSessionToken') || '', room:'', name:localStorage.getItem('bluffPlayerName') || '', phase:'LOBBY', questionId:'', gateId:'', options:[], timer:null, heartbeat:null, role:null, round:1, directive:null, gateReady:false, wakeLock:null, revealPayload:null };
  const query = new URLSearchParams(location.search);
  const queryRoom = query.get('room') || '';
  const queryWsPort = query.get('wsPort') || '';
  const wsPort = queryWsPort || (location.port === '8080' ? '8081' : location.port);
  $('room').value = queryRoom.toUpperCase();
  $('name').value = state.name;
  const show = (name) => views.forEach((id) => $(id).classList.toggle('active', id === name));
  const buzz = () => { try { navigator.vibrate?.(40); } catch (_) {} try { window.BluffAudio?.ensure(); window.BluffAudio?.play('click'); } catch (_) {} };
  const audioEnable = $('audioEnable');
  audioEnable?.addEventListener('click', async () => {
    const active = await window.BluffAudio?.ensure();
    audioEnable.classList.toggle('enabled', Boolean(active));
    audioEnable.setAttribute('aria-pressed', String(Boolean(active)));
    audioEnable.textContent = active ? 'Ton aktiv' : 'Ton erneut versuchen';
    if (active) window.BluffAudio.play('join');
  });
  const applyDisplayMode = () => { document.body.classList.add('handy-only'); };
  const keepScreenAwake = async () => { try { if ('wakeLock' in navigator && !state.wakeLock) state.wakeLock = await navigator.wakeLock.request('screen'); } catch (_) {} };
  const send = (type, payload={}) => { if (state.socket?.readyState === WebSocket.OPEN) state.socket.send(JSON.stringify({type, roomId:state.room, senderId:state.playerId, payload})); };
  const wsUrl = () => { const host = `${location.hostname}${wsPort ? `:${wsPort}` : ''}`; return `${location.protocol === 'https:' ? 'wss' : 'ws'}://${host}/ws?room=${encodeURIComponent(state.room)}`; };
  const connect = () => {
    state.room = $('room').value.trim().toUpperCase(); state.name = $('name').value.trim() || state.name || 'Gast';
    localStorage.setItem('bluffPlayerName', state.name);
    if (!/^[A-Z0-9]{4}$/.test(state.room)) { $('joinHint').textContent = 'Bitte gib den vierstelligen Raumcode ein.'; return; }
    buzz(); keepScreenAwake(); show('wait'); $('waitText').textContent = 'Der Showrunner prüft deinen Platz …';
    state.socket = new WebSocket(wsUrl());
    state.socket.addEventListener('open', () => { send('CONNECT_REQ', {playerId:state.playerId,sessionToken:state.sessionToken,playerName:state.name,avatarIndex:0}); clearInterval(state.heartbeat); state.heartbeat=setInterval(() => send('PING', {}), 5000); });
    state.socket.addEventListener('message', (event) => { try { handle(JSON.parse(event.data)); } catch (_) {} });
    state.socket.addEventListener('error', () => { $('waitText').textContent = 'Verbindung fehlgeschlagen. Prüfe WLAN und Host-Adresse.'; show('wait'); });
    state.socket.addEventListener('close', () => { clearInterval(state.heartbeat); state.heartbeat=null; if (state.phase !== 'SCORES') { $('waitText').textContent = 'Verbindung pausiert. Tippe auf „Verbindung prüfen“. '; show('wait'); } });
  };
  const handle = (msg) => {
    const payload = msg.payload || {};
    if (msg.type === 'PONG') return;
    if (msg.type === 'ROOM_STATE') { applyDisplayMode(); return; }
    if (msg.type === 'CONNECT_RESP') { if (payload.status !== 'OK') { $('waitText').textContent = 'Der Host hat die Verbindung abgelehnt. Prüfe den Raumcode und trete erneut bei.'; show('wait'); state.socket?.close(); return; } state.playerId = payload.playerId || state.playerId; state.sessionToken = payload.sessionToken || state.sessionToken; localStorage.setItem('bluffPlayerId', state.playerId); localStorage.setItem('bluffSessionToken', state.sessionToken); applyDisplayMode(); keepScreenAwake(); $('waitText').textContent = 'Du bist dabei. Die nächste Runde startet gleich.'; show('wait'); return; }
    if (msg.type === 'GATE_UPDATE') { state.gateId = payload.gateId || ''; if (payload.gate === 'ROUND' && state.revealPayload) renderRevealGate(payload); else renderGate(payload); return; }
    if (msg.type === 'GATE_COUNTDOWN') { if (payload.seconds > 0) { $('resultTitle').textContent = `Weiter in ${payload.seconds} …`; try { window.BluffAudio?.play('tick'); } catch (_) {} } return; }
    if (msg.type === 'ROLE_BRIEF') { state.round = payload.round || state.round; state.role = payload.role || null; $('roleIcon').textContent = state.role?.icon || '🎭'; $('roleTitle').textContent = state.role?.title || 'Geheime Rolle'; $('roleHint').textContent = state.role?.hint || 'Behalte diese Info für dich.'; return; }
    if (msg.type === 'SHOW_DIRECTIVE') { state.directive = payload; renderDirective(payload); return; }
    if (msg.type === 'PHASE_CHANGE') {
      state.phase = payload.newPhase;
      if (state.phase === 'INPUT') { $('questionText').textContent = payload.prompt || 'Frage wird geladen …'; $('hybridQuestion').textContent = payload.prompt || 'Frage wird geladen …'; $('lie').value=''; $('counter').textContent='0'; $('inputHint').textContent=''; $('submitLie').disabled = false; $('submitLie').textContent = 'Antwort abgeben'; show('input'); startTimer(payload.timeLimitSec || 45); }
      else if (state.phase === 'VOTING') { $('confidence').value = 50; $('confidenceValue').textContent = '50'; renderOptions(payload.options || []); show('vote'); }
      else if (state.phase === 'SCORES') { const rows = (payload.scores || []).map((score, index) => `<div class="reveal-row"><span><b>${index + 1}. ${escapeHtml(score.name)}</b><small>Zwischenstand</small></span><strong>${score.score} Pkt</strong></div>`).join(''); $('resultTitle').textContent = payload.final ? 'Finale' : 'Zwischenstand'; $('resultCard').innerHTML = `<div class="good">${payload.final ? 'Die Lügenrunde ist entschieden.' : 'Die nächste Runde wartet.'}</div><div class="reveal-list">${rows}</div><p class="muted">Der Host startet den nächsten Ready-Check.</p>`; $('resultReady').disabled = true; $('resultReady').textContent = 'Warte auf den Host …'; show('result'); }
      else if (state.phase === 'FINAL_PODIUM') { const rows = (payload.podium || []).map((player) => `<div class="reveal-row"><span>${['🥇','🥈','🥉'][player.rank - 1] || player.rank} ${escapeHtml(player.name)}</span><strong>${player.score} Pkt</strong></div>`).join(''); $('resultTitle').textContent = 'Champion-Podium'; $('resultCard').innerHTML = `<div class="good">Das große Finale ist entschieden.</div><div class="reveal-list">${rows}</div><p>Der größte Lügner: ${escapeHtml(payload.awards?.liar || '—')}</p><p>Der Meisterdetektiv: ${escapeHtml(payload.awards?.detective || '—')}</p>`; show('result'); }
      else if (state.phase === 'LOBBY') show('wait');
      return;
    }
    if (msg.type === 'QUESTION_BROADCAST') { state.questionId = payload.questionId || ''; const prompt = payload.chainHint ? `${payload.prompt}\n\n${payload.chainHint}` : (payload.prompt || ''); $('questionText').textContent = prompt; $('hybridQuestion').textContent = prompt; $('questionMeta').textContent = `${payload.category || 'Kurioses Wissen'} · ${payload.difficulty || 'mittel'}`; return; }
    if (msg.type === 'INPUT_FEEDBACK') { $('inputHint').textContent = payload.accepted ? 'Gespeichert. Pokerface an – die Runde läuft weiter.' : ((payload.reason === 'NEEDS_NUMBER' ? 'Diese Spezialrunde braucht mindestens eine Zahl in deiner Falschantwort.' : 'Diese Antwort ist noch nicht gültig.')); show(payload.accepted ? 'wait' : 'input'); return; }
    if (msg.type === 'SUBMIT_ACK') { if (payload.accepted) { $('waitText').textContent = 'Lüge eingeloggt! Warte auf die anderen …'; show('wait'); } else { $('inputHint').textContent = 'Die Antwort konnte noch nicht gespeichert werden. Bitte erneut versuchen.'; show('input'); } return; }
    if (msg.type === 'VOTE_ACK') { if (payload.accepted) { $('waitText').textContent = 'Tipp eingeloggt! Warte auf die anderen …'; show('wait'); } else { $('waitText').textContent = 'Der Tipp wurde nicht angenommen. Bitte erneut abstimmen.'; show('vote'); } return; }
    if (msg.type === 'VOTE_OPTIONS_LIST') { state.questionId = payload.questionId || state.questionId; renderOptions(payload.options || []); show('vote'); return; }
    if (msg.type === 'ROUND_REVEAL_DATA') {
      state.revealPayload = payload;
      const own = payload.personal || {}; const award = own.fooled > 0 ? 'MEISTERBLUFF' : (own.correct ? 'WAHRHEITSFINDER' : 'CHAOS-ENERGIE');
      if (payload.directive) renderDirective(payload.directive);
      $('resultTitle').textContent = own.correct ? 'Volltreffer!' : (own.fooled > 0 ? 'Du hast sie alle reingelegt.' : 'Das Publikum war anderer Meinung.');
      const rows = (payload.entries || []).slice(0, 8).map((entry) => `<div class="reveal-row"><span><b>${escapeHtml(entry.owner)}</b><small>${escapeHtml(entry.text || '')}</small></span><strong>${entry.votes || 0}</strong></div>`).join('');
      $('resultCard').innerHTML = `<div class="${own.correct ? 'good':'bad'}">${own.correct ? '+500 Punkte für die Wahrheit' : award}</div><p class="truth-answer"><strong>Wahrheit:</strong> ${escapeHtml(payload.truth || '')}</p><p class="muted">${escapeHtml(payload.explanation || '')}</p><div class="reveal-list">${rows}</div><p>${own.fooled || 0} Spieler ließen sich von dir täuschen.</p><p><strong>${own.delta > 0 ? '+' : ''}${own.delta || 0} Punkte · ${own.score || 0} gesamt</strong></p>`;
      $('resultCard').classList.remove('reveal-sequence'); void $('resultCard').offsetWidth; $('resultCard').classList.add('reveal-sequence'); try { window.BluffAudio?.play(own.correct ? 'truth' : 'buzzer'); } catch (_) {}
      $('resultReady').disabled = true;
      $('resultReady').textContent = 'Warte auf den Ready-Check …';
      show('result');
    }
  };
  const renderRevealGate = (gate) => {
    state.gateReady = (gate.ready || []).includes(state.playerId);
    $('resultTitle').textContent = state.gateReady ? 'Bereit – warte auf die anderen' : 'Bereit für die nächste Seite?';
    $('resultReady').disabled = state.gateReady;
    $('resultReady').textContent = state.gateReady ? 'BEREIT · WARTE AUF DIE ANDEREN' : 'BEREIT · WEITER';
    show('result');
    if (state.gateReady) try { window.BluffAudio?.play('ready'); } catch (_) {}
  };
  const renderGate = (gate) => {
    state.gateReady = (gate.ready || []).includes(state.playerId);
    $('gateTitle').textContent = gate.gate === 'LOBBY' ? 'Bereit für die erste Runde?' : (gate.gate === 'REMATCH' ? 'Nochmal spielen?' : 'Alle bereit für die nächste Runde?');
    $('gateText').textContent = `${gate.readyCount || 0}/${gate.total || 0} bereit · Der letzte GO-Klick startet sofort.`;
    $('gatePlayers').innerHTML = (gate.players || []).map(player => `<span class="gate-chip ${player.ready ? 'ready' : ''}">${player.ready ? '✓' : '○'} ${escapeHtml(player.name)}</span>`).join('');
    const button = $('readyGateButton');
    button.disabled = state.gateReady;
    button.textContent = state.gateReady ? 'BEREIT! WARTE AUF DIE TRÖDLER …' : 'ICH BIN BEREIT! · GO!';
    $('gateHint').textContent = gate.skipAvailable ? 'Der Host kann langsame Geräte jetzt im Notfall überspringen.' : 'Dein Button wird nach dem Tippen gesperrt.';
    show('gate');
    if (state.gateReady) window.BluffAudio?.play('ready');
  };
  const renderDirective = (directive) => {
    const title = directive.title || 'Showrunner';
    if ($('showCueTitle')) $('showCueTitle').textContent = `SHOWRUNNER · ${title}`;
    if ($('showCueText')) $('showCueText').textContent = directive.cue || 'Die Show läuft.';
    if ($('showCueHint')) $('showCueHint').textContent = directive.inputHint || '';
    if ($('voteCueText')) $('voteCueText').textContent = directive.votingHint || directive.cue || '';
    if ($('resultCueText')) $('resultCueText').textContent = directive.revealCue || directive.cue || '';
    if ($('hybridComment')) $('hybridComment').textContent = directive.cue || 'Der Showrunner beobachtet jede Silbe.';
  };
  const renderOptions = (options) => { state.options = options; const root = $('options'); root.innerHTML = ''; options.forEach((option, i) => { const optionId = option.optionId || option.id; const b = document.createElement('button'); b.className='option'; b.textContent=`${i+1}  ${option.text}`; b.addEventListener('click', () => { buzz(); send('SUBMIT_VOTE_REQ', {questionId:state.questionId, selectedOptionId:optionId, confidence:Number($('confidence').value)}); show('wait'); $('waitText').textContent='Dein Tipp sitzt. Wer wohl blufft?'; }); root.appendChild(b); }); };
  const startTimer = (seconds) => { clearInterval(state.timer); let left = Number(seconds); const update = () => { const shown = Math.max(0,left); $('inputTimer').textContent = `${shown} s`; if ($('hybridTimer')) $('hybridTimer').textContent = shown; if ($('hybridRing')) $('hybridRing').style.strokeDashoffset = String(264 - (264 * shown / Math.max(1, seconds))); if ($('hybridVoteTimer') && state.phase === 'VOTING') $('hybridVoteTimer').textContent = `${shown} s`; }; update(); state.timer = setInterval(() => { left -= 1; update(); if (left <= 0) clearInterval(state.timer); }, 1000); };
  const escapeHtml = (text) => String(text).replace(/[&<>'"]/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
  $('joinButton').addEventListener('click', connect); $('reconnectButton').addEventListener('click', connect);
  $('lie').addEventListener('input', () => { $('counter').textContent = $('lie').value.length; });
  $('confidence').addEventListener('input', () => { $('confidenceValue').textContent = $('confidence').value; });
  $('submitLie').addEventListener('click', () => { buzz(); const text = $('lie').value.trim(); if (!text) { $('inputHint').textContent='Schreib eine falsche Antwort oder warte auf den Timeout.'; return; } if (!state.socket || state.socket.readyState !== WebSocket.OPEN) { $('inputHint').textContent='Keine Verbindung zum Host. Bitte „Verbindung prüfen“ antippen.'; return; } send('SUBMIT_LIE_REQ', {questionId:state.questionId,lieText:text}); show('wait'); $('waitText').textContent='Antwort versiegelt. Niemand darf dein Pokerface lesen.'; });
  $('resultReady').addEventListener('click', () => { if ($('resultReady').disabled) return; buzz(); $('resultReady').disabled = true; $('resultReady').textContent = 'BEREIT · WARTE AUF DIE ANDEREN …'; send('READY_GATE_REQ', {playerName:state.name, gateId:state.gateId}); });
  $('readyGateButton').addEventListener('click', () => { if (state.gateReady) return; buzz(); state.gateReady = true; send('READY_GATE_REQ', {playerName:state.name, gateId:state.gateId}); renderGate({gate:'LOBBY', gateId:state.gateId, ready:[state.playerId], players:[{name:state.name,ready:true}], readyCount:1, total:1}); });
})();
