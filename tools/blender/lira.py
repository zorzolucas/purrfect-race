"""Lira v0.3, a garota de referência em 3D low-poly (fichas conceituais em arte/animações/).

Segue o pipeline do PDF em arte/ (estilo chunky retrô): volumes simples, pernas de 5 lados,
pescoço de 3 lados, mão em luva, cabelo em capacete com espetos e franja assimétrica,
textura pintada com a sombra (material sem luz), íris separadas presas a ossos de olho,
rosto 2D trocável por atlas, pesos chapados por parte e animações a 30 fps.

Gera do zero dentro do Blender: malha, textura pintada (atlas 512 × 512 com paleta e
regiões pintadas por parte), atlas de expressões, íris, contorno, esqueleto com orelhas,
rabo e olhos, pesos, animações do Mixamo (tools/blender/retarget_mixamo.py) e o glTF.

Uso (na raiz do repo):
    blender --background --factory-startup --python tools/blender/lira.py -- [--render] [--anims=a,b] [--sem-mixamo]

Saída:
    modelos/lira.glb          modelo para o Godot
    arte/lira.blend           arquivo do Blender para editar à mão
    arte/previa/*.png         prévias renderizadas (só com --render)

Eixos no Blender: Z para cima, a garota olha para -Y, a esquerda dela é +X.
Altura: 1,60 m até o topo do cabelo (o Godot escala para o tamanho da pista).
"""

import math
import os
import sys

import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDER = "--render" in ARGS

# ---------------------------------------------------------------------------
# Paleta (ficha conceitual da Lira)
# ---------------------------------------------------------------------------

PALETA = [
    ("pele", "#F8CDA6"),
    ("laranja", "#F0852E"),        # cabelo, orelhas, rabo
    ("laranja_esc", "#B5461C"),    # rajadas
    ("creme", "#F8E2BF"),
    ("preto", "#2A2730"),          # top e short
    ("branco", "#F3EFE7"),         # alças e barras
    ("vermelho", "#D63E2A"),       # jaqueta na cintura
    ("vermelho_esc", "#9C281D"),
    ("sola", "#2E2A33"),
    ("tenis", "#EE7A2A"),          # tênis e munhequeiras
    ("orelha_int", "#F5A9A2"),
    ("brilho", "#FFC890"),         # brilho pintado no cabelo
    ("listra_pele", "#E07C3C"),    # listras de gata na pele
    ("curativo", "#F2DDB2"),
]
COR = {nome: i for i, (nome, _) in enumerate(PALETA)}
SEM_SOMBRA = {"brilho", "orelha_int"}
# luz "pintada" na textura: de frente, de cima e do lado direito dela
LUZ = Vector((-0.45, -0.55, 0.70)).normalized()

# atlas 512 × 512: paleta no canto de cima à esquerda (cor por linha, tom por coluna)
# e regiões pintadas para as partes cilíndricas
ATLAS = 512
PAL_LINHA, PAL_COLUNA = 16, 64
REGIOES = {
    "tronco": (256, 0, 256, 128),
    "perna_L": (256, 128, 128, 128), "perna_R": (384, 128, 128, 128),
    "braco_L": (0, 256, 128, 128), "braco_R": (128, 256, 128, 128),
    "tenis_L": (256, 256, 128, 128), "tenis_R": (384, 256, 128, 128),
    "rabo": (0, 384, 256, 128),
    "saia": (256, 384, 256, 128),
}
META = {}  # dados dos anéis de cada região, para pintar


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def tom_rgb(rgb, tom):
    r, g, b = rgb
    if tom == 0:
        return tuple(min(1.0, c * 1.06 + 0.06) for c in rgb)
    if tom == 2:  # sombra puxada para o rosado/roxo, como em anime
        return (r * 0.84, g * 0.74, b * 0.82)
    if tom == 3:
        return (r * 0.66, g * 0.54, b * 0.68)
    return rgb


def tom_da_luz(d):
    return 0 if d > 0.55 else 1 if d > -0.25 else 2 if d > -0.62 else 3


def uv_da_cor(i, tom=1):
    x = tom * PAL_COLUNA + PAL_COLUNA / 2
    y = i * PAL_LINHA + PAL_LINHA / 2
    return (x / ATLAS, 1.0 - y / ATLAS)


def uv_regiao(nome, u, v):
    x0, y0, w, h = REGIOES[nome]
    x = x0 + 0.5 + u * (w - 1)
    y = y0 + 0.5 + v * (h - 1)
    return (x / ATLAS, 1.0 - y / ATLAS)


# ---------------------------------------------------------------------------
# Construtor de malha
# ---------------------------------------------------------------------------

class Malha:
    def __init__(self):
        self.verts = []
        self.pesos = []
        self.contorno = []   # fator da espessura do contorno por vértice (0 = sem contorno)
        self.faces = []      # (índices, cor da paleta ou None, material, uvs ou None)

    def v(self, p, pesos):
        self.verts.append(Vector(p))
        self.pesos.append(dict(pesos))
        self.contorno.append(1.0)
        return len(self.verts) - 1

    def face(self, idx, cor, para_fora=None, material=0, uvs=None):
        idx = list(idx)
        if para_fora is not None:
            pts = [self.verts[i] for i in idx]
            centro = sum(pts, Vector()) / len(pts)
            n = Vector()
            for a in range(len(pts)):
                n += pts[a].cross(pts[(a + 1) % len(pts)])
            if n.dot(centro - Vector(para_fora)) < 0:
                idx.reverse()
                if uvs:
                    uvs = list(reversed(uvs))
        self.faces.append((idx, cor, material, uvs))


M = Malha()


def mix(a, b, t):
    return a + (b - a) * t


def base_perp(direcao, frente=Vector((0, -1, 0))):
    """Eixos (lado, frente) perpendiculares à direção da peça."""
    d = direcao.normalized()
    f = frente - d * frente.dot(d)
    if f.length < 1e-4:
        f = Vector((0, 0, 1)) - d * d.z
    f.normalize()
    lado = f.cross(d).normalized()
    return lado, f


def anel(centro, direcao, rx, ry, lados, giro=0.0, frente=Vector((0, -1, 0))):
    lado, f = base_perp(direcao, frente)
    pts = [Vector(centro) + lado * math.cos(giro + 2 * math.pi * k / lados) * rx
           + f * math.sin(giro + 2 * math.pi * k / lados) * ry for k in range(lados)]
    return {"pts": pts, "c": Vector(centro), "rx": rx, "ry": ry, "lado": lado, "frente": f,
            "giro": giro, "lados": lados}


def loft(aneis, pesos, cores=None, regiao=None, tampa_ini=True, tampa_fim=True, cor_tampa="pele",
         fechado=True):
    """Tubo entre anéis. Com `regiao`, a UV vai para a região pintada (u em volta, v ao longo)."""
    lados = aneis[0]["lados"]
    idx = [[M.v(p, pesos[i]) for p in a["pts"]] for i, a in enumerate(aneis)]
    centros = [a["c"] for a in aneis]
    if regiao:
        comp = [0.0]
        for a, b in zip(centros, centros[1:]):
            comp.append(comp[-1] + (b - a).length)
        vs = [c / comp[-1] for c in comp]
        META[regiao] = {"v": vs, "c": [tuple(c) for c in centros], "rx": [a["rx"] for a in aneis],
                        "ry": [a["ry"] for a in aneis], "lado": [tuple(a["lado"]) for a in aneis],
                        "frente": [tuple(a["frente"]) for a in aneis], "giro": aneis[0]["giro"],
                        "lados": lados, "fechado": fechado}
    n_faces = lados if fechado else lados - 1
    for i in range(len(aneis) - 1):
        meio = (centros[i] + centros[i + 1]) / 2
        for k in range(n_faces):
            k2 = (k + 1) % lados
            quad = [idx[i][k], idx[i][k2], idx[i + 1][k2], idx[i + 1][k]]
            if regiao:
                u0, u1 = k / n_faces, (k + 1) / n_faces
                uvs = [uv_regiao(regiao, u0, vs[i]), uv_regiao(regiao, u1, vs[i]),
                       uv_regiao(regiao, u1, vs[i + 1]), uv_regiao(regiao, u0, vs[i + 1])]
                M.face(quad, None, meio, uvs=uvs)
            else:
                c = cores[i](k) if callable(cores[i]) else cores[i]
                M.face(quad, COR[c], meio)
    if tampa_ini:
        M.face(idx[0], COR[cor_tampa], centros[0] + (centros[1] - centros[0]))
    if tampa_fim:
        M.face(idx[-1], COR[cor_tampa], centros[-1] - (centros[-1] - centros[-2]))
    return idx


