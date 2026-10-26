(() => {
  'use strict';
  let ctx = null;
  let master = null;
  let enabled = false;
  const ensure = async () => {
    try {
      const AudioCtor = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtor) return false;
      if (!ctx) {
        ctx = new AudioCtor();
        master = ctx.createGain();
        master.gain.value = 0.16;
        master.connect(ctx.destination);
      }
      if (ctx.state === 'suspended') await ctx.resume();
      enabled = ctx.state === 'running';
      return enabled;
    } catch (_) {
      enabled = false;
      return false;
    }
  };
  const tone = (frequency, duration = 0.12, type = 'sine', gain = 0.12, when = 0) => {
    if (!enabled || !ctx) return;
    const start = ctx.currentTime + when;
    const oscillator = ctx.createOscillator();
    const envelope = ctx.createGain();
    oscillator.type = type;
    oscillator.frequency.setValueAtTime(frequency, start);
    envelope.gain.setValueAtTime(0.0001, start);
    envelope.gain.exponentialRampToValueAtTime(gain, start + 0.012);
    envelope.gain.exponentialRampToValueAtTime(0.0001, start + duration);
    oscillator.connect(envelope).connect(master);
    oscillator.start(start);
    oscillator.stop(start + duration + 0.02);
  };
  const play = (name) => {
    if (!enabled) return;
    if (name === 'join' || name === 'ready' || name === 'click') { tone(660, .08, 'triangle', .13); tone(990, .12, 'triangle', .11, .06); }
    if (name === 'tick') tone(520, .045, 'square', .06);
    if (name === 'go') { tone(392, .14, 'sawtooth', .15); tone(587, .18, 'sawtooth', .14, .12); tone(784, .25, 'triangle', .16, .25); }
    if (name === 'buzzer') { tone(180, .18, 'sawtooth', .12); tone(130, .28, 'sawtooth', .12, .18); }
    if (name === 'truth') { tone(523, .16, 'triangle', .14); tone(659, .18, 'triangle', .14, .12); tone(784, .32, 'triangle', .17, .25); }
    if (name === 'points') { [660, 784, 988, 1174].forEach((f, i) => tone(f, .08, 'triangle', .1, i * .06)); }
  };
  window.BluffAudio = { ensure, play, isEnabled: () => enabled };
})();
