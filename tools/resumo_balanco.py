"""Resume as saídas JSON de testes/balanco.gd (docs/campanhas.md §6.4 e §7).

Uso: python tools/resumo_balanco.py [--fora] saida_0.json [saida_1.json ...]
Mostra a taxa geral, a queda por objetivo, as taxas por casa e por arquétipo (com a
diferença entre a maior e a menor), a divisão no ponto de virada por campanha e os títulos.
Com --fora, mostra também os pontos fora da curva: a queda de cada objetivo por casa, arquétipo
e estilo, a grade casa x estilo e as garotas longe da média (em desvios da sorte).
"""
import math
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


def desvio(taxa, n):
    """Desvio da sorte (binomial) de uma taxa em % com n carreiras."""
    p = taxa / 100.0
    return 100.0 * math.sqrt(max(p * (1 - p), 0.01) / max(n, 1))


def fora_da_curva(rs, n, passou):
    geral = pct(passou[7], n)
    print("\n== Pontos fora da curva ==")
    print("Queda por objetivo (marcada com * acima de 20%, ** acima de 25%):")
    for chave in ("casa", "arquetipo", "estilo"):
        g = defaultdict(lambda: [0] * 9)
        for r in rs:
            g[r[chave]][0] += r["n"]
            for j in range(8):
                g[r[chave]][j + 1] += r["passou"][j]
        print(f"  {'por ' + chave + ':':16s}" + "".join(f"{'t' + str(o):>7s}" for o in OBJ) + "   final")
        for k in sorted(g, key=lambda x: pct(g[x][8], g[x][0])):
            v = g[k]
            cel = []
            for j in range(8):
                q = pct(v[j] - v[j + 1], v[j])
                cel.append(f"{q:5.0f}{'**' if q > 25 else ('* ' if q > 20 else '  ')}")
            print(f"    {k:14s}" + "".join(cel) + f" {pct(v[8], v[0]):5.1f}%")
    casas = sorted({r["casa"] for r in rs})
    ests = sorted({r["estilo"] for r in rs})
    print("\nGrade casa x estilo (% de carreiras completas):")
    print("    " + " " * 14 + "".join(f"{e[:12]:>13s}" for e in ests))
    for c in casas:
        linha = []
        for e in ests:
            a = sum(r["passou"][7] for r in rs if r["casa"] == c and r["estilo"] == e)
            b = sum(r["n"] for r in rs if r["casa"] == c and r["estilo"] == e)
            linha.append(f"{pct(a, b):12.0f}%" if b else " " * 13)
        print(f"    {c:14s}" + "".join(linha))
    print(f"\nGarotas a mais de 2 desvios da sorte da média ({geral:.1f}%):")
    for r in sorted(rs, key=lambda x: pct(x["passou"][7], x["n"])):
        t = pct(r["passou"][7], r["n"])
        z = (t - geral) / desvio(geral, r["n"])
        if abs(z) >= 2:
            print(f"    {r['nome']:11s} {r['arquetipo']:14s} {r['casa']:13s} {r['estilo']:12s} {t:5.1f}%  ({z:+.1f} desvios)")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    rs = carregar(args)
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
    if "--fora" in sys.argv:
        fora_da_curva(rs, n, passou)


if __name__ == "__main__":
    main()