def piramide(base_c, direcao, comp, larg, esp, cor, pesos, frente=None, centro=None):
    """Espeto: base retangular afundada e ponta para fora (cabelo, polegar)."""
    d = direcao.normalized()
    lado, f = base_perp(d, frente or Vector((0, -1, 0)))
    if centro is not None:  # mecha de cabelo: base afundada para o centro da cabeça, sem contorno
        b = Vector(base_c) - (Vector(base_c) - centro).normalized() * 0.035
    else:
        b = Vector(base_c) - d * 0.012
    cantos = [b + lado * sx * larg / 2 + f * sy * esp / 2 for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    ib = [M.v(p, pesos) for p in cantos]
    if centro is not None:
        for i in ib:
            M.contorno[i] = 0.0
    it = M.v(b + d * comp, pesos)
    dentro = b + d * comp * 0.3
    for k in range(4):
        M.face([ib[k], ib[(k + 1) % 4], it], COR[cor], dentro)
    M.face(ib, COR[cor], dentro)


# ---------------------------------------------------------------------------
# Esqueleto (pose A, joelho um pouco para frente e cotovelo para trás, como o PDF pede)
# ---------------------------------------------------------------------------

ANG_BRACO = math.radians(38)
OMBRO_Z = 1.062


def braco_pts(s):
    d = Vector((s * math.sin(ANG_BRACO), 0.0, -math.cos(ANG_BRACO)))
    ombro = Vector((s * 0.148, 0.0, OMBRO_Z))
    cotovelo = ombro + d * 0.20 + Vector((0, 0.012, 0))
    pulso = cotovelo + d * 0.18
    mao = pulso + d * 0.125
    return ombro, cotovelo, pulso, mao, d


def perna_pts(s):
    quadril = Vector((s * 0.085, 0.0, 0.72))
    joelho = Vector((s * 0.088, -0.012, 0.45))
    tornozelo = Vector((s * 0.088, 0.0, 0.20))
    dedos = Vector((s * 0.088, -0.15, 0.05))
    return quadril, joelho, tornozelo, dedos


RABO = [Vector(p) for p in (
    (0, 0.08, 0.74), (0, 0.19, 0.70), (0, 0.29, 0.74), (0, 0.35, 0.85),
    (0, 0.355, 0.97), (0, 0.31, 1.06), (0, 0.24, 1.07))]

CABECA_C = Vector((0, 0.005, 1.322))
CABECA_R = Vector((0.200, 0.180, 0.188))
# a ficha é "chunky": corpo mais largo e grosso para a mesma altura
LARGURA_CORPO = Vector((1.24, 1.2, 1.0))
OSSOS_CABECA = {"head", "ear.L", "ear.R", "eye.L", "eye.R"}

OSSOS = []  # (nome, cabeça, cauda, pai, deforma)


def osso(nome, h, t, pai=None, deforma=True):
    OSSOS.append((nome, Vector(h), Vector(t), pai, deforma))


osso("root", (0, 0, 0), (0, -0.25, 0), None, False)
osso("hips", (0, 0, 0.72), (0, 0, 0.84), "root")
osso("spine", (0, 0, 0.84), (0, 0, 0.97), "hips")
osso("chest", (0, 0, 0.97), (0, 0, 1.10), "spine")
osso("neck", (0, 0, 1.10), (0, 0, 1.20), "chest")
osso("head", (0, 0, 1.20), CABECA_C + Vector((0, 0, 0.19)), "neck")
for _s, _L in ((1, "L"), (-1, "R")):
    _q, _j, _t, _d = perna_pts(_s)
    osso(f"thigh.{_L}", _q, _j, "hips")
    osso(f"shin.{_L}", _j, _t, f"thigh.{_L}")
    osso(f"foot.{_L}", _t, _d, f"shin.{_L}")
    _o, _c, _p, _m, _ = braco_pts(_s)
    osso(f"shoulder.{_L}", (_s * 0.03, -0.01, OMBRO_Z + 0.005), _o, "chest")
    osso(f"upper_arm.{_L}", _o, _c, f"shoulder.{_L}")
    osso(f"forearm.{_L}", _c, _p, f"upper_arm.{_L}")
    osso(f"hand.{_L}", _p, _m, f"forearm.{_L}")
for _i in range(len(RABO) - 1):
    osso(f"tail.{_i + 1:03d}", RABO[_i], RABO[_i + 1], "hips" if _i == 0 else f"tail.{_i:03d}")

# ---------------------------------------------------------------------------
# Corpo
# ---------------------------------------------------------------------------

G8 = math.pi / 8   # 8 lados com uma face reta na frente
G5 = 0.3 * math.pi  # 5 lados com uma face reta na frente


def tronco():
    perfil = [  # (z, rx, ry, desloc_y, pesos)
        (0.62, 0.095, 0.070, 0.000, {"hips": 1}),
        (0.68, 0.142, 0.094, 0.000, {"hips": 1}),
        (0.755, 0.152, 0.098, 0.000, {"hips": 1}),
        (0.84, 0.118, 0.082, 0.000, {"hips": 0.5, "spine": 0.5}),
        (0.92, 0.124, 0.084, -0.003, {"spine": 1}),
        (0.99, 0.138, 0.094, -0.012, {"chest": 1}),
        (1.055, 0.146, 0.088, -0.006, {"chest": 1}),
        (1.10, 0.105, 0.072, 0.000, {"chest": 1}),
        (1.12, 0.060, 0.050, 0.000, {"chest": 1}),
    ]
    aneis = [anel((0, dy, z), Vector((0, 0, 1)), rx, ry, 8, G8) for z, rx, ry, dy, _ in perfil]
    loft(aneis, [p[4] for p in perfil], regiao="tronco", cor_tampa="preto")


def pescoco():
    # prisma de 3 lados, como no PDF (uma face para a frente)
    aneis = [anel((0, 0.004, z), Vector((0, 0, 1)), 0.05, 0.05, 3, math.pi / 2 + math.pi / 3)
             for z in (1.09, 1.23)]
    loft(aneis, [{"neck": 1}, {"neck": 0.4, "head": 0.6}], ["pele"], tampa_ini=False, tampa_fim=False)


def perna(s):
    L = "L" if s > 0 else "R"
    q, j, t, _ = perna_pts(s)
    coxa, canela = f"thigh.{L}", f"shin.{L}"
    perfil = [
        (Vector((s * 0.085, 0.0, 0.75)), 0.075, {coxa: 1}),
        (Vector((s * 0.087, 0.0, 0.64)), 0.074, {coxa: 1}),
        (Vector((s * 0.087, -0.005, 0.55)), 0.062, {coxa: 1}),
        (j, 0.052, {coxa: 0.5, canela: 0.5}),
        (Vector((s * 0.088, -0.006, 0.39)), 0.055, {canela: 1}),
        (Vector((s * 0.088, 0.008, 0.31)), 0.056, {canela: 1}),
        (Vector((s * 0.088, 0.002, 0.24)), 0.043, {canela: 1}),
        (t, 0.040, {canela: 1}),
    ]
    aneis = [anel(p, Vector((0, 0, -1)), r, r, 5, G5) for p, r, _ in perfil]
    loft(aneis, [p[2] for p in perfil], regiao=f"perna_{L}")


def tenis(s):
    L = "L" if s > 0 else "R"
    canela, pe = f"shin.{L}", f"foot.{L}"
    x = s * 0.088
    # cano alto do tênis (cor sólida da paleta)
    cano = [anel((x, 0.01, z), Vector((0, 0, 1)), r, r * 0.95, 8, G8) for z, r in ((0.12, 0.066), (0.215, 0.07))]
    loft(cano, [{canela: 0.4, pe: 0.6}, {canela: 1}], ["tenis"], tampa_ini=False, tampa_fim=False)
    # corpo do tênis: grande e arredondado, pintado (sola, biqueira e faixa creme)
    perfil = [  # (y, meia largura, meia altura, z do centro)
        (0.095, 0.068, 0.062, 0.072), (0.055, 0.094, 0.092, 0.097), (-0.045, 0.097, 0.083, 0.087),
        (-0.135, 0.085, 0.064, 0.067), (-0.195, 0.062, 0.042, 0.047)]
    aneis = [anel((x, y, z), Vector((0, -1, 0)), rx, rz, 8, G8, frente=Vector((0, 0, 1)))
             for y, rx, rz, z in perfil]
    loft(aneis, [{canela: 0.3, pe: 0.7}] + [{pe: 1}] * 4, regiao=f"tenis_{L}", cor_tampa="tenis")


def braco(s):
    L = "L" if s > 0 else "R"
    o, c, p, m, d = braco_pts(s)
    ua, fa, ha = f"upper_arm.{L}", f"forearm.{L}", f"hand.{L}"
    perfil = [
        (o - d * 0.03, 0.050, {ua: 1}), (o + d * 0.05, 0.048, {ua: 1}), (c - d * 0.03, 0.041, {ua: 1}),
        (c, 0.039, {ua: 0.5, fa: 0.5}), (c + d * 0.04, 0.043, {fa: 1}), (p - d * 0.03, 0.038, {fa: 1}),
        (p, 0.036, {fa: 0.6, ha: 0.4})]
    aneis = [anel(pt, d, r, r, 6, 0.0) for pt, r, _ in perfil]
    loft(aneis, [x[2] for x in perfil], regiao=f"braco_{L}")
    # munhequeira laranja, bem marcada
    mun = [anel(p + d * k, d, 0.05, 0.05, 6, 0.0) for k in (-0.045, 0.0)]
    loft(mun, [{fa: 1}, {fa: 0.7, ha: 0.3}], ["tenis"], cor_tampa="tenis")
    # mão em luva (sem dedos), como no PDF: bloco afunilado + polegar em cunha
    fino = Vector((0, -1, 0)).cross(d).normalized()  # espessura da palma
    frente = Vector((0, -1, 0))
    blocos = [(p + d * 0.005, 0.034, 0.048), (p + d * 0.05, 0.045, 0.066), (p + d * 0.11, 0.042, 0.062),
              (m + d * 0.02, 0.026, 0.040)]
    aneis = []
    for pt, e, w in blocos:
        pts = [pt + fino * math.cos(2 * math.pi * k / 6) * e + frente * math.sin(2 * math.pi * k / 6) * w
               for k in range(6)]
        aneis.append({"pts": pts, "c": pt, "rx": e, "ry": w, "lado": fino, "frente": frente, "giro": 0, "lados": 6})
    loft(aneis, [{ha: 1}] * 4, ["pele"] * 3)
    polegar = p + d * 0.045 + frente * 0.05
    piramide(polegar, (frente * 0.8 + d * 0.6), 0.06, 0.04, 0.034, "pele", {ha: 1}, frente=Vector((0, 0, 1)))


def jaqueta():
    """Jaqueta vermelha amarrada na cintura: faixa, mangas com nó e a 'saia' aberta na frente."""
    faixa = [anel((0, 0, z), Vector((0, 0, 1)), rx, ry, 8, G8) for z, rx, ry in ((0.835, 0.158, 0.106), (0.885, 0.142, 0.098))]
    loft(faixa, [{"hips": 1}, {"hips": 0.5, "spine": 0.5}], ["vermelho"], tampa_ini=False, tampa_fim=False)
    # saia: só costas e lados (a frente fica aberta mostrando o short)
    lados = 11
    abertura = 0.8
    a0 = math.pi / 2 + abertura
    perfil = [(0.865, 0.160, 0.108), (0.76, 0.182, 0.128), (0.60, 0.205, 0.150)]
    aneis = []
    for z, rx, ry in perfil:
        pts = []
        for k in range(lados + 1):
            a = a0 + (2 * math.pi - 2 * abertura) * k / lados
            pts.append(Vector((-math.cos(a) * rx, -math.sin(a) * ry, z)))
        aneis.append({"pts": pts, "c": Vector((0, 0, z)), "rx": rx, "ry": ry, "lado": Vector((-1, 0, 0)),
                      "frente": Vector((0, -1, 0)), "giro": a0, "lados": lados + 1})
    pesos_barra = []
    for p in aneis[2]["pts"]:
        lado_coxa = "thigh.L" if p.x > 0 else "thigh.R"
        w = min(0.45, abs(p.x) * 2.5)
        pesos_barra.append({"hips": 1 - w, lado_coxa: w} if w > 0.05 else {"hips": 1})
    idx = loft(aneis, [{"hips": 1}, {"hips": 1}, {"hips": 1}], regiao="saia", tampa_ini=False, tampa_fim=False,
               fechado=False)
    for i, pw in zip(idx[2], pesos_barra):
        M.pesos[i] = pw
    # mangas cruzando na frente e o nó
    no = Vector((0.0, -0.125, 0.85))
    for s in (1, -1):
        L = "L" if s > 0 else "R"
        caminho = [Vector((s * 0.15, -0.06, 0.865)), no + Vector((s * 0.012, 0, 0)), Vector((s * 0.05, -0.118, 0.67))]
        aneis = [anel(pt, caminho[min(i + 1, 2)] - caminho[max(i - 1, 0)], 0.03, 0.022, 6, 0.0)
                 for i, pt in enumerate(caminho)]
        loft(aneis, [{"hips": 1}, {"hips": 1}, {"hips": 0.6, f"thigh.{L}": 0.4}],
             ["vermelho", "vermelho_esc" if s > 0 else "vermelho"], cor_tampa="creme")
    # o nó em si
    nos = [anel(no + Vector((0, 0, dz)), Vector((0, 0, 1)), 0.035, 0.024, 6, 0.0) for dz in (-0.02, 0.02)]
    loft(nos, [{"hips": 1}] * 2, ["vermelho_esc"], cor_tampa="vermelho")


def rabo():
    """Grosso, laranja com anéis escuros e ponta clara, em ponto de interrogação."""
    pts, pesos, raios = [], [], []
    n = len(RABO)
    for i in range(n):
        ossos = [f"tail.{i:03d}"] if i > 0 else []
        if i < n - 1:
            ossos.append(f"tail.{i + 1:03d}")
        pts.append(RABO[i])
        pesos.append({o: 1.0 / len(ossos) for o in ossos})
        raios.append(mix(0.050, 0.040, i / (n - 1)))
        if i < n - 1:
            pts.append((RABO[i] + RABO[i + 1]) / 2)
            pesos.append({f"tail.{i + 1:03d}": 1.0})
            raios.append(mix(0.050, 0.040, (i + 0.5) / (n - 1)))
    tang = (RABO[-1] - RABO[-2]).normalized()
    pts.append(RABO[-1] + tang * 0.04)
    pesos.append({f"tail.{n - 1:03d}": 1.0})
    raios.append(0.022)
    aneis = []
    for i, p in enumerate(pts):
        a = pts[max(0, i - 1)]
        b = pts[min(len(pts) - 1, i + 1)]
        aneis.append(anel(p, b - a, raios[i], raios[i], 6, 0.0, frente=Vector((1, 0, 0))))
    loft(aneis, pesos, regiao="rabo", cor_tampa="laranja")


# ---------------------------------------------------------------------------
# Cabeça, rosto, íris, orelhas e cabelo
# ---------------------------------------------------------------------------

def esfera(centro, raios, segs, lat, deform=None):
    """Elipsoide low-poly: devolve (pontos, faces) com polos únicos."""
    pts = [Vector((0, 0, -1))]
    for i in range(1, lat):
        phi = -math.pi / 2 + math.pi * i / lat
        for k in range(segs):
            th = 2 * math.pi * k / segs + math.pi / segs
            pts.append(Vector((math.cos(phi) * math.sin(th), -math.cos(phi) * math.cos(th), math.sin(phi))))
    pts.append(Vector((0, 0, 1)))
    out = []
    for p in pts:
        q = Vector((p.x * raios.x, p.y * raios.y, p.z * raios.z))
        if deform:
            q = deform(q)
        out.append(Vector(centro) + q)
    faces = []
    topo = len(pts) - 1
    for k in range(segs):
        faces.append([0, 1 + (k + 1) % segs, 1 + k])
    for i in range(lat - 2):
        a, b = 1 + i * segs, 1 + (i + 1) * segs
        for k in range(segs):
            k2 = (k + 1) % segs
            faces.append([a + k, a + k2, b + k2, b + k])
    a = 1 + (lat - 2) * segs
    for k in range(segs):
        faces.append([a + k, a + (k + 1) % segs, topo])
    return out, faces


def queixo(q):
    """Rosto reto como em anime, queixo pontudo e bochechas que afinam embaixo."""
    if q.y < 0:
        q = Vector((q.x, q.y * 0.88, q.z))
    if q.z < 0:
        baixo = -q.z / CABECA_R.z
        frente = max(0.0, -q.y / CABECA_R.y)
        q = Vector((q.x * (1 - 0.45 * baixo * (0.4 + 0.6 * frente)),
                    q.y * (1 - 0.18 * baixo) - 0.014 * baixo * frente,
                    q.z * (1 + 0.08 * frente)))
    return q


CABECA_PTS = []
CABECA_FACES = []


def cabeca():
    pts, faces = esfera(CABECA_C, CABECA_R, 12, 8, queixo)
    idx = [M.v(p, {"head": 1}) for p in pts]
    for f in faces:
        M.face([idx[i] for i in f], COR["pele"], CABECA_C)
    CABECA_PTS.extend(pts)
    CABECA_FACES.extend(faces)


ROSTO_YAW = math.radians(56)
ROSTO_Z = (CABECA_C.z - 0.152, CABECA_C.z + 0.076)
ATLAS_COLS, ATLAS_ROWS, ATLAS_CEL = 3, 2, 128
EXPRESSOES = ["normal", "fechados", "feliz", "surpresa", "tonta", "piscadinha"]
OLHOS_PX = [(37, 62), (91, 62)]   # olho direito dela (x menor) e esquerdo, na célula de 128
OLHO_RX, OLHO_RY = 16.5, 25.0     # olhos grandes como na ficha


def _bvh_cabeca():
    return BVHTree.FromPolygons(CABECA_PTS, CABECA_FACES)


def _no_rosto(bvh, s, t, afasta):
    yaw = mix(-ROSTO_YAW, ROSTO_YAW, s)
    z = mix(ROSTO_Z[0], ROSTO_Z[1], t)
    alvo = Vector((math.sin(yaw), -math.cos(yaw), 0)) * 0.3 + Vector((0, 0, z))
    origem = Vector((0, 0.03, z))
    d = (alvo - origem).normalized()
    hit, normal, _, _ = bvh.ray_cast(origem, d, 1.0)
    return hit + normal * afasta, normal


def rosto():
    bvh = _bvh_cabeca()
    nx, nz = 12, 8
    grade = []
    for j in range(nz + 1):
        t = j / nz
        linha = []
        for i in range(nx + 1):
            s = i / nx
            p, _ = _no_rosto(bvh, s, t, 0.006)
            linha.append((M.v(p, {"head": 1}), s, t))
        grade.append(linha)
    for j in range(nz):
        for i in range(nx):
            cel = [grade[j][i], grade[j][i + 1], grade[j + 1][i + 1], grade[j + 1][i]]
            uvs = [(s / ATLAS_COLS, 1.0 - (1.0 - t) / ATLAS_ROWS) for _, s, t in cel]
            M.face([c[0] for c in cel], None, CABECA_C, material=1, uvs=uvs)
            for c in cel:
                M.contorno[c[0]] = 0.0


def iris():
    """Íris separadas (PDF §6.1): placas na frente da esclera, presas aos ossos eye.L/eye.R."""
    bvh = _bvh_cabeca()
    for (px, py), L, mat in zip(OLHOS_PX, ("R", "L"), (2, 3)):
        s_c = px / ATLAS_CEL
        t_c = 1.0 - py / ATLAS_CEL
        ds = OLHO_RX * 0.80 / ATLAS_CEL
        dt = OLHO_RY * 0.80 / ATLAS_CEL
        pesos = {f"eye.{L}": 1}
        n = 3  # grade 3 × 3 para acompanhar a curva do rosto
        grade = [[M.v(_no_rosto(bvh, s_c + ds * (2 * i / n - 1), t_c + dt * (2 * j / n - 1), 0.013)[0], pesos)
                  for i in range(n + 1)] for j in range(n + 1)]
        for j in range(n):
            for i in range(n):
                ids = [grade[j][i], grade[j][i + 1], grade[j + 1][i + 1], grade[j + 1][i]]
                uvs = [(i / n, j / n), ((i + 1) / n, j / n), ((i + 1) / n, (j + 1) / n), (i / n, (j + 1) / n)]
                M.face(ids, None, CABECA_C, material=mat, uvs=uvs)
                for k in ids:
                    M.contorno[k] = 0.0
        centro, normal = _no_rosto(bvh, s_c, t_c, 0.0)
        osso(f"eye.{L}", centro - normal * 0.09, centro, "head")


def orelha(s):
    """Orelha grande e pontuda, virada para a frente. A esquerda tem o entalhe."""
    L = "L" if s > 0 else "R"
    w, h = 0.13, 0.155
    if s > 0:
        contorno = [(-0.5, 0.0), (0.5, 0.0), (0.16, 0.74), (0.03, 0.76), (0.08, 0.86), (0.0, 1.0)]
    else:
        contorno = [(-0.5, 0.0), (0.5, 0.0), (0.0, 1.0)]
    base = CABECA_C + Vector((s * 0.105, 0.025, 0.150))
    cima = Matrix.Rotation(math.radians(-s * 18), 3, "Y") @ Matrix.Rotation(math.radians(-6), 3, "X") @ Vector((0, 0, 1))
    frente = Vector((0, -1, 0))
    frente = (frente - cima * frente.dot(cima)).normalized()
    fora = Vector((1, 0, 0))
    fora = (fora - frente * fora.dot(frente)).normalized()

    def P(x, y, prof):
        return base + fora * (x * s * w) + cima * (y * h) + frente * prof

    pesos = {f"ear.{L}": 1}
    esp = lambda y: 0.016 * (1 - y) + 0.002
    fr = [M.v(P(x, y, esp(y)), pesos) for x, y in contorno]
    tr = [M.v(P(x, y, -esp(y)), pesos) for x, y in contorno]
    centro_f = M.v(P(0, 0.05, esp(0)), pesos)
    centro_t = M.v(P(0, 0.05, -esp(0)), pesos)
    dentro = P(0, 0.3, 0)
    n = len(contorno)
    for k in range(n):
        k2 = (k + 1) % n
        M.face([centro_f, fr[k], fr[k2]], COR["laranja"], dentro)
        M.face([centro_t, tr[k2], tr[k]], COR["laranja"], dentro)
        M.face([fr[k], tr[k], tr[k2], fr[k2]], COR["laranja"], dentro)
    interno = [(-0.32, 0.10), (0.32, 0.10), (0.0, 0.74)]
    ii = [M.v(P(x, y, esp(y) + 0.003), pesos) for x, y in interno]
    M.face(ii, COR["orelha_int"], P(0, 0.3, -0.05))
    osso(f"ear.{L}", base, base + cima * h, "head")


CAP_ESC = 1.15


def ponto_cranio(yaw_graus, z_rel, extra=0.0, esc=CAP_ESC):
    yaw = math.radians(yaw_graus)
    r = CABECA_R * esc
    zz = max(-0.999, min(0.999, z_rel / r.z))
    c = math.sqrt(1 - zz * zz)
    return CABECA_C + Vector((math.sin(yaw) * c * (r.x + extra), -math.cos(yaw) * c * (r.y + extra), z_rel))


def mecha(base, ponta, larg, esp, cor, pesos, frente):
    piramide(base, ponta - base, (ponta - base).length + 0.035, larg, esp, cor, pesos, frente=frente, centro=CABECA_C)


def cabelo():
    """Capacete de cabelo com espetos (PDF §2.5): calota, franja assimétrica, laterais abertas,
    nuca e espetado atrás, com o 'M' das rajadas em V na testa."""
    pesos = {"head": 1}
    R = CABECA_R
    raios = R * CAP_ESC
    pts, faces = esfera(CABECA_C + Vector((0, 0.008, 0.01)), raios, 16, 10)
    usados = {}

    def limite(y_norm):
        if y_norm < -0.76:
            return 0.32 * R.z
        if y_norm < -0.5:
            return mix(0.32, -0.72, (y_norm + 0.76) / 0.26) * R.z
        if y_norm < 0.15:
            return -0.72 * R.z
        return mix(-0.72, -0.60, (y_norm - 0.15) / 0.85) * R.z

    for f in faces:
        c = sum((pts[i] for i in f), Vector()) / len(f)
        rel = c - CABECA_C
        if rel.z < limite(rel.y / raios.y):
            continue
        idx = []
        for i in f:
            if i not in usados:
                usados[i] = M.v(pts[i], pesos)
            idx.append(usados[i])
        M.face(idx, COR["laranja"], CABECA_C)

    # o "M" das rajadas: um V escuro bem marcado na testa, pintado por cima da calota
    for s in (1, -1):
        trilha = [(s * 62, 0.80), (s * 44, 0.66), (s * 24, 0.50), (s * 4, 0.34)]
        larg = 0.016
        anteriores = None
        for yaw, zr in trilha:
            c = ponto_cranio(yaw, zr * R.z, 0.006)
            cima = (ponto_cranio(yaw, zr * R.z + 0.02, 0.006) - c).normalized()
            par = [M.v(c + cima * larg, pesos), M.v(c - cima * larg, pesos)]
            for i in par:
                M.contorno[i] = 0.0
            if anteriores:
                M.face([anteriores[0], anteriores[1], par[1], par[0]], COR["laranja_esc"], CABECA_C)
            anteriores = par

    # franja assimétrica até a linha dos olhos
    franja = [(-55, 0.050, 0.12, "laranja"), (-31, 0.030, 0.11, "laranja"), (-6, 0.016, 0.10, "laranja_esc"),
              (16, 0.026, 0.11, "laranja"), (37, 0.036, 0.11, "laranja"), (56, 0.052, 0.11, "laranja_esc")]
    for yaw, z_ponta, larg, cor in franja:
        b = ponto_cranio(yaw * 0.8, 0.78 * R.z)
        ponta = ponto_cranio(yaw * 0.95 + 3, z_ponta, 0.02, esc=1.0)
        mecha(b, ponta, larg, 0.032, cor, pesos, (b - CABECA_C).normalized())
    # laterais abertas para fora na altura das bochechas (a silhueta larga da ficha)
    for s in (1, -1):
        for yaw, z_b, z_ponta, abre, larg, cor in ((58, 0.04, -0.14, 0.04, 0.12, "laranja"),
                                                  (76, 0.03, -0.12, 0.07, 0.13, "laranja_esc"),
                                                  (94, 0.02, -0.10, 0.08, 0.13, "laranja"),
                                                  (112, 0.01, -0.08, 0.07, 0.13, "laranja_esc"),
                                                  (84, 0.10, -0.02, 0.07, 0.12, "laranja")):
            b = ponto_cranio(s * yaw, z_b)
            ponta = ponto_cranio(s * (yaw + 6), z_ponta, abre, esc=1.05)
            mecha(b, ponta, larg, 0.034, cor, pesos, (b - CABECA_C).normalized())
    # nuca serrilhada
    for k, yaw in enumerate(range(130, 236, 15)):
        b = ponto_cranio(yaw, -0.25 * R.z)
        ponta = ponto_cranio(yaw, -0.15, 0.06, esc=1.0) + Vector((0, 0.03, 0))
        mecha(b, ponta, 0.09, 0.034, "laranja_esc" if k % 2 else "laranja", pesos, Vector((0, 0, 1)))
    # espetado grande para trás
    for yaw, z, incl, comp, larg, cor in (
            (140, 0.50, 25, 0.15, 0.10, "laranja"), (162, 0.68, 35, 0.17, 0.11, "laranja_esc"),
            (198, 0.68, 35, 0.17, 0.11, "laranja"), (220, 0.50, 25, 0.15, 0.10, "laranja_esc"),
            (150, 0.18, 2, 0.17, 0.11, "laranja_esc"), (180, 0.30, 10, 0.19, 0.12, "laranja"),
            (210, 0.18, 2, 0.17, 0.11, "laranja_esc"), (165, -0.15, -20, 0.15, 0.10, "laranja"),
            (195, -0.15, -20, 0.15, 0.10, "laranja_esc"), (122, 0.30, 10, 0.13, 0.10, "laranja"),
            (238, 0.30, 10, 0.13, 0.10, "laranja"), (180, 0.88, 60, 0.11, 0.09, "laranja_esc"),
            (125, -0.05, -10, 0.12, 0.09, "laranja_esc"), (235, -0.05, -10, 0.12, 0.09, "laranja_esc")):
        b = ponto_cranio(yaw, z * R.z)
        n = (b - CABECA_C).normalized()
        d = (n * 0.8 + Vector((0, 0.75, math.sin(math.radians(incl))))).normalized()
        piramide(b, d, comp, larg, 0.045, cor, pesos, frente=Vector((0, 0, 1)), centro=CABECA_C)
    # brilhos pintados no topo
    for yaw in (-40, 30):
        a = ponto_cranio(yaw - 5, 0.93 * R.z, 0.012)
        b2 = ponto_cranio(yaw + 5, 0.93 * R.z, 0.012)
        c = ponto_cranio(yaw + 2, 0.80 * R.z, 0.014)
        M.face([M.v(a, pesos), M.v(b2, pesos), M.v(c, pesos)], COR["brilho"], CABECA_C)


# ---------------------------------------------------------------------------
# Texturas
# ---------------------------------------------------------------------------

def imagem(nome, arr):
    """arr: (h, w, 4) float, linha 0 em cima."""
    h, w = arr.shape[:2]
    img = bpy.data.images.new(nome, w, h, alpha=True)
    img.pixels.foreach_set(np.flipud(arr).astype(np.float32).ravel())
    img.filepath_raw = os.path.join(RAIZ, "arte", nome + ".png")
    img.file_format = "PNG"
    img.save()
    img.pack()
    return img


def _cor(nome):
    return np.array(hex_rgb(dict(PALETA)[nome]))


def _faixa_listra(S, N, zc, fora, w=0.011, incl=0.025, min_fora=0.2):
    """Listra de gata: traço que afina para os lados, só no lado de fora do membro."""
    f = N @ np.array(fora)
    frente = N @ np.array((0, -1, 0))
    return (f > min_fora) & (np.abs(S[..., 2] - zc - incl * frente) < w * np.clip((f - min_fora) / 0.6, 0, 1))


def pintor_tronco(U, V, S, N):
    z = S[..., 2]
    x = S[..., 0]
    cor = np.zeros(S.shape)
    cor[:] = _cor("pele")
    cor[z < 0.805] = _cor("preto")                              # short
    top = (z > 0.915) & (z < 1.085)
    cor[top] = _cor("preto")                                    # top esportivo
    cor[(z > 0.915) & (z < 0.93)] = _cor("branco")              # barra do top
    alca = (z >= 1.085) & (np.abs(np.abs(x) - 0.07) < 0.014)
    cor[alca] = _cor("branco")
    umbigo = (np.abs(x) < 0.006) & (np.abs(z - 0.86) < 0.008) & (S[..., 1] < 0)
    cor[umbigo] = _cor("listra_pele")
    return cor


def pintor_perna(lado_s, curativo):
    def pintor(U, V, S, N):
        z = S[..., 2]
        cor = np.zeros(S.shape)
        cor[:] = _cor("pele")
        fora = (lado_s, 0, 0)
        for zc in (0.50, 0.36, 0.30):
            cor[_faixa_listra(S, N, zc, fora)] = _cor("listra_pele")
        cor[z > 0.545] = _cor("preto")
        cor[(z > 0.545) & (z < 0.562)] = _cor("branco")          # barra do short
        if curativo:
            frente = N @ np.array((0, -1, 0))
            band = (frente > 0.35) & (np.abs(z - 0.455) < 0.03)
            cor[band] = _cor("curativo")
            cor[band & (np.abs(z - 0.455) < 0.012) & (frente > 0.75)] = _cor("creme")
        return cor
    return pintor


def pintor_braco(lado_s):
    def pintor(U, V, S, N):
        cor = np.zeros(S.shape)
        cor[:] = _cor("pele")
        fora = (lado_s * 0.8, 0.0, 0.6)
        for zc, w in ((1.01, 0.010), (0.975, 0.009), (0.86, 0.009), (0.83, 0.008)):
            cor[_faixa_listra(S, N, zc, fora, w=w, incl=0.02, min_fora=0.15)] = _cor("listra_pele")
        return cor
    return pintor


def pintor_tenis(U, V, S, N):
    z = S[..., 2]
    cor = np.zeros(S.shape)
    cor[:] = _cor("tenis")
    lateral = np.abs(N[..., 0]) > 0.45
    cor[(V > 0.30) & (V < 0.50) & lateral & (z > 0.05) & (z < 0.14)] = _cor("creme")
    cor[(V > 0.70) & (z < 0.115)] = _cor("creme")               # biqueira
    cor[z < 0.042] = _cor("sola")
    return cor


def pintor_rabo(U, V, S, N):
    cor = np.zeros(S.shape)
    cor[:] = _cor("laranja")
    anel_esc = ((V * 7.0) % 1.0 > 0.55) & (V < 0.84)
    cor[anel_esc] = _cor("laranja_esc")
    cor[V > 0.9] = _cor("creme")
    return cor


def pintor_saia(U, V, S, N):
    z = S[..., 2]
    cor = np.zeros(S.shape)
    cor[:] = _cor("vermelho")
    cor[(z > 0.625) & (z < 0.645)] = _cor("creme")
    cor[(z > 0.66) & (z < 0.672)] = _cor("creme")
    return cor


PINTORES = {
    "tronco": pintor_tronco,
    "perna_L": pintor_perna(1, False), "perna_R": pintor_perna(-1, True),
    "braco_L": pintor_braco(1), "braco_R": pintor_braco(-1),
    "tenis_L": pintor_tenis, "tenis_R": pintor_tenis,
    "rabo": pintor_rabo, "saia": pintor_saia,
}


def _sombrear(cor, N):
    d = N @ np.array(tuple(LUZ))
    out = cor.copy()
    luz = d > 0.55
    out[luz] = np.minimum(1.0, cor[luz] * 1.06 + 0.06)
    s1 = (d <= -0.25) & (d > -0.62)
    out[s1] = cor[s1] * np.array((0.84, 0.74, 0.82))
    s2 = d <= -0.62
    out[s2] = cor[s2] * np.array((0.66, 0.54, 0.68))
    return out


def _pintar_regiao(arr, nome):
    x0, y0, w, h = REGIOES[nome]
    m = META[nome]
    ys, xs = np.mgrid[0:h, 0:w].astype(float)
    U = xs / (w - 1)
    V = ys / (h - 1)
    vr = np.array(m["v"])
    j = np.clip(np.searchsorted(vr, V, side="right") - 1, 0, len(vr) - 2)
    t = np.clip((V - vr[j]) / np.maximum(vr[j + 1] - vr[j], 1e-9), 0, 1)[..., None]

    def lerp(lista):
        a = np.array(lista)
        if a.ndim == 1:
            return (a[j] * (1 - t[..., 0]) + a[j + 1] * t[..., 0])[..., None]
        return a[j] * (1 - t) + a[j + 1] * t

    C = lerp(m["c"])
    rx, ry = lerp(m["rx"]), lerp(m["ry"])
    la, fr = lerp(m["lado"]), lerp(m["frente"])
    la /= np.linalg.norm(la, axis=-1, keepdims=True)
    fr /= np.linalg.norm(fr, axis=-1, keepdims=True)
    lados = m["lados"]
    if m["fechado"]:
        a = m["giro"] + 2 * math.pi * U
    else:  # tira aberta (saia): u vai do primeiro ao último ponto
        a = m["giro"] + (2 * math.pi - 2 * 0.8) * U
    a = a[..., None]
    S = C + la * np.cos(a) * rx + fr * np.sin(a) * ry
    N = la * np.cos(a) / rx + fr * np.sin(a) / ry
    N /= np.linalg.norm(N, axis=-1, keepdims=True)
    cor = PINTORES[nome](U, V, S, N)
    arr[y0:y0 + h, x0:x0 + w, :3] = _sombrear(cor, N)
    arr[y0:y0 + h, x0:x0 + w, 3] = 1.0


def textura_atlas():
    arr = np.zeros((ATLAS, ATLAS, 4))
    arr[..., 3] = 1.0
    for i, (_, hx) in enumerate(PALETA):
        for t in range(4):
            arr[i * PAL_LINHA:(i + 1) * PAL_LINHA, t * PAL_COLUNA:(t + 1) * PAL_COLUNA, :3] = tom_rgb(hex_rgb(hx), t)
    for nome in REGIOES:
        if nome in META:
            _pintar_regiao(arr, nome)
    return imagem("lira_textura", arr)


def _ferramentas(tam):
    yy, xx = np.mgrid[0:tam, 0:tam].astype(float) + 0.5

    def elipse(cx, cy, rx, ry):
        return ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1

    def segmento(ax, ay, bx, by, esp):
        px, py = xx - ax, yy - ay
        dx, dy = bx - ax, by - ay
        t = np.clip((px * dx + py * dy) / (dx * dx + dy * dy), 0, 1)
        return (px - t * dx) ** 2 + (py - t * dy) ** 2 <= esp * esp

    def curva(pts, esp):
        m = np.zeros_like(xx, dtype=bool)
        for a, b in zip(pts, pts[1:]):
            m |= segmento(*a, *b, esp)
        return m

    def arco(cx, cy, rx, ry, a0, a1, esp, n=16):
        return curva([(cx + rx * math.cos(a), cy + ry * math.sin(a)) for a in np.linspace(a0, a1, n)], esp)

    return yy, xx, elipse, segmento, curva, arco


def atlas_rosto():
    """Rosto 2D (PDF §6): esclera, cílios, boca e as listras das bochechas. A íris é à parte."""
    W, H = ATLAS_COLS * ATLAS_CEL, ATLAS_ROWS * ATLAS_CEL
    arr = np.zeros((H, W, 4))
    yy, xx, elipse, segmento, curva, arco = _ferramentas(ATLAS_CEL)
    escuro = (*hex_rgb("#2A1A16"), 1)
    branco = (1, 1, 1, 1)
    boca = (*hex_rgb("#7A3A30"), 1)
    lingua = (*hex_rgb("#E8706A"), 1)
    rubor = (*hex_rgb("#F2A0A0"), 0.6)
    listra = (*hex_rgb(dict(PALETA)["listra_pele"]), 1)
    verde = (*hex_rgb("#5DB04A"), 1)
    BOCA = (64, 112)

    def pinta(cel, mask, cor):
        cel[mask] = cor

    def olho_aberto(cel, cx, cy, lado, rx=OLHO_RX, ry=OLHO_RY):
        pinta(cel, elipse(cx, cy, rx, ry), branco)
        borda = elipse(cx, cy, rx + 1.6, ry + 1.6) & ~elipse(cx, cy, rx, ry)
        pinta(cel, borda & (yy > cy), escuro)
        pinta(cel, arco(cx, cy, rx + 1.0, ry + 1.0, math.pi * 1.02, math.pi * 1.98, 2.8), escuro)
        pinta(cel, segmento(cx + (rx + 0.5) * lado, cy - ry * 0.5, cx + (rx + 6) * lado, cy - ry * 0.85, 1.8), escuro)

    def fechado(cel, cx, cy, feliz=False):
        if feliz:  # ^ ^
            pinta(cel, arco(cx, cy + 6, OLHO_RX, OLHO_RY * 0.7, math.pi * 1.1, math.pi * 1.9, 2.8), escuro)
        else:      # olhos calmos fechados, curva para baixo
            pinta(cel, arco(cx, cy - 2, OLHO_RX, OLHO_RY * 0.5, math.pi * 0.1, math.pi * 0.9, 2.6), escuro)

    def piscando(cel, cx, cy, lado):  # > ou <
        pinta(cel, curva([(cx - 11 * lado, cy - 9), (cx + 9 * lado, cy), (cx - 11 * lado, cy + 9)], 2.6), escuro)

    def espiral(cel, cx, cy):
        pinta(cel, elipse(cx, cy, OLHO_RX, OLHO_RY), branco)
        pts = [(cx + (1.5 + 1.9 * a) * math.cos(a) * 0.95, cy + (1.5 + 1.9 * a) * math.sin(a) * 1.25)
               for a in np.linspace(0, 5.5 * math.pi / 1.0, 60)]
        pinta(cel, curva(pts, 1.5) & elipse(cx, cy, OLHO_RX, OLHO_RY), verde)
        borda = elipse(cx, cy, OLHO_RX + 1.6, OLHO_RY + 1.6) & ~elipse(cx, cy, OLHO_RX, OLHO_RY)
        pinta(cel, borda, escuro)

    def sobrancelha(cel, cx, cy, lado, incl=-1):
        pinta(cel, segmento(cx + 13 * lado, cy - 34, cx - 12 * lado, cy - 34 + incl, 2.0), escuro)

    def celula(nome):
        cel = np.zeros((ATLAS_CEL, ATLAS_CEL, 4))
        for (cx, cy), lado in zip(OLHOS_PX, (-1, 1)):
            pinta(cel, elipse(cx + 2 * lado, cy + 32, 10, 4), rubor)
            # listras de gata nas bochechas (3 traços para fora)
            for k in range(3):
                y = cy + 27 + k * 6
                pinta(cel, segmento(cx + (6 + k) * lado, y, cx + (17 + k) * lado, y - 2, 1.4), listra)
        bx, by = BOCA
        olhos = list(zip(OLHOS_PX, (-1, 1)))
        if nome == "normal":
            for (cx, cy), lado in olhos:
                olho_aberto(cel, cx, cy, lado)
                sobrancelha(cel, cx, cy, lado)
            pinta(cel, arco(bx, by - 4, 6, 4, 0.15 * math.pi, 0.85 * math.pi, 1.4), boca)
        elif nome == "fechados":
            for (cx, cy), lado in olhos:
                fechado(cel, cx, cy)
                sobrancelha(cel, cx, cy + 2, lado, -2)
            pinta(cel, arco(bx, by - 4, 5, 3, 0.15 * math.pi, 0.85 * math.pi, 1.4), boca)
        elif nome == "feliz":
            for (cx, cy), lado in olhos:
                fechado(cel, cx, cy, feliz=True)
                sobrancelha(cel, cx, cy - 2, lado, -3)
            m = elipse(bx, by - 3, 10, 8) & (yy >= by - 4)
            pinta(cel, m, boca)
            pinta(cel, elipse(bx, by + 3, 6, 3.5) & m, lingua)
        elif nome == "surpresa":
            for (cx, cy), lado in olhos:
                olho_aberto(cel, cx, cy - 1, lado, rx=OLHO_RX * 1.04, ry=OLHO_RY * 1.06)
                sobrancelha(cel, cx, cy - 6, lado, -3)
            pinta(cel, elipse(bx, by - 1, 3.5, 4.5), boca)
        elif nome == "tonta":
            for (cx, cy), lado in olhos:
                espiral(cel, cx, cy)
                sobrancelha(cel, cx, cy, lado, -4)
            pinta(cel, curva([(bx - 4, by), (bx, by - 4), (bx + 4, by)], 1.4), boca)
        elif nome == "piscadinha":
            (cxd, cyd), (cxe, cye) = OLHOS_PX
            olho_aberto(cel, cxd, cyd, -1)
            sobrancelha(cel, cxd, cyd, -1)
            piscando(cel, cxe, cye, 1)
            sobrancelha(cel, cxe, cye + 3, 1, -3)
            pinta(cel, arco(bx, by - 5, 7, 4, 0.1 * math.pi, 0.9 * math.pi, 1.4), boca)
            pinta(cel, elipse(bx + 2, by + 1, 3.5, 4.5) & (yy > by - 2), lingua)
        return cel

    for i, nome in enumerate(EXPRESSOES):
        c, r = i % ATLAS_COLS, i // ATLAS_COLS
        arr[r * ATLAS_CEL:(r + 1) * ATLAS_CEL, c * ATLAS_CEL:(c + 1) * ATLAS_CEL] = celula(nome)
    return imagem("lira_rosto", arr)


def textura_iris():
    tam = 64
    yy, xx, elipse, segmento, curva, arco = _ferramentas(tam)
    arr = np.zeros((tam, tam, 4))
    c = tam / 2
    fora = elipse(c, c, 29, 31)
    arr[fora] = (*hex_rgb("#2E6B2A"), 1)
    arr[elipse(c, c + 2, 26, 27)] = (*hex_rgb("#7CC85A"), 1)
    arr[elipse(c, c + 2, 26, 27) & (yy < c - 6)] = (*hex_rgb("#3F8A3A"), 1)
    arr[elipse(c, c + 3, 11, 16)] = (*hex_rgb("#17221A"), 1)
    arr[elipse(c - 9, c - 9, 6, 7)] = (1, 1, 1, 1)
    arr[elipse(c + 8, c + 12, 3, 3.5)] = (1, 1, 1, 1)
    return imagem("lira_iris", arr)


def material(nome, img, alpha=False):
    """Material sem luz (PDF §3.2): a cor da textura vai na base e na emissão."""
    mat = bpy.data.materials.new(nome)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    for nome_in in ("Emission Color", "Emission"):
        if nome_in in bsdf.inputs:
            nt.links.new(tex.outputs["Color"], bsdf.inputs[nome_in])
            break
    if "Emission Strength" in bsdf.inputs:
        bsdf.inputs["Emission Strength"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 1.0
    if alpha:
        nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
        try:
            mat.surface_render_method = "DITHERED"
        except (AttributeError, TypeError):
            pass
    return mat


# ---------------------------------------------------------------------------
# Montagem
# ---------------------------------------------------------------------------

def limpar():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    cena = bpy.context.scene
    try:  # PDF §1.2: sem AgX, cor da textura 1:1
        cena.view_settings.view_transform = "Standard"
    except TypeError:
        pass


def normal_face(idx):
    pts = [M.verts[i] for i in idx]
    n = Vector()
    for a in range(len(pts)):
        n += pts[a].cross(pts[(a + 1) % len(pts)])
    return n.normalized() if n.length > 1e-12 else Vector((0, 0, 1))


def tom_da_face(idx, cor):
    nome = PALETA[cor][0]
    if nome in SEM_SOMBRA:
        return 0 if nome == "brilho" else 1
    n = normal_face(idx)
    centro = sum((M.verts[i] for i in idx), Vector()) / len(idx)
    if nome == "pele" and (centro - CABECA_C).length < 0.22 and n.y < -0.25:
        return 1  # rosto chapado
    tom = tom_da_luz(n.dot(LUZ))
    if nome == "pele" and abs(centro.x) < 0.07 and 1.08 < centro.z < CABECA_C.z - 0.12:
        tom = max(tom, 2)  # pescoço na sombra da cabeça
    return tom


def contorno(faces_ok, espessura=0.007):
    """Contorno preto por casco invertido: cópia inflada pelas normais suaves, com as faces viradas."""
    chave = lambda v: (round(v.x, 4), round(v.y, 4), round(v.z, 4))
    soma = {}
    for idx, _, _, _ in faces_ok:
        n = normal_face(idx)
        for i in idx:
            soma[chave(M.verts[i])] = soma.get(chave(M.verts[i]), Vector()) + n
    usados, verts, pesos, faces = {}, [], [], []
    for idx, _, _, _ in faces_ok:
        nova = []
        for i in idx:
            if i not in usados:
                n = soma[chave(M.verts[i])]
                n = n.normalized() if n.length > 1e-9 else Vector()
                usados[i] = len(verts)
                verts.append(M.verts[i] + n * espessura * M.contorno[i])
                pesos.append(M.pesos[i])
            nova.append(usados[i])
        faces.append(list(reversed(nova)))
    me = bpy.data.meshes.new("Lira_Contorno")
    me.from_pydata([tuple(v) for v in verts], [], faces)
    me.update()
    uvc = me.uv_layers.new(name="UVMap")
    for d in uvc.data:
        d.uv = (0.5, 0.5)
    mat = bpy.data.materials.new("Lira_Contorno")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = imagem("lira_contorno", np.full((2, 2, 4), (*hex_rgb("#2A1A16"), 1.0)))
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 1.0
    mat.use_backface_culling = True
    me.materials.append(mat)
    ob = bpy.data.objects.new("Lira_Contorno", me)
    bpy.context.scene.collection.objects.link(ob)
    return ob, pesos


def _alargar_corpo():
    """Alarga x e y de tudo que não é da cabeça (depois de modelar, antes de montar a malha)."""
    for i, v in enumerate(M.verts):
        if not any(o in OSSOS_CABECA for o in M.pesos[i]):
            M.verts[i] = Vector((v.x * LARGURA_CORPO.x, v.y * LARGURA_CORPO.y, v.z))


def montar_malha():
    tronco()
    pescoco()
    for s in (1, -1):
        perna(s)
        tenis(s)
        braco(s)
        orelha(s)
    jaqueta()
    rabo()
    cabeca()
    rosto()
    iris()
    cabelo()
    _alargar_corpo()

    me = bpy.data.meshes.new("Lira")
    me.from_pydata([tuple(v) for v in M.verts], [], [f[0] for f in M.faces])
    me.update()
    uv = me.uv_layers.new(name="UVMap")
    for poly, (idx, cor, mat, uvs) in zip(me.polygons, M.faces):
        poly.material_index = mat
        if uvs is None:
            tom = tom_da_face(idx, cor)
            uvs = [uv_da_cor(cor, tom)] * len(idx)
        for k, li in enumerate(poly.loop_indices):
            uv.data[li].uv = uvs[k]
    img_iris = textura_iris()
    me.materials.append(material("Lira_Textura", textura_atlas()))
    me.materials.append(material("Lira_Rosto", atlas_rosto(), alpha=True))
    me.materials.append(material("Lira_IrisD", img_iris, alpha=True))
    me.materials.append(material("Lira_IrisE", img_iris, alpha=True))
    for p in me.polygons:
        p.use_smooth = False
    ob = bpy.data.objects.new("Lira", me)
    bpy.context.scene.collection.objects.link(ob)
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    print(f"[lira] vértices {len(me.vertices)}  triângulos {tris}")
    fora = {COR["brilho"], COR["orelha_int"]}
    faces_ok = [f for f in M.faces if f[2] == 0 and f[1] not in fora]
    cont, pesos_cont = contorno(faces_ok)
    return ob, cont, pesos_cont


def montar_esqueleto():
    arm = bpy.data.armatures.new("Lira_Rig")
    ob = bpy.data.objects.new("Lira_Rig", arm)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    arm.show_axes = False
    ob.show_in_front = True  # PDF §4.1
    bpy.ops.object.mode_set(mode="EDIT")
    for nome, h, t, pai, deforma in OSSOS:
        eb = arm.edit_bones.new(nome)
        if nome not in OSSOS_CABECA:
            h = Vector((h.x * LARGURA_CORPO.x, h.y * LARGURA_CORPO.y, h.z))
            t = Vector((t.x * LARGURA_CORPO.x, t.y * LARGURA_CORPO.y, t.z))
        eb.head, eb.tail = h, t
        eb.use_deform = deforma
        eb.align_roll(Vector((0, -1, 0)) if abs((t - h).normalized().y) < 0.9 else Vector((0, 0, 1)))
        if pai:
            eb.parent = arm.edit_bones[pai]
            eb.use_connect = (arm.edit_bones[pai].tail - eb.head).length < 1e-4
    bpy.ops.object.mode_set(mode="OBJECT")
    return ob


def pesar(malha, rig, lista_pesos):
    grupos = {}
    for nome, _, _, _, deforma in OSSOS:
        if deforma:
            grupos[nome] = malha.vertex_groups.new(name=nome)
    for i, pw in enumerate(lista_pesos):
        tot = sum(pw.values())
        for nome, w in pw.items():
            grupos[nome].add([i], w / tot, "REPLACE")
    mod = malha.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    malha.parent = rig


# ---------------------------------------------------------------------------
# Animação de reserva (sem os FBX do Mixamo)
# ---------------------------------------------------------------------------

def anim_parada(rig):
    acao = bpy.data.actions.new("parada")
    acao.use_fake_user = True
    if rig.animation_data is None:
        rig.animation_data_create()
    rig.animation_data.action = acao
    N = 60
    for f in range(0, N + 1, 6):
        respira = math.sin(2 * math.pi * f / N)
        for pb in rig.pose.bones:
            pb.rotation_mode = "QUATERNION"
            q = Quaternion()
            if pb.name in ("spine", "chest"):
                m = rig.data.bones[pb.name].matrix_local.to_3x3()
                q = (m.inverted() @ Matrix.Rotation(math.radians(1.5 * respira), 3, "X") @ m).to_quaternion()
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=f + 1)
    acao.frame_range = (1, N + 1)
    return acao


def guardar_acoes(rig, acoes):
    """Cada ação vira uma faixa do NLA, para o glTF exportar todas com o nome certo."""
    ad = rig.animation_data
    for acao in acoes:
        tr = ad.nla_tracks.new()
        tr.name = acao.name
        st = tr.strips.new(acao.name, int(acao.frame_range[0]), acao)
        st.name = acao.name
        tr.mute = True
    ad.action = None


# ---------------------------------------------------------------------------
# Export e prévias
# ---------------------------------------------------------------------------

def exportar(rig):
    os.makedirs(os.path.join(RAIZ, "modelos"), exist_ok=True)
    caminho = os.path.join(RAIZ, "modelos", "lira.glb")
    bpy.ops.object.select_all(action="DESELECT")
    bpy.ops.export_scene.gltf(filepath=caminho, export_format="GLB", export_skins=True, export_animations=True,
                              export_animation_mode="NLA_TRACKS", export_yup=True, export_apply=False,
                              export_texcoords=True, export_normals=True, export_materials="EXPORT")
    print("[lira] exportado:", caminho, os.path.getsize(caminho), "bytes")


def exportar_fbx_mixamo(malha):
    """Malha sozinha (sem rig e sem contorno) em FBX, para subir no Mixamo e baixar animações."""
    caminho = os.path.join(RAIZ, "arte", "lira_para_mixamo.fbx")
    bpy.ops.object.select_all(action="DESELECT")
    malha.select_set(True)
    bpy.context.view_layer.objects.active = malha
    bpy.ops.export_scene.fbx(filepath=caminho, use_selection=True, use_armature_deform_only=True,
                             add_leaf_bones=False, path_mode="COPY", embed_textures=True,
                             use_mesh_modifiers=False)


def _posar_repouso(rig):
    for pb in rig.pose.bones:
        pb.rotation_quaternion = Quaternion()
        pb.location = (0, 0, 0)


def previas(rig):
    _posar_repouso(rig)
    pasta = os.path.join(RAIZ, "arte", "previa")
    os.makedirs(pasta, exist_ok=True)
    cena = bpy.context.scene
    cena.render.engine = "BLENDER_WORKBENCH"
    sh = cena.display.shading
    sh.light = "FLAT"
    sh.show_backface_culling = True
    sh.color_type = "TEXTURE"
    sh.show_object_outline = False
    sh.show_cavity = False
    cena.render.resolution_x = 900
    cena.render.resolution_y = 1100
    cena.world = bpy.data.worlds.new("Fundo")
    cam_d = bpy.data.cameras.new("Cam")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = 1.9
    cam = bpy.data.objects.new("Cam", cam_d)
    cena.collection.objects.link(cam)
    cena.camera = cam
    alvo = Vector((0, 0.05, 0.82))

    def foto(nome, d, centro=alvo, escala=1.9, res=(900, 1100)):
        d = Vector(d).normalized()
        cam_d.ortho_scale = escala
        cena.render.resolution_x, cena.render.resolution_y = res
        cam.location = centro + d * 4
        cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
        cena.render.filepath = os.path.join(pasta, f"{nome}.png")
        bpy.ops.render.render(write_still=True)

    for nome, d in {"frente": (0, -1, 0.02), "lado": (1, 0, 0.02), "tres_quartos": (0.7, -0.7, 0.15),
                    "costas": (-0.4, 1, 0.1)}.items():
        foto(nome, d)
    foto("rosto", (0.2, -1, 0.05), CABECA_C + Vector((0, 0, 0.03)), 0.62, (700, 700))
    ad = rig.animation_data
    if ad and any(t.name == "correr" for t in ad.nla_tracks):
        for tr in ad.nla_tracks:
            tr.mute = tr.name != "correr"
        cena.frame_set(6)
        foto("correndo", (1, -0.35, 0.1))
        for tr in ad.nla_tracks:
            tr.mute = True
        cena.frame_set(1)
    bpy.data.objects.remove(cam)


def main():
    limpar()
    os.makedirs(os.path.join(RAIZ, "arte"), exist_ok=True)
    malha, cont, pesos_cont = montar_malha()
    rig = montar_esqueleto()
    pesar(malha, rig, M.pesos)
    pesar(cont, rig, pesos_cont)
    bpy.context.scene.render.fps = 30  # PDF §7.1
    pasta_mixamo = os.path.join(RAIZ, "arte", "animações")
    if os.path.isdir(pasta_mixamo) and "--sem-mixamo" not in ARGS:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import retarget_mixamo
        lista = retarget_mixamo.ANIMACOES
        so = [a for a in ARGS if a.startswith("--anims=")]
        if so:
            nomes = so[0].split("=", 1)[1].split(",")
            lista = {k: v for k, v in lista.items() if k in nomes}
        acoes = retarget_mixamo.retargetar_tudo(rig, pasta_mixamo, lista)
    else:
        acoes = [anim_parada(rig)]
    guardar_acoes(rig, acoes)
    exportar(rig)
    exportar_fbx_mixamo(malha)
    if RENDER:
        previas(rig)
    _posar_repouso(rig)
    bpy.context.scene.display.shading.color_type = "TEXTURE"
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(RAIZ, "arte", "lira.blend"), compress=True)
    print("[lira] ok")


main()
