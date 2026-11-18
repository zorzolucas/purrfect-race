"""Lê as fichas de docs/visual-elenco.md e grava signo, aniversário e visual de cada garota
em data/garotas.json e data/rivais.json. O documento é a fonte: mudou a ficha, rode de novo.
Rode: python tools/importar_visual.py   (o gerar_elenco.py também chama no fim)

Campos gravados em cada garota:
  signo, elemento, aniversario [dia, mês]  -> regras de jogo (visual-elenco.md §3)
  visual: pelagem, paleta [base, secundária, detalhe], marca, altura, porte,
          cabelo, olhos, orelhas, rabo                              -> arte (GDD §11)
"""
import json, os, re, unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, "docs", "visual-elenco.md")

SIGNOS = {"Áries": "fogo", "Touro": "terra", "Gêmeos": "ar", "Câncer": "agua", "Leão": "fogo",
          "Virgem": "terra", "Libra": "ar", "Escorpião": "agua", "Sagitário": "fogo",
          "Capricórnio": "terra", "Aquário": "ar", "Peixes": "agua"}
MESES = {"jan": 1, "fev": 2, "mar": 3, "abr": 4, "mai": 5, "jun": 6, "jul": 7, "ago": 8,
         "set": 9, "out": 10, "nov": 11, "dez": 12}
# a pelagem van tem a cor secundária "da marca": a cor da cabeça e do rabo de cada uma
COR_VAN = {"Carina": "#7D8A99", "Zaniah": "#C4672B"}
# variações de pelagem descritas na ficha (ex.: siamesa de pontas azuladas): troca cores da paleta
VARIANTE = {"Adara": {1: "#6F7C8C"}, "Auriga": {0: "#B8693E"}, "Avior": {0: "#A89F92", 1: "#5E6976"},
            "Andrômeda": {0: "#EFE4CC"}, "Corona": {0: "#F1DDB0"}, "Mirach": {0: "#3A4250"},
            "Achernar": {1: "#2F3033"}}


def slug(texto):
    t = unicodedata.normalize("NFD", texto.lower())
    t = "".join(ch for ch in t if unicodedata.category(ch) != "Mn")
    return re.sub(r"[^a-z0-9]+", "_", t).strip("_")


def limpar(texto):
    """Tira o Markdown (negrito e itálico) e espaços sobrando."""
    t = re.sub(r"\*\*|\*", "", texto)
    return re.sub(r"\s+", " ", t).strip().rstrip(".")


def signo_e_data(texto):
    """'♐ Sagitário · aniversário 2/dez' ou '♈ Áries, 28/mar' -> (signo, elemento, [dia, mês])."""
    nome = next(s for s in SIGNOS if s in texto)
    m = re.search(r"(\d{1,2})/([a-z]{3})", texto)
    return slug(nome), SIGNOS[nome], [int(m.group(1)), MESES[m.group(2)]]


def corpo(texto):
    """'Alta, atlética (a "grandona fofa")' -> ('alta', 'atletica')."""
    m = re.match(r"\s*(Baixa|Média|Alta),\s*(esguia|atlética)", texto)
    return slug(m.group(1)), slug(m.group(2))


def ler_pelagens(md):
    """Tabela do §2: nome da pelagem, paleta e garotas de cada uma."""
    pel, de_quem = {}, {}
    sec = md.split("## 2. As 23 pelagens")[1].split("\n## ")[0]
    for linha in sec.splitlines():
        cols = [c.strip() for c in linha.strip().strip("|").split("|")]
        if len(cols) != 5 or not cols[0].isdigit():
            continue
        nome = limpar(cols[1]).split(" (")[0]
        cores = re.findall(r"#[0-9A-Fa-f]{6}", cols[3])
        if "cor da marca" in cols[3]:
            cores.insert(1, None)
        pel[nome] = cores
        for g in cols[4].split(","):
            de_quem[g.strip()] = nome
    return pel, de_quem


def ler_fichas_completas(md):
    """§4: fichas em tabela (MVP e rivais)."""
    fichas = {}
    sec = md.split("## 4. Fichas do MVP e das rivais")[1].split("\n## 5.")[0]
    for bloco in sec.split("\n### ")[1:]:
        nome = re.match(r"[\d.]+\s+(\S+)", bloco).group(1)
        campos = {}
        for linha in bloco.splitlines():
            m = re.match(r"\|\s*\*\*(.+?)\*\*\s*\|\s*(.+?)\s*\|$", linha)
            if m:
                campos[m.group(1)] = m.group(2)
        signo, elemento, aniv = signo_e_data(campos["Signo"])
        marca = re.split(r"\*\*Marca:\*\*", campos["Pelagem"])
        altura, porte = corpo(campos["Corpo"])
        fichas[nome] = dict(signo=signo, elemento=elemento, aniversario=aniv,
                            marca=limpar(marca[1] if len(marca) > 1 else marca[0]),
                            altura=altura, porte=porte, cabelo=limpar(campos["Cabelo"]),
                            olhos=limpar(campos["Olhos"]), orelhas=limpar(campos["Orelhas"]),
                            rabo=limpar(campos["Rabo"]))
    return fichas


