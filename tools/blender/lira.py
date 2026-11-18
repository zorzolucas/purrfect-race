"""Lira, a garota de referência em 3D low-poly (GDD §11, visual-elenco §4.1).

Gera do zero, dentro do Blender: malha low-poly com cor por paleta, atlas de expressões
do rosto, esqueleto com ossos de orelha e rabo, pesos, animações (parada e correr) e
exporta tudo em glTF para o Godot.

Uso (na raiz do repo):
    blender --background --factory-startup --python tools/blender/lira.py -- [--render]

Saída:
    modelos/lira.glb          modelo para o Godot
    arte/lira.blend           arquivo do Blender para editar à mão
    arte/previa/*.png         prévias renderizadas (só com --render)

Eixos no Blender: Z para cima, a garota olha para -Y, a esquerda dela é +X.
Altura: 1,60 m (o Godot escala para o tamanho da pista).
"""

import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDER = "--render" in ARGS

# ---------------------------------------------------------------------------
# Paleta (visual-elenco §2, pelagem 1: laranja rajada)
# ---------------------------------------------------------------------------

PALETA = [
    ("pele", "#F6D7BE"),
    ("laranja", "#E8833A"),        # base da pelagem
    ("laranja_esc", "#B8541E"),    # rajadas
    ("creme", "#F6D2A8"),          # detalhe: ponta do rabo
    ("camisa", "#F4F4F0"),
    ("short", "#2B2F4A"),
    ("tenis", "#F2F2F2"),
    ("sola", "#3A3A44"),
    ("jaqueta", "#3E6FB0"),
    ("munhequeira", "#F08A24"),
    ("curativo", "#E9CF9E"),
    ("orelha_int", "#F2A9A0"),
    ("meia", "#FFFFFF"),
    ("estrela", "#F2C230"),
    ("jaqueta_esc", "#2D528A"),
    ("boca", "#7A3A30"),
]
COR = {nome: i for i, (nome, _) in enumerate(PALETA)}
CELULAS = 4  # 4 × 4 cores
PX_CELULA = 4


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def uv_da_cor(i):
    cx, cy = i % CELULAS, i // CELULAS
    # linha 0 em cima da imagem (v alto no Blender)
    return ((cx + 0.5) / CELULAS, 1.0 - (cy + 0.5) / CELULAS)


# ---------------------------------------------------------------------------
# Construtor de malha: tudo vai para uma malha só, com cor e pesos por parte
# ---------------------------------------------------------------------------

class Malha:
    def __init__(self):
        self.verts = []      # Vector
        self.pesos = []      # {osso: peso}
        self.faces = []      # (índices, cor, material, uvs ou None)

    def v(self, p, pesos):
        self.verts.append(Vector(p))
        self.pesos.append(dict(pesos))
        return len(self.verts) - 1

    def face(self, idx, cor, para_fora=None, material=0, uvs=None):
        """para_fora: ponto de dentro da peça; a face é virada para longe dele."""
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
    pts = []
    for k in range(lados):
        a = giro + 2 * math.pi * k / lados
        pts.append(Vector(centro) + lado * math.cos(a) * rx + f * math.sin(a) * ry)
    return pts


def loft(aneis, pesos, cores, tampa_ini=True, tampa_fim=True, cor_tampa=None):
    """aneis: lista de listas de pontos (mesmo nº de lados). cores[i](k) ou nome: faixa i."""
    lados = len(aneis[0])
    idx = [[M.v(p, pesos[i]) for p in a] for i, a in enumerate(aneis)]
    centros = [sum(a, Vector()) / lados for a in aneis]
    for i in range(len(aneis) - 1):
        meio = (centros[i] + centros[i + 1]) / 2
        for k in range(lados):
            k2 = (k + 1) % lados
            c = cores[i](k) if callable(cores[i]) else cores[i]
            M.face([idx[i][k], idx[i][k2], idx[i + 1][k2], idx[i + 1][k]], COR[c], meio)
    if tampa_ini:
        d = centros[1] - centros[0]
        ct = cor_tampa or (cores[0] if not callable(cores[0]) else cores[0](0))
        M.face(idx[0], COR[ct], centros[0] + d)
    if tampa_fim:
        d = centros[-1] - centros[-2]
        ct = cor_tampa or (cores[-1] if not callable(cores[-1]) else cores[-1](0))
        M.face(idx[-1], COR[ct], centros[-1] - d)
    return idx


