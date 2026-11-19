"""Recorta as fichas conceituais (arte/animações/*.png) em sprites para o jogo.

Cada ficha tem o corpo de frente à esquerda e 6 expressões embaixo, na ordem do atlas
do modelo: normal, fechados, feliz, surpresa, tonta, piscadinha. O fundo cinza-claro e as
linhas-guia viram transparência (preenchimento a partir das bordas, o contorno preto
protege o desenho).

Saída em sprites/garotas/:
  <nome>_corpo.png    corpo de frente, altura 512 px
  <nome>_rostos.png   atlas 6 x 1 de 256 x 256 px

Uso: python tools/recortar_fichas.py
"""
import glob
import os
import sys

import numpy as np
from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEM = os.path.join(RAIZ, "arte", "animações")
DESTINO = os.path.join(RAIZ, "sprites", "garotas")
# Ordem das fichas pelo nome do arquivo (como foram exportadas).
NOMES = ["Lira", "Nashira", "Mira", "Capela", "Antares", "Shaula", "Polaris", "Algol"]
CORPO = (0, 68, 724, 785)        # x0, y0, x1, y1 na ficha 1448 x 1086 (até abaixo da linha do chão)
FAIXA_ROSTOS = (850, 1066)        # y da fileira de expressões
ALTURA_CORPO = 512
LADO_ROSTO = 256


def fundo(arr: np.ndarray, estrito: bool = False) -> np.ndarray:
    """Pixels que podem ser fundo: cinza claro, quase sem cor (inclui as linhas-guia).
    No modo estrito só a cor do papel, para não comer cabelo branco (Polaris)."""
    if estrito:
        papel = np.median(arr[:4].reshape(-1, 3), axis=0)
        return np.abs(arr.astype(int) - papel).max(axis=2) < 9
    mx = arr.max(axis=2).astype(int)
    mn = arr.min(axis=2).astype(int)
    return (mx - mn < 22) & (mn > 160)


def dilatar(m: np.ndarray) -> np.ndarray:
    d = m.copy()
    d[1:, :] |= m[:-1, :]
    d[:-1, :] |= m[1:, :]
    d[:, 1:] |= m[:, :-1]
    d[:, :-1] |= m[:, 1:]
    return d


def alcance_das_bordas(cand: np.ndarray, bordas=("t", "b", "l", "r")) -> np.ndarray:
    """Pixels candidatos ligados às bordas pedidas (dilatação repetida, sem scipy)."""
    alc = np.zeros_like(cand)
    if "t" in bordas:
        alc[0, :] = cand[0, :]
    if "b" in bordas:
        alc[-1, :] = cand[-1, :]
    if "l" in bordas:
        alc[:, 0] = cand[:, 0]
    if "r" in bordas:
        alc[:, -1] = cand[:, -1]
    while True:
        d = alc.copy()
        d[1:, :] |= alc[:-1, :]
        d[:-1, :] |= alc[1:, :]
        d[:, 1:] |= alc[:, :-1]
        d[:, :-1] |= alc[:, 1:]
        d &= cand
        if (d == alc).all():
            return alc
        alc = d


def vaos_fechados(arr: np.ndarray, livres: np.ndarray, y_chao: int, area_min: int = 150) -> np.ndarray:
    """O vão entre as pernas: área cercada de contorno, quase toda da cor do papel, que
    desce até o chão. Só a cor não basta, porque a roupa branca da Polaris é igual ao papel."""
    papel = fundo(arr, True)
    vaos = np.zeros_like(livres)
    resto = livres & papel
    while resto.any():
        y, x = np.argwhere(resto)[0]
        reg = np.zeros_like(livres)
        reg[y, x] = True
        while True:
            d = dilatar(reg) & livres
            if (d == reg).all():
                break
            reg = d
        resto &= ~reg
        if reg.sum() >= area_min and reg[y_chao - 8:].any() and (reg & papel).sum() > 0.6 * reg.sum():
            vaos |= reg
    return vaos


