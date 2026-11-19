// Port fiel de race() e corredora() de tools/sim_corrida.py (docs/corrida.md §2–§7).
// Se mudar uma constante lá, mude aqui também.
(function () {
  const V0 = 20.0, A0 = 0.35, DT = 0.1;
  const K_VEL = 1.2, K_HP_D = 0.6, K_HP = 1.5;
  const K_INT_FINAL = 1.5;
  const K_DET_SPRINT = 7.0, K_DET_FINAL = 2.0, K_HP_SPRINT = 3.0;
  const BLOCK = 0.015;
  const SORTE = 0.025;
  const SKILL_BASE = 0.0, SKILL_INT = 1.2;
  const KEYS = ["vel", "est", "pod", "det", "int"];
  const W = {
    pon: { vel: 1.0, est: 1.0, pod: 0.95, det: 0.95, int: 1.1 },
    per: { vel: 1.0, est: 1.0, pod: 1.0, det: 1.0, int: 1.0 },
    arr: { vel: 1.0, est: 1.0, pod: 1.1, det: 1.0, int: 0.9 },
    fec: { vel: 1.0, est: 1.0, pod: 1.05, det: 1.1, int: 0.85 },
  };
  const PH = {
    // recalibrado para o teto de velocidade (v0.5)
    pon: [0.9943, 0.9694, 0.9843, 0.9893],
    per: [0.9877, 0.9678, 0.9927, 0.9977],
    arr: [0.9710, 0.9659, 1.0060, 1.0110],
    fec: [0.9568, 0.9669, 1.0122, 1.0525],
  };
  // Correção de estilo por nível e distância (corrida.md §8.5), igual a CORRECAO_ESTILO de
  // scripts/sim_corrida.gd. Vale 1,0 a partir do nível 800.
  const CORR_NIVEIS = [200, 300, 375, 450, 525, 600, 700, 800];
  const CORR_DISTS = [1200, 1600, 2000, 2400, 3200];
  const CORRECAO_ESTILO = {
    pon: [[1.0132, 0.9964, 0.9834, 0.9762, 0.9688], [1.0189, 0.9989, 0.9913, 0.9793, 0.9694], [1.0496, 1.0090, 0.9821, 0.9808, 0.9640], [1.0402, 1.0461, 1.0021, 0.9779, 0.9766], [1.0156, 1.0427, 1.0329, 0.9961, 0.9686], [0.9984, 1.0198, 1.0251, 1.0286, 0.9751], [0.9954, 1.0059, 1.0085, 1.0101, 1.0099], [1.0, 1.0, 1.0, 1.0, 1.0]],
    per: [[1.0157, 1.0073, 0.9886, 0.9871, 0.9856], [1.0099, 1.0046, 1.0028, 0.9883, 0.9880], [1.0145, 1.0043, 1.0006, 1.0003, 0.9895], [1.0105, 1.0182, 0.9986, 0.9947, 0.9924], [0.9978, 1.0105, 1.0091, 0.9994, 0.9938], [0.9920, 0.9980, 0.9995, 0.9999, 0.9932], [0.9930, 0.9907, 0.9910, 0.9956, 0.9891], [1.0, 1.0, 1.0, 1.0, 1.0]],
    arr: [[1.0130, 1.0143, 1.0109, 1.0120, 1.0195], [1.0034, 1.0135, 1.0123, 1.0156, 1.0175], [1.0011, 1.0045, 1.0164, 1.0147, 1.0176], [0.9911, 0.9904, 1.0099, 1.0177, 1.0139], [0.9855, 0.9855, 0.9919, 1.0090, 1.0191], [0.9804, 0.9840, 0.9911, 0.9908, 1.0155], [0.9846, 0.9942, 0.9921, 0.9936, 0.9957], [1.0, 1.0, 1.0, 1.0, 1.0]],
    fec: [[0.9581, 0.9820, 1.0172, 1.0248, 1.0261], [0.9678, 0.9830, 0.9935, 1.0167, 1.0251], [0.9348, 0.9821, 1.0009, 1.0042, 1.0289], [0.9582, 0.9453, 0.9893, 1.0097, 1.0171], [1.0011, 0.9612, 0.9661, 0.9954, 1.0185], [1.0292, 0.9982, 0.9843, 0.9807, 1.0161], [1.0269, 1.0092, 1.0085, 1.0007, 1.0052], [1.0, 1.0, 1.0, 1.0, 1.0]],
  };
  function naGrade(grade, x) {
    if (x <= grade[0]) return [0, 0];
    for (let i = 0; i < grade.length - 1; i++) {
      if (x <= grade[i + 1]) return [i, (x - grade[i]) / (grade[i + 1] - grade[i])];
    }
    return [grade.length - 2, 1];
  }
  function correcaoEstilo(style, nivel, D) {
    const m = CORRECAO_ESTILO[style];
    const [i, a] = naGrade(CORR_NIVEIS, nivel);
    const [j, b] = naGrade(CORR_DISTS, D);
    const baixo = m[i][j] + (m[i][j + 1] - m[i][j]) * b;
    const cima = m[i + 1][j] + (m[i + 1][j + 1] - m[i + 1][j]) * b;
    return baixo + (cima - baixo) * a;
  }
  // (fase, tipo, valor, duração s)
  const SKILLS = [[1, "hp", 0.06, 0], [1, "vel", 0.8, 4.0], [2, "vel", 0.8, 4.0], [2, "hp", 0.04, 0], [3, "vel", 1.0, 4.0]];
  const APT = { R: 0.90, O: 0.95, B: 1.00, X: 1.05 };
  // Teto de velocidade (km/h) e escala de unidades. ESCALA multiplica todas as velocidades
  // (acelerações por ESCALA², durações por 1/ESCALA, gasto de fôlego por segundo por ESCALA),
  // então sem o teto a corrida seria a mesma, só mais lenta. Igual a TETO/ESCALA do sim_corrida.py.
  const cfg = { ESCALA: 0.66, TETO: [60, 65] };
  const DIST = [["sprint", 1200], ["milha", 1600], ["media", 2000], ["longa", 3200]];
  const PISO = ["grama", "terra"];

  // RNG com semente (mulberry32) + gauss por Box-Muller.
  // Não reproduz a sequência do random do Python, só a distribuição.
  function rng(seed) {
    let a = seed >>> 0;
    const random = () => {
      a = (a + 0x6D2B79F5) >>> 0;
      let t = a;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
    const gauss = (mu, sigma) => {
      const u = 1 - random(), v = random();
      return mu + sigma * Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
    };
    return { random, gauss };
  }

  function phase(x, D) {
    return x < D / 6 ? 0 : x < 0.6 * D ? 1 : x < D - 400 ? 2 : 3;
  }

  // field: lista de [estilo, atributos, multiplicador]. Avance com step() até done.
  function novaCorrida(field, D, seed) {
    const rnd = rng(seed);
    const k = cfg.ESCALA, v0 = V0 * k;
    let nivel = 0;
    for (const [, s] of field) for (const k of KEYS) nivel += s[k];
    nivel /= 5 * field.length;
    const rs = field.map(([style, s, mult], idx) => {
      const corr = correcaoEstilo(style, nivel, D);
      const e = {};
      for (const k of KEYS) e[k] = s[k] * W[style][k] * mult * corr;
      const hpmax = K_HP_D * D + K_HP * e.est;
      const noise = rnd.gauss(0, SORTE * (1 - e.int / 2400));
      const chance = Math.min(0.9, SKILL_BASE + SKILL_INT * e.int / 1200);
      // teto: 60 km/h com Vel 0 até 65 km/h com Vel 1200 (linear)
      const vmax = cfg.TETO ? (cfg.TETO[0] + (cfg.TETO[1] - cfg.TETO[0]) * Math.min(Math.max(e.vel, 0), 1200) / 1200) / 3.6 : Infinity;
      return { idx, st: style, e, hp: hpmax, hpmax, vmax, v: 3.0 * k, x: 0.0, t: null,
               blk: 0.0, noise, chance, ph: -1, buff: 0.0, buff_t: 0.0 };
    });
    const corrida = { rs, D, t: 0.0, done: false };

    // Um passo de DT. Retorna as habilidades disparadas: [{idx, fase, tipo, val, dur}].
    corrida.step = function () {
      const ev = [];
      corrida.t += DT;
      const t = corrida.t;
      const order = rs.slice().sort((a, b) => b.x - a.x);
      for (let i = 0; i < order.length; i++) {
        const r = order[i];
        if (r.t !== null) continue;
        const e = r.e, p = phase(r.x, D);
        if (p !== r.ph) {
          r.ph = p;
          for (const [fase, tipo, val, dur] of SKILLS) {
            if (fase === p && rnd.random() < r.chance) {
              if (tipo === "hp") r.hp += val * r.hpmax;
              else { r.buff = val * k; r.buff_t = dur / k; }
              ev.push({ idx: r.idx, fase, tipo, val, dur });
            }
          }
        }
        let vt = (V0 + K_VEL * e.vel / 1000) * k * PH[r.st][p] * (1 + r.noise);
        if (p === 2) vt += k * (K_DET_FINAL * e.det + K_INT_FINAL * e.int) / 1000;
        if (p === 3) {
          const bonus = k * (K_DET_SPRINT * e.det / 1000 + K_HP_SPRINT * Math.max(r.hp, 0) / r.hpmax);
          const vf = vt + bonus;
          const need = 20 * k * (vf / v0) ** 2 * (1.1 - e.det / 2000) * (D - r.x) / vf;
          vt += bonus * Math.min(1.0, Math.max(r.hp, 0) / need);
        }
        if (r.hp <= 0) vt = v0 * (0.80 + 0.15 * e.det / 1000);
        if (r.buff_t > 0) { vt += r.buff; r.buff_t -= DT; }
        if (i > 0 && p >= 1) {
          const f = order[i - 1];
          if (0 < f.x - r.x && f.x - r.x < 2 && f.v < vt && r.blk <= 0) {
            if (rnd.random() < k * BLOCK * (1 - e.pod / 1500) * (1 - e.int / 2000)) r.blk = 1.0 / k;
          }
          if (r.blk > 0) { vt = Math.min(vt, f.v); r.blk -= DT; }
        }
        vt = Math.min(vt, r.vmax);
        const a = A0 * k * k * (0.8 + e.pod / 1000) * (p === 0 ? 5 : 1);
        r.v = r.v < vt ? Math.min(vt, r.v + a * DT) : Math.max(vt, r.v - 0.8 * k * k * DT);
        let cost = 20 * k * (r.v / v0) ** 2;
        if (p === 1) cost *= 1.2 - e.int / 1500;
        if (p === 3) cost *= 1.1 - e.det / 2000;
        r.hp -= cost * DT;
        r.x += r.v * DT;
        if (r.x >= D) r.t = t;
      }
      corrida.done = rs.every(r => r.t !== null);
      return ev;
    };

    // Índices na ordem de chegada (empate: ordem do field, como o sorted do Python).
    corrida.chegada = () => rs.slice().sort((a, b) => a.t - b.t).map(r => r.idx);
    return corrida;
  }

  function race(field, D, seed) {
    const c = novaCorrida(field, D, seed);
    while (!c.done) c.step();
    return c.chegada();
  }

  // Garota no formato do simulador: perfil escalado para a média, aptidão d × p e humor aplicados.
  function corredora(g, d, p, media = 600, humor = 1.0) {
    const soma = KEYS.reduce((acc, k) => acc + g.atributos[k], 0);
    const scale = media * KEYS.length / soma;
    const s = {};
    for (const k of KEYS) s[k] = g.atributos[k] * scale;
    return [g.estilo, s, APT[g.aptidao[DIST[d][0]]] * APT[g.aptidao[PISO[p]]] * humor];
  }

  const api = { cfg, PH, V0, DT, KEYS, APT, DIST, PISO, phase, novaCorrida, race, corredora };
  if (typeof module !== "undefined") module.exports = api;
  else window.SIM = api;
})();
