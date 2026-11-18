"""Resume as saídas JSON de testes/balanco.gd (docs/campanhas.md §6.4 e §7).

Uso: python tools/resumo_balanco.py saida_0.json [saida_1.json ...]
Mostra a taxa geral, a queda por objetivo, as taxas por casa e por arquétipo (com a
diferença entre a maior e a menor), a divisão no ponto de virada por campanha e os títulos.
"""
import json
import os
import sys
from collections import defaultdict

ESTILO_NOME = {"pon": "Ponteira", "per": "Perseguidora", "arr": "Arrancadora", "fec": "Fechadora"}

OBJ = [13, 20, 24, 32, 40, 48, 60, 72]


def carregar(caminhos):
    todos = []
    for c in caminhos:
        with open(c, encoding="utf-8") as f:
            todos.extend(json.load(f))
    return todos


def pct(a, b):
    return 100.0 * a / b if b else 0.0


def estilos():
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    with open(os.path.join(raiz, "data", "garotas.json"), encoding="utf-8-sig") as f:
        return {g["nome"]: ESTILO_NOME[g["estilo"]] for g in json.load(f)}


def main():
    rs = carregar(sys.argv[1:])
    est = estilos()
    for r in rs:
        r["estilo"] = est.get(r["nome"], "?")
    n = sum(r["n"] for r in rs)
    passou = [sum(r["passou"][j] for r in rs) for j in range(8)]
    print(f"{len(rs)} garotas, {n} carreiras ({rs[0]['conta']})")
    print("Passa:  " + " ".join(f"{pct(p, n):5.1f}" for p in passou))
    quedas = []
    ant = n
    for p in passou:
        quedas.append(pct(ant - p, ant))
        ant = p
    print("Queda:  " + " ".join(f"{q:5.1f}" for q in quedas))
    print(f"Completas: {pct(passou[7], n):.1f}%")
    curva = [sum(r["curva"][j] * r["n"] for r in rs) / n for j in range(6)]
    print("Curva:  " + " / ".join(f"{c:.0f}" for c in curva))
    print(f"Corridas por carreira: {sum(r['corridas'] * r['n'] for r in rs) / n:.1f}")
    print(f"GP final vencido: {pct(sum(r['gp_final'] for r in rs), n):.1f}%")
    comp = {k: sum(r["completou"][k] for r in rs) for k in "AB"}
    cam = {k: sum(r["caminho"][k] for r in rs) for k in "AB"}
    print("Depois da virada: A completa %.0f%%, B completa %.0f%%" % (pct(comp["A"], cam["A"]), pct(comp["B"], cam["B"])))

    for chave in ("casa", "arquetipo", "estilo"):
        g = defaultdict(lambda: [0, 0])
        for r in rs:
            g[r[chave]][0] += r["passou"][7]
            g[r[chave]][1] += r["n"]
        taxas = sorted(((pct(a, b), k, b) for k, (a, b) in g.items()))
        print(f"\nPor {chave}:")
        for t, k, b in taxas:
            print(f"  {k:16s} {t:5.1f}%  ({b} carreiras)")
        sem_mvp = [t for t, k, _ in taxas if k != "(MVP)"] or [t for t, _, _ in taxas]
        print(f"  diferença: {max(sem_mvp) - min(sem_mvp):.1f} pontos")

    print("\nVirada (% no caminho A entre as que passam do turno 48):")
    v = defaultdict(lambda: [0, 0])
    for r in rs:
        k = r["nome"] if r["arquetipo"] == "(MVP)" else r["arquetipo"]
        v[k][0] += r["caminho"]["A"]
        v[k][1] += r["caminho"]["A"] + r["caminho"]["B"]
    for k, (a, b) in sorted(v.items(), key=lambda x: pct(*x[1])):
        marca = "" if 35 <= pct(a, b) <= 65 else "  <- fora"
        print(f"  {k:16s} {pct(a, b):5.1f}%  ({b}){marca}")

    tit = defaultdict(int)
    for r in rs:
        for k, q in r["titulos"].items():
            tit[k] += q
    print("\nTítulos por carreira: " + ", ".join(f"{k} {q / n:.2f}" for k, q in sorted(tit.items())))
    if all("com_titulo" in r for r in rs):
        ct = defaultdict(int)
        for r in rs:
            for k, q in r["com_titulo"].items():
                ct[k] += q
        print("Carreiras com o título: " + ", ".join(f"{k} {pct(q, n):.0f}%" for k, q in sorted(ct.items())))


if __name__ == "__main__":
    main()