def piramide(base_c, direcao, comp, larg, esp, cor, pesos, giro=0.0, frente=None, cor_ponta=None):
    """Mecha de cabelo: base retangular afundada no crânio e ponta para fora."""
    d = direcao.normalized()
    frente = frente or Vector((0, -1, 0))
    lado, f = base_perp(d, frente)
    rot = Matrix.Rotation(giro, 3, d)
    lado, f = rot @ lado, rot @ f
    b = Vector(base_c) - d * 0.012
    cantos = [b + lado * sx * larg / 2 + f * sy * esp / 2 for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    ib = [M.v(p, pesos) for p in cantos]
    it = M.v(b + d * comp, pesos)
    dentro = b + d * comp * 0.3
    for k in range(4):
        M.face([ib[k], ib[(k + 1) % 4], it], COR[cor], dentro)
    M.face(ib, COR[cor], dentro)


def mix(a, b, t):
    return a + (b - a) * t


# ---------------------------------------------------------------------------
# Esqueleto (posição de repouso em A)
# ---------------------------------------------------------------------------

SEN, COS = math.sin(math.radians(35)), math.cos(math.radians(35))


def braco_pts(s):
    d = Vector((s * SEN, 0.0, -COS))
    ombro = Vector((s * 0.165, 0.0, 1.29))
    cotovelo = ombro + d * 0.25
    pulso = cotovelo + d * 0.22
    mao = pulso + d * 0.085
    return ombro, cotovelo, pulso, mao, d


def perna_pts(s):
    quadril = Vector((s * 0.085, 0.0, 0.90))
    joelho = Vector((s * 0.085, -0.008, 0.49))
    tornozelo = Vector((s * 0.085, 0.0, 0.085))
    dedos = Vector((s * 0.085, -0.11, 0.03))
    return quadril, joelho, tornozelo, dedos


RABO = [Vector(p) for p in (
    (0, 0.07, 0.90), (0, 0.19, 0.90), (0, 0.295, 0.97), (0, 0.345, 1.08),
    (0, 0.35, 1.195), (0, 0.30, 1.275), (0, 0.23, 1.27))]

CABECA_C = Vector((0, 0.0, 1.515))
CABECA_R = Vector((0.121, 0.124, 0.138))

OSSOS = []  # (nome, cabeça, cauda, pai, deforma)


def osso(nome, h, t, pai=None, deforma=True):
    OSSOS.append((nome, Vector(h), Vector(t), pai, deforma))


osso("root", (0, 0, 0), (0, -0.25, 0), None, False)
osso("hips", (0, 0, 0.90), (0, 0, 1.01), "root")
osso("spine", (0, 0, 1.01), (0, 0, 1.15), "hips")
osso("chest", (0, 0, 1.15), (0, 0, 1.33), "spine")
osso("neck", (0, 0, 1.33), (0, 0, 1.42), "chest")
osso("head", (0, 0, 1.41), (0, 0, 1.66), "neck")
for s, L in ((1, "L"), (-1, "R")):
    q, j, t, dd = perna_pts(s)
    osso(f"thigh.{L}", q, j, "hips")
    osso(f"shin.{L}", j, t, f"thigh.{L}")
    osso(f"foot.{L}", t, dd, f"shin.{L}")
    o, c, p, m, _ = braco_pts(s)
    osso(f"shoulder.{L}", (s * 0.03, -0.01, 1.30), o, "chest")
    osso(f"upper_arm.{L}", o, c, f"shoulder.{L}")
    osso(f"forearm.{L}", c, p, f"upper_arm.{L}")
    osso(f"hand.{L}", p, m, f"forearm.{L}")
for i in range(len(RABO) - 1):
    osso(f"tail.{i + 1:03d}", RABO[i], RABO[i + 1], "hips" if i == 0 else f"tail.{i:03d}")

# ---------------------------------------------------------------------------
# Corpo
# ---------------------------------------------------------------------------

G8 = math.pi / 8  # 8 lados com uma face reta na frente


def tronco():
    # (z, rx, ry, desloc_y, pesos, cor da faixa acima)
    perfil = [
        (0.79, 0.095, 0.070, 0.000, {"hips": 1}, "short"),
        (0.85, 0.145, 0.095, 0.000, {"hips": 1}, "short"),
        (0.93, 0.150, 0.096, 0.000, {"hips": 1}, "short"),
        (1.00, 0.116, 0.080, 0.000, {"hips": 0.5, "spine": 0.5}, "camisa"),
        (1.10, 0.124, 0.085, -0.002, {"spine": 1}, "camisa"),
        (1.20, 0.140, 0.094, -0.012, {"chest": 1}, "camisa"),
        (1.27, 0.150, 0.085, -0.006, {"chest": 1}, "camisa"),
        (1.325, 0.095, 0.068, 0.000, {"chest": 1}, "pele"),
        (1.355, 0.044, 0.042, 0.000, {"neck": 1}, "pele"),
        (1.46, 0.042, 0.042, 0.004, {"neck": 0.4, "head": 0.6}, None),
    ]
    aneis = [anel((0, dy, z), Vector((0, 0, 1)), rx, ry, 8, G8) for z, rx, ry, dy, _, _ in perfil]
    loft(aneis, [p[4] for p in perfil], [p[5] for p in perfil[:-1]], cor_tampa=None)


def perna(s):
    L = "L" if s > 0 else "R"
    q, j, t, _ = perna_pts(s)
    coxa, canela, pe = f"thigh.{L}", f"shin.{L}", f"foot.{L}"
    perfil = [  # (ponto, raio, pesos, cor da faixa abaixo)
        (Vector((s * 0.085, 0.0, 0.93)), 0.070, {coxa: 1}, "short"),
        (Vector((s * 0.088, 0.0, 0.79)), 0.076, {coxa: 1}, "pele"),
        (Vector((s * 0.086, -0.004, 0.62)), 0.062, {coxa: 1}, "pele"),
        (j, 0.047, {coxa: 0.5, canela: 0.5}, "pele"),
        (Vector((s * 0.085, -0.002, 0.41)), 0.049, {canela: 1}, "pele"),
        (Vector((s * 0.085, 0.010, 0.30)), 0.052, {canela: 1}, "pele"),
        (Vector((s * 0.085, 0.004, 0.16)), 0.035, {canela: 1}, "meia"),
        (Vector((s * 0.085, 0.0, 0.085)), 0.034, {canela: 0.5, pe: 0.5}, None),
    ]
    cores = [p[3] for p in perfil[:-1]]
    if s < 0:  # curativo no joelho direito, nas faces da frente
        cores[2] = lambda k: "curativo" if k == 1 else "pele"
    aneis = [anel(p, Vector((0, 0, -1)), r, r, 6, math.pi / 6) for p, r, _, _ in perfil]
    loft(aneis, [p[2] for p in perfil], cores)
    # tênis: loft para a frente
    tenis = [  # (y, meia largura, meia altura, z do centro, pesos)
        (0.045, 0.030, 0.034, 0.052, {canela: 0.3, pe: 0.7}),
        (0.020, 0.043, 0.050, 0.055, {pe: 1}),
        (-0.060, 0.042, 0.040, 0.042, {pe: 1}),
        (-0.125, 0.030, 0.024, 0.030, {pe: 1}),
    ]
    aneis = []
    for y, rx, rz, z, _ in tenis:
        pts = anel((s * 0.085, y, z), Vector((0, -1, 0)), rx, rz, 6, math.pi / 6, frente=Vector((0, 0, 1)))
        aneis.append(pts)
    inicio = len(M.faces)
    loft(aneis, [p[4] for p in tenis], ["tenis"] * 3)
    # sola nas faces viradas para baixo
    for fi in range(inicio, len(M.faces)):
        idx, cor, mat, uvs = M.faces[fi]
        pts = [M.verts[i] for i in idx]
        n = (pts[1] - pts[0]).cross(pts[2] - pts[0]).normalized()
        if abs(n.z) > 0.75 and max(p.z for p in pts) < 0.035:
            M.faces[fi] = (idx, COR["sola"], mat, uvs)


def braco(s):
    L = "L" if s > 0 else "R"
    o, c, p, m, d = braco_pts(s)
    ua, fa, ha = f"upper_arm.{L}", f"forearm.{L}", f"hand.{L}"
    perfil = [
        (o - d * 0.025, 0.043, {ua: 1}, "camisa"),
        (o + d * 0.06, 0.044, {ua: 1}, "pele"),
        (c - d * 0.03, 0.039, {ua: 1}, "pele"),
        (c, 0.035, {ua: 0.5, fa: 0.5}, "pele"),
        (c + d * 0.05, 0.037, {fa: 1}, "pele"),
        (p - d * 0.05, 0.030, {fa: 1}, "munhequeira" if s > 0 else "pele"),
        (p, 0.029, {fa: 0.6, ha: 0.4}, None),
    ]
    aneis = [anel(pt, d, r, r, 6, 0.0) for pt, r, _, _ in perfil]
    loft(aneis, [x[2] for x in perfil], [x[3] for x in perfil[:-1]])
    # mão: achatada, palma para o corpo
    lado = Vector((0, -1, 0)).cross(d).normalized()  # eixo fino
    maos = [(p - d * 0.01, 0.016, 0.028), (p + d * 0.045, 0.018, 0.033), (m, 0.010, 0.020)]
    aneis = []
    for pt, fino, larg in maos:
        pts = []
        for k in range(6):
            a = 2 * math.pi * k / 6
            pts.append(pt + lado * math.cos(a) * fino + Vector((0, 1, 0)) * math.sin(a) * larg)
        aneis.append(pts)
    loft(aneis, [{ha: 1}] * 3, ["pele"] * 2)


def esfera(centro, raios, segs, lat, deform=None):
    """Elipsoide low-poly: devolve (pontos, quads) com polos únicos."""
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
    """Afina o queixo e as bochechas na frente de baixo."""
    if q.y < 0:  # rosto mais reto, como em anime
        q = Vector((q.x, q.y * 0.9, q.z))
    if q.z < 0:
        baixo = -q.z / CABECA_R.z
        frente = max(0.0, -q.y / CABECA_R.y)
        q = Vector((q.x * (1 - 0.42 * baixo * (0.4 + 0.6 * frente)),
                    q.y * (1 - 0.18 * baixo) - 0.012 * baixo * frente,
                    q.z * (1 + 0.10 * frente)))
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


# rosto: decal recortado do atlas de expressões
ROSTO_YAW = math.radians(56)
ROSTO_Z = (1.405, 1.57)
ATLAS_COLS, ATLAS_ROWS, ATLAS_CEL = 3, 2, 128
EXPRESSOES = ["normal", "feliz", "determinada", "cansada", "triste", "surpresa"]


def rosto():
    bvh = BVHTree.FromPolygons(CABECA_PTS, CABECA_FACES)
    nx, nz = 12, 8
    grade = []
    for j in range(nz + 1):
        t = j / nz
        z = mix(ROSTO_Z[0], ROSTO_Z[1], t)
        linha = []
        for i in range(nx + 1):
            s = i / nx
            yaw = mix(-ROSTO_YAW, ROSTO_YAW, s)
            alvo = Vector((math.sin(yaw), -math.cos(yaw), 0)) * 0.3 + Vector((0, 0, z))
            origem = Vector((0, 0.03, z))
            d = (alvo - origem).normalized()
            hit, normal, _, _ = bvh.ray_cast(origem, d, 1.0)
            p = hit + normal * 0.006
            linha.append((M.v(p, {"head": 1}), s, t))
        grade.append(linha)
    for j in range(nz):
        for i in range(nx):
            cel = [grade[j][i], grade[j][i + 1], grade[j + 1][i + 1], grade[j + 1][i]]
            # célula 0 do atlas: canto de cima à esquerda
            uvs = [(s / ATLAS_COLS, 1.0 - (1.0 - t) / ATLAS_ROWS) for _, s, t in cel]
            M.face([c[0] for c in cel], 0, CABECA_C, material=1, uvs=uvs)


def orelha(s):
    """Orelha de gato média e pontuda, virada para a frente. A esquerda tem um entalhe."""
    L = "L" if s > 0 else "R"
    w, h = 0.092, 0.108
    if s > 0:  # entalhe na borda de fora, perto da ponta
        contorno = [(-0.5, 0.0), (0.5, 0.0), (0.16, 0.74), (0.03, 0.76), (0.08, 0.86), (0.0, 1.0)]
    else:
        contorno = [(-0.5, 0.0), (0.5, 0.0), (0.0, 1.0)]
    # quadro local: x para fora, y para cima, n para a frente
    base = CABECA_C + Vector((s * 0.074, 0.014, 0.106))
    cima = Matrix.Rotation(math.radians(-s * 16), 3, "Y") @ Matrix.Rotation(math.radians(-8), 3, "X") @ Vector((0, 0, 1))
    frente = Vector((0, -1, 0))
    frente = (frente - cima * frente.dot(cima)).normalized()
    fora = Vector((1, 0, 0)) - cima * cima.x * s
    fora = (fora - frente * fora.dot(frente)).normalized()

    def P(x, y, prof):
        return base + fora * (x * s * w) + cima * (y * h) + frente * prof

    pesos = {f"ear.{L}": 1}
    esp = lambda y: 0.012 * (1 - y) + 0.002
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
    # parte de dentro rosada
    interno = [(-0.30, 0.10), (0.30, 0.10), (0.0, 0.72)]
    ii = [M.v(P(x, y, esp(y) + 0.003), pesos) for x, y in interno]
    M.face(ii, COR["orelha_int"], P(0, 0.3, -0.05))
    osso(f"ear.{L}", base, base + cima * h, "head")


def ponto_cranio(yaw_graus, z_rel, extra=0.0):
    """Ponto na superfície do cabelo: yaw 0 = frente, 90 = esquerda (+X)."""
    yaw = math.radians(yaw_graus)
    r = CABECA_R * 1.07
    zz = max(-0.999, min(0.999, z_rel / r.z))
    c = math.sqrt(1 - zz * zz)
    return CABECA_C + Vector((math.sin(yaw) * c * (r.x + extra), -math.cos(yaw) * c * (r.y + extra), z_rel))


def cabelo():
    # calota: elipsoide um pouco maior que a cabeça, sem a parte do rosto
    raios = CABECA_R * 1.07 + Vector((0.004, 0.006, 0.006))
    pts, faces = esfera(CABECA_C + Vector((0, 0.004, 0.004)), raios, 12, 8)
    pesos = {"head": 1}
    usados = {}

    def limite(y_norm):
        # testa na frente, mais baixo dos lados e na nuca
        if y_norm < -0.55:
            return 0.045
        if y_norm < 0.2:
            return mix(0.045, -0.035, (y_norm + 0.55) / 0.75)
        return mix(-0.035, -0.085, (y_norm - 0.2) / 0.8)

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
        # rajadas: faixas escuras no topo
        ang = math.degrees(math.atan2(rel.x, -rel.y)) % 360
        cor = "laranja_esc" if (rel.z > 0.06 and int(ang // 30) % 3 == 0) else "laranja"
        M.face(idx, COR[cor], CABECA_C)

    # franja: mechas sobre a testa; o "M" sai das listras escuras alternadas
    franja = [(-46, "laranja", 0.07), (-29, "laranja_esc", 0.065), (-13, "laranja", 0.055),
              (0, "laranja_esc", 0.06), (13, "laranja", 0.055), (29, "laranja_esc", 0.065), (46, "laranja", 0.07)]
    for yaw, cor, comp in franja:
        b = ponto_cranio(yaw, 0.08)
        ponta = ponto_cranio(yaw * 0.95, 0.08 - comp, 0.014)
        piramide(b, ponta - b, (ponta - b).length + 0.012, 0.05, 0.022, cor, pesos,
                  frente=(b - CABECA_C).normalized())
    # mechas dos lados, na frente das orelhas humanas (que não existem: gatas)
    for s in (1, -1):
        b = ponto_cranio(s * 72, 0.03)
        ponta = ponto_cranio(s * 76, -0.075, 0.01)
        piramide(b, ponta - b, (ponta - b).length + 0.012, 0.045, 0.02, "laranja", pesos,
                  frente=(b - CABECA_C).normalized())
    # espetado atrás, como quem acabou de correr
    tras = [(150, 0.07, -15, "laranja"), (180, 0.08, -5, "laranja_esc"), (210, 0.07, -15, "laranja"),
            (125, 0.0, -30, "laranja"), (165, -0.01, -30, "laranja_esc"), (195, -0.01, -30, "laranja"),
            (235, 0.0, -30, "laranja_esc"), (150, -0.07, -50, "laranja"), (180, -0.075, -55, "laranja"),
            (210, -0.07, -50, "laranja_esc"), (110, 0.07, 5, "laranja_esc"), (250, 0.07, 5, "laranja"),
            (160, 0.115, 70, "laranja"), (200, 0.11, 70, "laranja_esc")]
    for yaw, z, incl, cor in tras:
        b = ponto_cranio(yaw, z)
        n = (b - CABECA_C).normalized()
        lado = Vector((n.x, 0, 0)) * 0.8
        d = (n * 0.55 + lado + Vector((0, 0.15, 0)) + Vector((0, 0, math.sin(math.radians(incl)) - 0.15))).normalized()
        piramide(b, d, 0.075 + 0.02 * ((yaw // 15) % 2), 0.06, 0.03, cor, pesos, frente=Vector((0, 0, 1)))


def rabo():
    """Grosso, com anéis escuros e ponta clara, em pé como ponto de interrogação."""
    pts, pesos, raios = [], [], []
    n = len(RABO)
    for i in range(n):
        ossos = []
        if i > 0:
            ossos.append(f"tail.{i:03d}")
        if i < n - 1:
            ossos.append(f"tail.{i + 1:03d}")
        pts.append(RABO[i])
        pesos.append({o: 1.0 / len(ossos) for o in ossos})
        raios.append(mix(0.043, 0.030, i / (n - 1)))
        if i < n - 1:
            pts.append((RABO[i] + RABO[i + 1]) / 2)
            pesos.append({f"tail.{i + 1:03d}": 1.0})
            raios.append(mix(0.043, 0.030, (i + 0.5) / (n - 1)))
    # ponta arredondada
    tang = (RABO[-1] - RABO[-2]).normalized()
    pts.append(RABO[-1] + tang * 0.035)
    pesos.append({f"tail.{n - 1:03d}": 1.0})
    raios.append(0.016)
    aneis = []
    for i, p in enumerate(pts):
        a = pts[max(0, i - 1)]
        b = pts[min(len(pts) - 1, i + 1)]
        aneis.append(anel(p, b - a, raios[i], raios[i], 6, 0.0, frente=Vector((1, 0, 0))))
    cores = []
    for i in range(len(pts) - 1):
        if i >= len(pts) - 3:
            cores.append("creme")
        else:
            cores.append("laranja_esc" if i % 2 == 1 else "laranja")
    loft(aneis, pesos, cores, cor_tampa="laranja")


def jaqueta():
    """Jaqueta do treino amarrada na cintura."""
    # faixa em volta do quadril (aberta, dupla face no Godot)
    perfil = [(0.955, 0.162, 0.108), (1.025, 0.138, 0.095)]
    aneis = [anel((0, 0, z), Vector((0, 0, 1)), rx, ry, 8, G8) for z, rx, ry in perfil]
    loft(aneis, [{"hips": 1}] * 2, ["jaqueta"], tampa_ini=False, tampa_fim=False)
    # mangas cruzando na frente e o nó
    no = Vector((0.0, -0.112, 0.965))
    for s in (1, -1):
        L = "L" if s > 0 else "R"
        ini = Vector((s * 0.135, -0.07, 0.99))
        fim = Vector((s * 0.03, -0.12, 0.80))
        caminho = [ini, no + Vector((s * 0.01, 0, 0)), fim]
        aneis = [anel(p, (caminho[min(i + 1, 2)] - caminho[max(i - 1, 0)]), 0.024, 0.016, 6, 0.0)
                 for i, p in enumerate(caminho)]
        loft(aneis, [{"hips": 1}, {"hips": 1}, {"hips": 0.6, f"thigh.{L}": 0.4}],
             ["jaqueta", "jaqueta_esc" if s > 0 else "jaqueta"])
    # corpo da jaqueta caindo atrás, em duas abas (o rabo passa no meio)
    for s in (1, -1):
        L = "L" if s > 0 else "R"
        topo = [Vector((s * 0.04, 0.10, 0.96)), Vector((s * 0.15, 0.04, 0.96))]
        baixo = [Vector((s * 0.035, 0.125, 0.76)), Vector((s * 0.165, 0.06, 0.78))]
        esp = Vector((0, 0.008, 0))
        pw = [{"hips": 1}, {"hips": 1}, {"hips": 0.5, f"thigh.{L}": 0.5}, {"hips": 0.5, f"thigh.{L}": 0.5}]
        q = [topo[0], topo[1], baixo[1], baixo[0]]
        fora = [M.v(p + esp, w) for p, w in zip(q, pw)]
        dentro = [M.v(p - esp * 0.5, w) for p, w in zip(q, pw)]
        meio = sum(q, Vector()) / 4 - Vector((0, 0.05, 0))
        M.face(fora, COR["jaqueta"], meio)
        M.face(dentro, COR["jaqueta_esc"], meio + Vector((0, 0.2, 0)))
        for k in range(4):
            k2 = (k + 1) % 4
            M.face([fora[k], fora[k2], dentro[k2], dentro[k]], COR["jaqueta"], sum(q, Vector()) / 4)


def estrela_peito():
    """Símbolo da estrela na camisa de corrida (GDD §11.2)."""
    c = Vector((0.06, -0.103, 1.17))
    n = Vector((0, -1, 0.18)).normalized()
    up = Vector((0, 0, 1))
    up = (up - n * up.dot(n)).normalized()
    lado = n.cross(up).normalized()
    centro = M.v(c, {"chest": 1})
    anel_e = []
    for k in range(10):
        r = 0.024 if k % 2 == 0 else 0.010
        a = math.pi / 2 + 2 * math.pi * k / 10
        anel_e.append(M.v(c + lado * math.cos(a) * r + up * math.sin(a) * r, {"chest": 1}))
    for k in range(10):
        M.face([centro, anel_e[k], anel_e[(k + 1) % 10]], COR["estrela"], c - n)


# ---------------------------------------------------------------------------
# Texturas
# ---------------------------------------------------------------------------

def imagem(nome, arr):
    """arr: (h, w, 4) float, linha 0 em cima."""
    h, w = arr.shape[:2]
    img = bpy.data.images.new(nome, w, h, alpha=True)
    img.pixels.foreach_set(np.flipud(arr).astype(np.float32).ravel())
    caminho = os.path.join(RAIZ, "arte", nome + ".png")
    img.filepath_raw = caminho
    img.file_format = "PNG"
    img.save()
    img.pack()
    return img


def textura_paleta():
    n = CELULAS * PX_CELULA
    arr = np.zeros((n, n, 4))
    for i, (_, hx) in enumerate(PALETA):
        cx, cy = i % CELULAS, i // CELULAS
        arr[cy * PX_CELULA:(cy + 1) * PX_CELULA, cx * PX_CELULA:(cx + 1) * PX_CELULA] = (*hex_rgb(hx), 1)
    return imagem("lira_paleta", arr)


def atlas_rosto():
    W, H = ATLAS_COLS * ATLAS_CEL, ATLAS_ROWS * ATLAS_CEL
    arr = np.zeros((H, W, 4))
    yy, xx = np.mgrid[0:ATLAS_CEL, 0:ATLAS_CEL].astype(float) + 0.5

    escuro = (*hex_rgb("#2A1A16"), 1)
    branco = (1, 1, 1, 1)
    iris = (*hex_rgb("#8FD16A"), 1)
    iris_esc = (*hex_rgb("#3F8A3A"), 1)
    pupila = (*hex_rgb("#1D2A1A"), 1)
    boca = (*hex_rgb("#7A3A30"), 1)
    lingua = (*hex_rgb("#E07A72"), 1)
    rubor = (*hex_rgb("#F2A0A0"), 0.55)

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

    def arco(cx, cy, rx, ry, a0, a1, esp, n=14):
        pts = [(cx + rx * math.cos(a), cy + ry * math.sin(a)) for a in np.linspace(a0, a1, n)]
        return curva(pts, esp)

    def pinta(cel, mask, cor):
        cel[mask] = cor

    # olhos: centro (x, y) e raios, no espaço da célula (y para baixo)
    OLHOS = [(41, 64), (87, 64)]
    RX, RY = 10.5, 15.0
    BOCA = (64, 107)

    def olho_aberto(cel, cx, cy, lado, rx=RX, ry=RY, corte=0.0, pupila_r=1.0):
        # corte: fração de cima tampada (cansada)
        dentro = elipse(cx, cy, rx, ry)
        topo = cy - ry + corte * 2 * ry
        dentro &= yy >= topo
        pinta(cel, dentro, branco)
        ir = elipse(cx, cy + 1.5, rx * 0.86, ry * 0.86) & dentro
        pinta(cel, ir, iris)
        pinta(cel, ir & (yy < cy - ry * 0.25), iris_esc)
        pinta(cel, elipse(cx, cy + 2.5, rx * 0.42 * pupila_r, ry * 0.45 * pupila_r) & dentro, pupila)
        pinta(cel, elipse(cx - 3.5 * lado, cy - 5, 2.6, 3.4) & dentro, branco)
        pinta(cel, elipse(cx + 3 * lado, cy + 6, 1.4, 1.8) & dentro, branco)
        # contorno e cílio grosso em cima, com pontinha para fora
        borda = elipse(cx, cy, rx + 1.6, ry + 1.6) & ~elipse(cx, cy, rx, ry) & (yy >= topo - 2)
        pinta(cel, borda & (yy > cy), escuro)
        cilio = arco(cx, cy if corte == 0 else topo + ry * 0.2, rx + 1.0, ry * (1 - corte) + 1.0 if corte == 0 else 3.0,
                     math.pi * 1.05, math.pi * 1.95, 2.4)
        pinta(cel, cilio, escuro)
        pinta(cel, segmento(cx + (rx + 0.5) * lado, cy - ry * 0.55, cx + (rx + 5) * lado, cy - ry * 0.85, 1.6), escuro)
        if corte > 0:
            pinta(cel, segmento(cx - rx - 1, topo, cx + rx + 1, topo, 1.8), escuro)

    def sobrancelha(cel, cx, cy, lado, incl):
        # incl > 0: ponta de dentro para baixo (brava); < 0: para cima (triste)
        dentro_x = cx - 9 * lado
        fora_x = cx + 9 * lado
        pinta(cel, segmento(fora_x, cy - 24, dentro_x, cy - 24 + incl, 1.8), escuro)

    def celula(nome):
        cel = np.zeros((ATLAS_CEL, ATLAS_CEL, 4))
        for (cx, cy), lado in zip(OLHOS, (-1, 1)):
            # bochechas coradas, bem leves
            pinta(cel, elipse(cx + 2 * lado, cy + 22, 9, 4), rubor)
        bx, by = BOCA
        if nome == "normal":
            for (cx, cy), lado in zip(OLHOS, (-1, 1)):
                olho_aberto(cel, cx, cy, lado)
                sobrancelha(cel, cx, cy, lado, -1)
            pinta(cel, arco(bx, by - 4, 6, 4, 0.15 * math.pi, 0.85 * math.pi, 1.4), boca)
        elif nome == "feliz":
            for (cx, cy), lado in zip(OLHOS, (-1, 1)):
                pinta(cel, arco(cx, cy + 4, RX, RY * 0.7, math.pi * 1.1, math.pi * 1.9, 2.6), escuro)
                sobrancelha(cel, cx, cy - 3, lado, -2)
            m = elipse(bx, by - 2, 9, 7) & (yy >= by - 3)
            pinta(cel, m, boca)
            pinta(cel, elipse(bx, by + 3, 5, 3) & m, lingua)
        elif nome == "determinada":
            for (cx, cy), lado in zip(OLHOS, (-1, 1)):
                olho_aberto(cel, cx, cy + 1, lado, ry=RY * 0.9, corte=0.18)
                pinta(cel, segmento(cx + 11 * lado, cy - 20, cx - 9 * lado, cy - 12, 2.3), escuro)
            pinta(cel, curva([(bx - 7, by - 1), (bx, by - 3), (bx + 7, by - 1)], 1.5), boca)
            pinta(cel, segmento(bx + 4, by - 2.5, bx + 7, by - 5, 1.2), boca)
        elif nome == "cansada":
            for (cx, cy), lado in zip(OLHOS, (-1, 1)):
                olho_aberto(cel, cx, cy + 2, lado, corte=0.5, pupila_r=0.9)
                sobrancelha(cel, cx, cy + 3, lado, -4)
            pinta(cel, elipse(bx, by - 1, 4, 3.5), boca)
            pinta(cel, elipse(108, 44, 3, 5) | (elipse(108, 41, 1.6, 4) & (yy < 41)), (*hex_rgb("#9AD4F0"), 1))
        elif nome == "triste":
            for (cx, cy), lado in zip(OLHOS, (-1, 1)):
                olho_aberto(cel, cx, cy + 2, lado, ry=RY * 0.92, corte=0.12)
                sobrancelha(cel, cx, cy, lado, -8)
                pinta(cel, elipse(cx - 6 * lado, cy + 16, 2, 3), (*hex_rgb("#9AD4F0"), 1))
            pinta(cel, arco(bx, by + 2, 6, 4, 1.15 * math.pi, 1.85 * math.pi, 1.4), boca)
        elif nome == "surpresa":
            for (cx, cy), lado in zip(OLHOS, (-1, 1)):
                olho_aberto(cel, cx, cy - 1, lado, rx=RX * 1.05, ry=RY * 1.08, pupila_r=0.6)
                sobrancelha(cel, cx, cy - 6, lado, -3)
            pinta(cel, elipse(bx, by - 1, 5, 6.5), boca)
            pinta(cel, elipse(bx, by + 2, 3, 2.5), lingua)
        return cel

    for i, nome in enumerate(EXPRESSOES):
        c, r = i % ATLAS_COLS, i // ATLAS_COLS
        arr[r * ATLAS_CEL:(r + 1) * ATLAS_CEL, c * ATLAS_CEL:(c + 1) * ATLAS_CEL] = celula(nome)
    return imagem("lira_rosto", arr)


def material(nome, img, alpha=False):
    mat = bpy.data.materials.new(nome)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
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


def montar_malha():
    tronco()
    for s in (1, -1):
        perna(s)
        braco(s)
        orelha(s)
    cabeca()
    rosto()
    cabelo()
    rabo()
    jaqueta()
    estrela_peito()

    me = bpy.data.meshes.new("Lira")
    me.from_pydata([tuple(v) for v in M.verts], [], [f[0] for f in M.faces])
    me.update()
    uv = me.uv_layers.new(name="UVMap")
    for poly, (idx, cor, mat, uvs) in zip(me.polygons, M.faces):
        poly.material_index = mat
        for k, li in enumerate(poly.loop_indices):
            uv.data[li].uv = uvs[k] if uvs else uv_da_cor(cor)
    me.materials.append(material("Lira_Paleta", textura_paleta()))
    me.materials.append(material("Lira_Rosto", atlas_rosto(), alpha=True))
    for p in me.polygons:
        p.use_smooth = False
    ob = bpy.data.objects.new("Lira", me)
    bpy.context.scene.collection.objects.link(ob)
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    print(f"[lira] vértices {len(me.vertices)}  triângulos {tris}")
    return ob


def montar_esqueleto():
    arm = bpy.data.armatures.new("Lira_Rig")
    ob = bpy.data.objects.new("Lira_Rig", arm)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for nome, h, t, pai, deforma in OSSOS:
        eb = arm.edit_bones.new(nome)
        eb.head, eb.tail = h, t
        eb.use_deform = deforma
        eb.align_roll(Vector((0, -1, 0)) if abs((t - h).normalized().y) < 0.9 else Vector((0, 0, 1)))
        if pai:
            eb.parent = arm.edit_bones[pai]
            eb.use_connect = (arm.edit_bones[pai].tail - eb.head).length < 1e-4
    bpy.ops.object.mode_set(mode="OBJECT")
    return ob


def pesar(malha, rig):
    grupos = {}
    for nome, _, _, _, deforma in OSSOS:
        if deforma:
            grupos[nome] = malha.vertex_groups.new(name=nome)
    for i, pw in enumerate(M.pesos):
        tot = sum(pw.values())
        for nome, w in pw.items():
            grupos[nome].add([i], w / tot, "REPLACE")
    mod = malha.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    malha.parent = rig


# ---------------------------------------------------------------------------
# Animações
# ---------------------------------------------------------------------------

def rot_mundo(rig, osso_nome, eixo, graus):
    """Rotação em torno de um eixo do mundo, convertida para o espaço do osso em repouso."""
    m = rig.data.bones[osso_nome].matrix_local.to_3x3()
    r = Matrix.Rotation(math.radians(graus), 3, eixo)
    return (m.inverted() @ r @ m).to_quaternion()


def pose(rig, quadro, rots, locs=None):
    """rots: {osso: [(eixo, graus), ...]}; aplica e grava chave em todos os ossos."""
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
        q = Quaternion()
        for eixo, g in rots.get(pb.name, []):
            q = rot_mundo(rig, pb.name, eixo, g) @ q
        pb.rotation_quaternion = q
        pb.location = (locs or {}).get(pb.name, (0, 0, 0))
        pb.keyframe_insert("rotation_quaternion", frame=quadro)
        pb.keyframe_insert("location", frame=quadro)


def nova_acao(rig, nome):
    acao = bpy.data.actions.new(nome)
    acao.use_fake_user = True
    if rig.animation_data is None:
        rig.animation_data_create()
    rig.animation_data.action = acao
    return acao


def anim_parada(rig):
    acao = nova_acao(rig, "parada")
    N = 48
    for f in range(0, N + 1, 4):
        p = 2 * math.pi * f / N
        respira = math.sin(p)
        rots = {
            "spine": [("X", 1.5 * respira)],
            "chest": [("X", 1.0 * respira)],
            "head": [("X", -1.5 * respira), ("Z", 3 * math.sin(p * 0.5))],
            "upper_arm.L": [("Y", 4 + 1.5 * respira)],
            "upper_arm.R": [("Y", -4 - 1.5 * respira)],
            "forearm.L": [("X", -8)],
            "forearm.R": [("X", -8)],
        }
        # rabo em pé, balançando de leve, com atraso ao longo da corrente
        for i in range(1, len(RABO)):
            rots[f"tail.{i:03d}"] = [("Z", 6 * math.sin(p - i * 0.6))]
        # orelha esquerda dá uma tremidinha
        tre = 12 if f in (32, 36) else 0
        rots["ear.L"] = [("Y", -tre)]
        rots["ear.R"] = [("Y", 2 * respira)]
        pose(rig, f + 1, rots, {"hips": (0, -0.004 * (1 - respira) * 0.5, 0)})
    acao.frame_range = (1, N + 1)
    return acao


def anim_correr(rig):
    acao = nova_acao(rig, "correr")
    N = 16
    for f in range(0, N + 1, 2):
        p = 2 * math.pi * f / N
        rots = {"spine": [("X", 8)], "chest": [("X", 4), ("Z", 6 * math.cos(p))],
                "hips": [("Z", -5 * math.cos(p))], "head": [("X", -9)], "neck": [("X", -2)]}
        for s, L, fase in ((1, "L", 0.0), (-1, "R", math.pi)):
            q = p + fase
            rots[f"thigh.{L}"] = [("X", -38 * math.cos(q) + 6)]
            rots[f"shin.{L}"] = [("X", 12 + 80 * max(0.0, -math.sin(q)) + 10 * max(0.0, math.sin(q)))]
            rots[f"foot.{L}"] = [("X", 18 * max(0.0, -math.sin(q)) - 8 * math.cos(q))]
            # braço oposto à perna, cotovelo dobrado, mais perto do corpo
            rots[f"upper_arm.{L}"] = [("Y", s * 22), ("X", 38 * math.cos(q))]
            rots[f"forearm.{L}"] = [("X", -72 - 12 * math.cos(q))]
            rots[f"ear.{L}"] = [("X", -18)]
        rots["tail.001"] = [("X", -38), ("Z", 8 * math.sin(p))]
        for i in range(2, len(RABO)):
            rots[f"tail.{i:03d}"] = [("X", -14), ("Z", 7 * math.sin(p - i * 0.7))]
        bob = 0.03 * abs(math.sin(p))
        pose(rig, f + 1, rots, {"hips": (0, bob - 0.02, 0)})
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
    kw = dict(filepath=caminho, export_format="GLB", export_skins=True, export_animations=True,
              export_animation_mode="NLA_TRACKS", export_yup=True, export_apply=False,
              export_texcoords=True, export_normals=True, export_materials="EXPORT")
    try:
        bpy.ops.export_scene.gltf(**kw)
    except TypeError as e:
        print("[lira] export: parâmetro rejeitado:", e)
        raise
    print("[lira] exportado:", caminho, os.path.getsize(caminho), "bytes")


def previas(rig, malha):
    for pb in rig.pose.bones:
        pb.rotation_quaternion = Quaternion()
        pb.location = (0, 0, 0)
    pasta = os.path.join(RAIZ, "arte", "previa")
    os.makedirs(pasta, exist_ok=True)
    cena = bpy.context.scene
    for motor in ("BLENDER_WORKBENCH",):
        cena.render.engine = motor
    sh = cena.display.shading
    sh.light = "STUDIO"
    sh.color_type = "TEXTURE"
    sh.show_object_outline = True
    sh.show_cavity = False
    cena.render.resolution_x = 900
    cena.render.resolution_y = 1100
    cena.render.film_transparent = False
    mundo = bpy.data.worlds.new("Fundo")
    cena.world = mundo
    cam_d = bpy.data.cameras.new("Cam")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = 1.95
    cam = bpy.data.objects.new("Cam", cam_d)
    cena.collection.objects.link(cam)
    cena.camera = cam
    alvo = Vector((0, 0.05, 0.86))
    vistas = {"frente": (0, -1, 0.05), "lado": (1, 0, 0.05), "tres_quartos": (0.7, -0.7, 0.18),
              "costas": (-0.4, 1, 0.1)}
    for nome, d in vistas.items():
        d = Vector(d).normalized()
        cam.location = alvo + d * 4
        cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
        cena.render.filepath = os.path.join(pasta, f"{nome}.png")
        bpy.ops.render.render(write_still=True)
    # close do rosto com todas as expressões? fica no Godot (troca de UV)
    cam_d.ortho_scale = 0.42
    d = Vector((0.25, -1, 0.05)).normalized()
    cam.location = CABECA_C + Vector((0, 0, 0.02)) + d * 3
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    cena.render.resolution_x = cena.render.resolution_y = 700
    cena.render.filepath = os.path.join(pasta, "rosto.png")
    bpy.ops.render.render(write_still=True)
    # pose de corrida
    ad = rig.animation_data
    for tr in ad.nla_tracks:
        tr.mute = tr.name != "correr"
    cena.frame_set(5)
    cam_d.ortho_scale = 1.95
    cena.render.resolution_x, cena.render.resolution_y = 900, 1100
    d = Vector((1, -0.35, 0.1)).normalized()
    cam.location = alvo + d * 4
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    cena.render.filepath = os.path.join(pasta, "correndo.png")
    bpy.ops.render.render(write_still=True)
    for tr in ad.nla_tracks:
        tr.mute = True
    cena.frame_set(1)
    bpy.data.objects.remove(cam)


def main():
    limpar()
    os.makedirs(os.path.join(RAIZ, "arte"), exist_ok=True)
    malha = montar_malha()
    rig = montar_esqueleto()
    pesar(malha, rig)
    acoes = [anim_parada(rig), anim_correr(rig)]
    guardar_acoes(rig, acoes)
    bpy.context.scene.render.fps = 24
    exportar(rig)
    if RENDER:
        previas(rig, malha)
    # arquivo salvo em repouso, com a vista em textura (o Workbench das prévias não tem Material Preview)
    for pb in rig.pose.bones:
        pb.rotation_quaternion = Quaternion()
        pb.location = (0, 0, 0)
    bpy.context.scene.display.shading.color_type = "TEXTURE"
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(RAIZ, "arte", "lira.blend"), compress=True)
    print("[lira] ok")


main()