def recortar(img: Image.Image, caixa, chao: tuple = ()) -> Image.Image:
    """Recorta a caixa e deixa o fundo transparente. chao = (y0, y1) da linha do chão
    na caixa, para o corpo: a linha some onde não há tênis em cima (abre o vão entre as
    pernas) e continua embaixo dos tênis, como contorno da sola."""
    parte = img.crop(caixa).convert("RGB")
    arr = np.array(parte)
    if chao:
        y0, y1 = chao
        acima = fundo(arr[y0 - 4:y0 - 3])[0]
        for y in range(y0 - 2, min(y1 + 3, arr.shape[0])):
            arr[y, acima] = arr[0, 0]
        arr = arr[: y1 + 3]
    # o contorno engrossado em 1 px fecha frestas (orelhas claras da Polaris, por exemplo)
    contorno = dilatar(arr.max(axis=2) < 110)
    if chao:
        # linhas-guia (cinza) contam como fundo
        cand = fundo(arr)
        fora = alcance_das_bordas(cand & ~contorno)
        fora |= vaos_fechados(arr, cand & ~contorno & ~fora, chao[0])
    else:
        # o pescoço encosta na moldura de baixo: só preenche a partir de cima e dos lados,
        # e só a cor do papel, para não comer cabelo branco
        cand = fundo(arr, True)
        fora = alcance_das_bordas(cand & ~contorno, ("t", "l", "r"))
    fora = dilatar(fora) & cand
    alfa = np.where(fora, 0, 255).astype(np.uint8)
    out = Image.fromarray(np.dstack([arr, alfa]), "RGBA")
    return out.crop(out.getbbox())


def colunas_da_moldura(img: Image.Image) -> list:
    """Linhas verticais escuras da moldura das expressões."""
    arr = np.array(img.convert("L").crop((0, FAIXA_ROSTOS[0] + 10, img.width, FAIXA_ROSTOS[1] - 10)))
    escuras = (arr < 80).mean(axis=0) > 0.85
    cols, x = [], 0
    while x < len(escuras):
        if escuras[x]:
            ini = x
            while x < len(escuras) and escuras[x]:
                x += 1
            cols.append((ini, x))
        x += 1
    return cols


def linha_do_chao(img: Image.Image) -> tuple:
    """Linhas (y0, y1), na caixa do corpo, da linha preta do chão embaixo dos pés."""
    arr = np.array(img.convert("L").crop(CORPO))
    for y in range(arr.shape[0] - 1, 0, -1):
        if (arr[y] < 90).mean() > 0.6:
            y0 = y
            while y0 > 0 and (arr[y0 - 1] < 90).mean() > 0.6:
                y0 -= 1
            return (y0, y)
    sys.exit("não achei a linha do chão")


def linhas_da_moldura(img: Image.Image) -> list:
    """As 7 linhas da moldura: as das pontas e, entre elas, a mais perto de cada sexto.
    Cabelo escuro também forma colunas escuras, por isso não dá para pegar todas."""
    cols = [c for c in colunas_da_moldura(img) if c[1] - c[0] <= 8]
    a, b = cols[0][0], cols[-1][0]
    linhas = []
    for i in range(7):
        alvo = a + (b - a) * i / 6
        linhas.append(min(cols, key=lambda c: abs(c[0] - alvo)))
    return linhas


def em_quadrado(sprite: Image.Image, lado: int) -> Image.Image:
    q = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    s = sprite.copy()
    s.thumbnail((lado, lado), Image.LANCZOS)
    q.paste(s, ((lado - s.width) // 2, lado - s.height), s)
    return q


def main() -> None:
    fichas = sorted(glob.glob(os.path.join(ORIGEM, "*.png")))
    if len(fichas) != len(NOMES):
        sys.exit("Esperava %d fichas em %s, achei %d" % (len(NOMES), ORIGEM, len(fichas)))
    os.makedirs(DESTINO, exist_ok=True)
    for nome, arq in zip(NOMES, fichas):
        img = Image.open(arq)
        corpo = recortar(img, CORPO, linha_do_chao(img))
        esc = ALTURA_CORPO / corpo.height
        corpo = corpo.resize((max(1, round(corpo.width * esc)), ALTURA_CORPO), Image.LANCZOS)
        corpo.save(os.path.join(DESTINO, nome.lower() + "_corpo.png"))

        cols = linhas_da_moldura(img)
        atlas = Image.new("RGBA", (LADO_ROSTO * 6, LADO_ROSTO), (0, 0, 0, 0))
        for i in range(6):
            x0, x1 = cols[i][1] + 5, cols[i + 1][0] - 5
            rosto = recortar(img, (x0, FAIXA_ROSTOS[0] + 8, x1, FAIXA_ROSTOS[1] - 2))
            atlas.paste(em_quadrado(rosto, LADO_ROSTO), (i * LADO_ROSTO, 0))
        atlas.save(os.path.join(DESTINO, nome.lower() + "_rostos.png"))
        print(nome, corpo.size, "ok")


if __name__ == "__main__":
    main()
