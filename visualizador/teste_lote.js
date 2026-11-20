// Confere o port: 6 especialistas de Sprint Grama, 4000 corridas. Rode: node visualizador/teste_lote.js
// Esperado: cada uma entre ~11% e ~22%. Com 4000 (v0.7, com o extra de +2% da Perseguidora,
// docs/corrida.md §8.5): Altair 15,4 · Spica 21,3 · Adara 12,6 · Alcione 19,5 · Electra 19,7 · Maia 11,5
const SIM = require("./sim.js");
global.window = {};
require("./garotas.js");
const casa = window.GAROTAS.filter(g => g.casa[0] === 0 && g.casa[1] === 0);
const field = casa.map(g => SIM.corredora(g, 0, 0));
const N = 4000, wins = new Array(field.length).fill(0);
for (let k = 0; k < N; k++) wins[SIM.race(field, 1200, k)[0]]++;
casa.forEach((g, i) => console.log(`${g.nome.padEnd(18)} ${g.estilo} ${(100 * wins[i] / N).toFixed(1)}%`));
const ok = wins.every(w => w / N > 0.10 && w / N < 0.23);
console.log(ok ? "OK" : "FORA DA FAIXA");
process.exit(ok ? 0 : 1);