def ler_fichas_curtas(md):
    """§5: '**Nome** · Estilo · Arquétipo · ♈ Signo, dd/mmm' e a linha '*Visual:*' em frases."""
    fichas = {}
    sec = md.split("## 5. Fichas da pool")[1].split("\n## 6.")[0]
    for m in re.finditer(r"^\*\*(\S+)\*\* · .*?· (.+)\n- \*Visual:\* (.+)$", sec, re.M):
        nome, cab, vis = m.groups()
        signo, elemento, aniv = signo_e_data(cab)
        # frases: "pelagem, marca. Alta, atlética. Cabelo ... Olhos ... Orelhas ... Rabo ..."
        frases = re.split(r"\.\s+(?=[A-ZÁÉÍÓÚÂÊÔ])", vis.strip())
        pelo = frases[0]
        mm = re.split(r"\*\*marca:\*\*", pelo)
        marca = mm[1] if len(mm) > 1 else pelo
        altura, porte = corpo(frases[1])
        f = dict(signo=signo, elemento=elemento, aniversario=aniv, marca=limpar(marca),
                 altura=altura, porte=porte, cabelo="", olhos="", orelhas="", rabo="")
        for fr in frases[2:]:
            primeira = fr.split()[0]
            chave = {"Olhos": "olhos", "Orelhas": "orelhas", "Rabo": "rabo", "Cabelo": "cabelo"}.get(primeira, "cabelo")
            if primeira in ("Olhos", "Orelhas", "Rabo", "Cabelo"):
                fr = fr[len(primeira):].strip()  # "Olhos azuis" -> "Azuis", como nas fichas completas
            fr = limpar(fr)
            fr = fr[:1].upper() + fr[1:]
            f[chave] = (f[chave] + ". " if f[chave] else "") + fr
        if not f["olhos"]:
            # a cor dos olhos está na marca (ex.: heterocromia da Albireo, olhos verdes da Bellatrix)
            f["olhos"] = "ver marca"
        fichas[nome] = f
    return fichas


def importar(garotas, rivais):
    md = open(DOC, encoding="utf-8").read()
    pel, de_quem = ler_pelagens(md)
    fichas = ler_fichas_completas(md)
    fichas.update(ler_fichas_curtas(md))
    for g in garotas + rivais:
        f = fichas[g["nome"]]
        p = de_quem[g["nome"]]
        paleta = list(pel[p])
        if paleta[1] is None:
            paleta[1] = COR_VAN[g["nome"]]
        for i, cor in VARIANTE.get(g["nome"], {}).items():
            paleta[i] = cor
        g["signo"], g["elemento"], g["aniversario"] = f["signo"], f["elemento"], f["aniversario"]
        g["visual"] = dict(pelagem=slug(p), paleta=paleta, marca=f["marca"], altura=f["altura"],
                           porte=f["porte"], cabelo=f["cabelo"], olhos=f["olhos"],
                           orelhas=f["orelhas"], rabo=f["rabo"])
    return garotas, rivais


def conferir(garotas):
    from collections import Counter
    assert len(garotas) == 48
    signos = Counter(g["signo"] for g in garotas)
    assert set(signos.values()) == {4} and len(signos) == 12, signos
    pelagens = Counter(g["visual"]["pelagem"] for g in garotas)
    assert max(pelagens.values()) <= 3, pelagens
    combos = Counter((g["visual"]["pelagem"], g["visual"]["marca"]) for g in garotas)
    assert max(combos.values()) == 1
    for g in garotas:
        v = g["visual"]
        assert v["altura"] in ("baixa", "media", "alta") and v["porte"] in ("esguia", "atletica"), g["nome"]
        assert all(v[k] for k in ("marca", "cabelo", "orelhas", "rabo")), g["nome"]


def gravar(caminho, dados, indent):
    """Grava mantendo o fim de linha do arquivo (o repositório guarda os JSON com CRLF)."""
    nl = "\n"
    if os.path.exists(caminho):
        with open(caminho, "rb") as f:
            if b"\r\n" in f.read(4096):
                nl = "\r\n"
    with open(caminho, "w", encoding="utf-8", newline=nl) as f:
        f.write(json.dumps(dados, ensure_ascii=False, indent=indent))


def main():
    cam_g = os.path.join(ROOT, "data", "garotas.json")
    cam_r = os.path.join(ROOT, "data", "rivais.json")
    garotas = json.load(open(cam_g, encoding="utf-8"))
    rivais = json.load(open(cam_r, encoding="utf-8"))
    importar(garotas, rivais)
    conferir(garotas)
    gravar(cam_g, garotas, 1)
    gravar(cam_r, rivais, 2)
    print("Visual de %d garotas e %d rivais gravado." % (len(garotas), len(rivais)))


if __name__ == "__main__":
    main()
