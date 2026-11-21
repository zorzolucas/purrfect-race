"""Etapa 2 do import dos modelos do Tripo: esqueleto, pesos, animações do Mixamo e o .glb do jogo.

Todas as garotas usam o mesmo esqueleto da Lira (mesmos ossos, mesma hierarquia, os nomes que o
retarget e o jogo esperam: corpo humanoide, 2 orelhas e a cadeia do rabo). Só a posição de cada
junta é medida na malha dela (mãos, joelhos, tornozelos, orelhas e o caminho do rabo), e as
mesmas 31 animações do Mixamo são passadas para ele com tools/blender/retarget_mixamo.py.

    python tools/blender/tripo_rig.py <preparado.blend> <saida.glb> <pasta_animacoes> [previa.blend]
"""
import heapq
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import retarget_mixamo as rt  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
ENTRADA, SAIDA, PASTA_ANIM = args[0], args[1], args[2]
PREVIA = args[3] if len(args) > 3 else None
N_RABO = 6
# ponta do rabo de cada garota (m, já na pose do jogo: frente -Y, 1,6 m). Só precisa cair perto:
# o script pega o vértice candidato mais próximo e segue a malha dali até a base do rabo.
PONTA_RABO = {
    "Algol": (0.35, 0.36, 1.06), "Antares": (0.39, 0.49, 1.08), "Capela": (-0.35, 0.32, 0.45),
    "Lira": (0.39, 0.48, 1.07), "Mira": (0.45, 0.43, 0.22), "Nahira": (0.45, 0.43, 1.13),
    "Polaris": (0.41, 0.53, 1.11), "Shaula": (0.38, 0.36, 1.07),
}
NOME = os.path.splitext(os.path.basename(ENTRADA))[0]

bpy.ops.wm.open_mainfile(filepath=ENTRADA)
malha = bpy.data.objects["Corpo"]
me = malha.data
V = np.empty(len(me.vertices) * 3)
me.vertices.foreach_get("co", V)
V = V.reshape(-1, 3)
X, Y, Z = V[:, 0], V[:, 1], V[:, 2]


def faixa(z0, z1, extra=None):
    m = (Z >= z0) & (Z <= z1)
    return m if extra is None else m & extra


def centro_y(z0, z1):
    """Centro do tronco em Y naquela altura (mediana, ignora rabo e cabelo)."""
    m = faixa(z0, z1, np.abs(X) < 0.12)
    return float(np.median(Y[m])) if m.sum() > 10 else 0.0


# --- tronco e cabeça (proporções medidas nas 8 garotas do Tripo, 1,6 m) -----------------
y_quadril = centro_y(0.70, 0.86)
y_cintura = centro_y(0.86, 0.95)
y_peito = centro_y(0.95, 1.06)
J = {}
J["hips"] = Vector((0, y_quadril, 0.78))
J["spine"] = Vector((0, y_cintura, 0.89))
J["chest"] = Vector((0, y_peito, 0.99))
J["neck"] = Vector((0, y_peito, 1.10))
J["head"] = Vector((0, y_peito, 1.16))
J["head_fim"] = Vector((0, y_peito, 1.50))

# --- pernas --------------------------------------------------------------------------
def media_lado(s, z0, z1, max_x=0.3):
    m = faixa(z0, z1, (s * X > 0.01) & (s * X < max_x))
    if m.sum() < 5:
        return None
    ym = np.median(Y[m])
    m &= np.abs(Y - ym) < 0.12  # tira rabo e cabelo que passam por ali
    return Vector((float(X[m].mean()), float(Y[m].mean()), (z0 + z1) / 2))


for s, L in ((1, "L"), (-1, "R")):
    joelho = media_lado(s, 0.40, 0.44)
    tornoz = media_lado(s, 0.20, 0.24)
    pe = faixa(0.0, 0.08, (s * X > 0.02) & (s * X < 0.35))
    ponta_y = float(np.percentile(Y[pe], 2))
    J[f"thigh.{L}"] = Vector((s * max(0.07, abs(joelho.x) * 0.85), y_quadril, 0.74))
    J[f"shin.{L}"] = Vector((joelho.x, joelho.y - 0.01, 0.42))
    J[f"foot.{L}"] = Vector((tornoz.x, tornoz.y, 0.15))
    J[f"toe.{L}"] = Vector((tornoz.x, ponta_y * 0.7 + tornoz.y * 0.3, 0.04))

    # --- braços (pose A): a mão é o ponto mais de fora entre a cintura e o peito -----------
    m = faixa(0.45, 1.0, s * X > 0.2)
    ponta = np.percentile(s * X[m], 99.7)
    mao = m & (s * X > ponta - 0.11)
    mao_c = Vector((float(X[mao].mean()), float(Y[mao].mean()), float(Z[mao].mean())))
    ombro = Vector((s * 0.15, y_peito, 1.04))
    d = (mao_c - ombro).normalized()
    pulso = mao_c - d * 0.085
    cotovelo = (ombro + pulso) / 2 + Vector((0, 0.012, 0))
    J[f"shoulder.{L}"] = Vector((s * 0.03, y_peito - 0.01, 1.06))
    J[f"upper_arm.{L}"] = ombro
    J[f"forearm.{L}"] = cotovelo
    J[f"hand.{L}"] = pulso
    J[f"hand_fim.{L}"] = mao_c + d * 0.06

    # --- orelhas: ponta mais alta de cada lado, no topo da cabeça -------------------------
    m = faixa(1.35, 2.0, (s * X > 0.04) & (np.abs(Y - y_peito) < 0.2))
    i = np.argmax(np.where(m, Z, -9))
    tip = Vector(V[i])
    J[f"ear.{L}"] = Vector((tip.x * 0.75, tip.y, tip.z - 0.13))
    J[f"ear_fim.{L}"] = tip

# --- rabo: o pedaço da malha longe dos ossos do corpo, atrás, que nasce perto do quadril ---
def dist_seg(P, a, b):
    a, b = np.array(a), np.array(b)
    ab = b - a
    t = np.clip(((P - a) @ ab) / max(ab @ ab, 1e-9), 0, 1)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)


# cada parte do corpo tem um raio: o que passa disso, atrás do corpo, é candidato a rabo.
# Braços só contam pelo que está na linha deles: em pose A o rabo costuma passar atrás da mão.
tronco = [(J["hips"], J["chest"], 0.14), (J["chest"], J["neck"], 0.14)]
pernas, bracos = [], []
for L in "LR":
    pernas += [(J[f"thigh.{L}"], J[f"shin.{L}"], 0.11), (J[f"shin.{L}"], J[f"foot.{L}"], 0.10),
               (J[f"foot.{L}"], J[f"toe.{L}"], 0.11)]
    bracos += [(J[f"upper_arm.{L}"], J[f"hand.{L}"], 0.09), (J[f"hand.{L}"], J[f"hand_fim.{L}"], 0.10)]
perto = np.zeros(len(V), bool)
for a_, b_, r in tronco + pernas:
    perto |= dist_seg(V, a_, b_) < r
y_mao = np.mean([J[f"hand.{L}"].y for L in "LR"])
for a_, b_, r in bracos:
    perto |= (dist_seg(V, a_, b_) < r) & (Y < y_mao + 0.06)
cand = ~perto & (Y > y_quadril + 0.04) & (Z < 1.10)
viz = [[] for _ in range(len(V))]
for e in me.edges:
    a, b = e.vertices
    w = float(np.linalg.norm(V[a] - V[b]))
    viz[a].append((b, w))
    viz[b].append((a, w))

raiz = Vector((0, y_quadril + 0.08, 0.76))
comp = -np.ones(len(V), int)
comps = []
for i in np.where(cand)[0]:
    if comp[i] >= 0:
        continue
    k = len(comps)
    i = int(i)
    pilha, membros, borda = [i], [], []
    comp[i] = k
    while pilha:
        u = pilha.pop()
        membros.append(u)
        for w, _ in viz[u]:
            if cand[w]:
                if comp[w] < 0:
                    comp[w] = k
                    pilha.append(w)
            else:
                borda.append(u)
    comps.append((membros, borda))

rabo_vs, rabo_bin = [], {}
ponta = PONTA_RABO.get(NOME)
if ponta is not None:
    cs = np.where(comp >= 0)[0]
    semente = int(cs[np.argmin(np.linalg.norm(V[cs] - np.array(ponta), axis=1))])
    membros, borda = comps[comp[semente]]
    em = set(membros)
    dist = {semente: 0.0}
    fila = [(0.0, semente)]
    while fila:
        d0, u = heapq.heappop(fila)
        if d0 > dist.get(u, 9e9):
            continue
        for w, c in viz[u]:
            if w in em and d0 + c < dist.get(w, 9e9):
                dist[w] = d0 + c
                heapq.heappush(fila, (d0 + c, w))
    # a base é o vértice do pedaço mais perto do quadril (por trás); o rabo vai da ponta até ela
    alcance = [u for u in membros if u in dist]
    base_v = min(alcance, key=lambda u: np.linalg.norm(V[u] - np.array(raiz)))
    Lr = dist[base_v]
    rabo_vs = [int(u) for u in alcance if dist[u] <= Lr]
    base = Vector(V[[u for u in rabo_vs if dist[u] >= Lr - 0.04]].mean(0))
    pts = [base]
    for k in range(1, N_RABO + 1):
        alvo = Lr * (1 - k / N_RABO)
        sel = [u for u in rabo_vs if abs(dist[u] - alvo) <= Lr / N_RABO / 2] or [semente]
        pts.append(Vector(V[sel].mean(0)))
    for u in rabo_vs:
        rabo_bin[u] = (Lr - dist[u]) / max(Lr, 1e-6) * N_RABO
    J["tail_pts"] = [J["hips"] + (base - J["hips"]) * 0.5] + pts
    print(f"[rig] rabo: {len(rabo_vs)} vértices, {Lr:.2f} m")
else:
    print("[rig] rabo não encontrado")

if os.environ.get("RIG_DEBUG"):
    tm = np.zeros(len(V), bool)
    tm[rabo_vs] = True
    np.savez(os.environ["RIG_DEBUG"], V=V, cand=cand, rabo=tm, comp=comp)

# --- esqueleto (mesma hierarquia e nomes do rig da Lira) -------------------------------
OSSOS = [("root", Vector((0, 0, 0)), Vector((0, -0.25, 0)), None),
         ("hips", J["hips"], J["spine"], "root"),
         ("spine", J["spine"], J["chest"], "hips"),
         ("chest", J["chest"], J["neck"], "spine"),
         ("neck", J["neck"], J["head"], "chest"),
         ("head", J["head"], J["head_fim"], "neck")]
for L in "LR":
    OSSOS += [(f"thigh.{L}", J[f"thigh.{L}"], J[f"shin.{L}"], "hips"),
              (f"shin.{L}", J[f"shin.{L}"], J[f"foot.{L}"], f"thigh.{L}"),
              (f"foot.{L}", J[f"foot.{L}"], J[f"toe.{L}"], f"shin.{L}"),
              (f"shoulder.{L}", J[f"shoulder.{L}"], J[f"upper_arm.{L}"], "chest"),
              (f"upper_arm.{L}", J[f"upper_arm.{L}"], J[f"forearm.{L}"], f"shoulder.{L}"),
              (f"forearm.{L}", J[f"forearm.{L}"], J[f"hand.{L}"], f"upper_arm.{L}"),
              (f"hand.{L}", J[f"hand.{L}"], J[f"hand_fim.{L}"], f"forearm.{L}")]
for L in "LR":
    OSSOS.append((f"ear.{L}", J[f"ear.{L}"], J[f"ear_fim.{L}"], "head"))
if "tail_pts" in J:
    tp = J["tail_pts"]
    for i in range(len(tp) - 1):
        OSSOS.append((f"tail.{i + 1:03d}", tp[i], tp[i + 1], "hips" if i == 0 else f"tail.{i:03d}"))

arm = bpy.data.armatures.new("Esqueleto")
rig = bpy.data.objects.new("Esqueleto", arm)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
for nome, h, t, pai in OSSOS:
    eb = arm.edit_bones.new(nome)
    eb.head, eb.tail = h, t
    if (t - h).length < 0.01:
        eb.tail = h + Vector((0, 0, 0.02))
    eb.use_deform = nome != "root"
    if pai:
        eb.parent = arm.edit_bones[pai]
bpy.ops.object.mode_set(mode="OBJECT")

# --- pesos: automáticos (calor) e depois rabo e orelhas por conta própria ---------------
bpy.ops.object.select_all(action="DESELECT")
malha.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
grupos = {g.name: g for g in malha.vertex_groups}
for nome, *_ in OSSOS:
    if nome != "root" and nome not in grupos:
        grupos[nome] = malha.vertex_groups.new(name=nome)
idx_nome = {g.index: g.name for g in malha.vertex_groups}

def grupos_do(i):
    return [g.group for g in me.vertices[i].groups]


def zera(i):
    for gi in grupos_do(i):
        malha.vertex_groups[gi].remove([i])

# completa o rabo com o que está colado na cadeia e mais perto dela do que do corpo (a ponta às
# vezes é uma ilha separada ou passa perto da mão)
if "tail_pts" in J:
    tp = J["tail_pts"][1:]
    d_rabo = np.min([dist_seg(V, tp[k], tp[k + 1]) for k in range(len(tp) - 1)], axis=0)
    d_corpo = np.min([dist_seg(V, a_, b_) for a_, b_, _ in tronco + pernas + bracos], axis=0)
    rabo_set0 = set(rabo_vs)
    extra = np.where((d_rabo < 0.10) & (d_rabo < 0.8 * d_corpo) & (Y > y_quadril))[0]
    for u in extra:
        u = int(u)
        if u in rabo_set0:
            continue
        # posição ao longo da cadeia: segmento mais perto + fração dentro dele
        ds = [dist_seg(V[u:u + 1], tp[k], tp[k + 1])[0] for k in range(len(tp) - 1)]
        k = int(np.argmin(ds))
        a_, b_ = np.array(tp[k]), np.array(tp[k + 1])
        t = float(np.clip((V[u] - a_) @ (b_ - a_) / max((b_ - a_) @ (b_ - a_), 1e-9), 0, 1))
        rabo_vs.append(u)
        rabo_bin[u] = k + t
    # e o que encosta nisso, longe do corpo e perto da cadeia (a ponta pode passar da altura do
    # corte dos candidatos)
    no_rabo = set(rabo_vs)
    fila = list(no_rabo)
    while fila:
        u = fila.pop()
        for w, _ in viz[u]:
            if w not in no_rabo and not perto[w] and d_rabo[w] < 0.15 and Y[w] > y_quadril:
                no_rabo.add(w)
                fila.append(w)
                ds = [dist_seg(V[w:w + 1], tp[k], tp[k + 1])[0] for k in range(len(tp) - 1)]
                k = int(np.argmin(ds))
                a_, b_ = np.array(tp[k]), np.array(tp[k + 1])
                rabo_vs.append(int(w))
                rabo_bin[int(w)] = k + float(np.clip((V[w] - a_) @ (b_ - a_) / max((b_ - a_) @ (b_ - a_), 1e-9), 0, 1))
    # pedaços soltos da malha que são quase todos rabo vão inteiros
    ilha = -np.ones(len(V), int)
    ilhas = []
    for i0 in range(len(V)):
        if ilha[i0] >= 0:
            continue
        pilha, mem = [i0], []
        ilha[i0] = len(ilhas)
        while pilha:
            u = pilha.pop()
            mem.append(u)
            for w, _ in viz[u]:
                if ilha[w] < 0:
                    ilha[w] = len(ilhas)
                    pilha.append(w)
        ilhas.append(mem)
    no_rabo = set(rabo_vs)
    for mem in ilhas:
        dentro = sum(1 for u in mem if u in no_rabo)
        if 0 < dentro < len(mem) and dentro >= 0.4 * len(mem) and len(mem) < 0.2 * len(V):
            for u in mem:
                if u not in no_rabo:
                    ds = [dist_seg(V[u:u + 1], tp[k], tp[k + 1])[0] for k in range(len(tp) - 1)]
                    rabo_vs.append(int(u))
                    rabo_bin[int(u)] = float(np.argmin(ds)) + 0.5
                    no_rabo.add(u)
    print(f"[rig] rabo completado com {len(rabo_vs) - len(rabo_set0)} vértices")
rabo_set = set(rabo_vs)
cauda_nomes = [n for n, *_ in OSSOS if n.startswith("tail.")]
perto_raiz = np.linalg.norm(V - np.array(J["tail_pts"][1] if "tail_pts" in J else raiz), axis=1) < 0.08
for i, v in enumerate(me.vertices):
    if i in rabo_set:
        continue
    if not perto_raiz[i]:  # rabo só mexe no rabo (o calor às vezes puxa a perna junto)
        for gi in grupos_do(i):
            if idx_nome.get(gi, "").startswith("tail."):
                malha.vertex_groups[gi].remove([i])
for i in rabo_vs:
    zera(i)
    b = rabo_bin[i]
    k = min(int(b), len(cauda_nomes) - 1)
    f = b - k
    proximo = min(k + 1, len(cauda_nomes) - 1)
    if f > 0.5 and proximo != k:
        w = (f - 0.5)
        grupos[cauda_nomes[k]].add([i], 1 - w, "REPLACE")
        grupos[cauda_nomes[proximo]].add([i], w, "REPLACE")
    else:
        grupos[cauda_nomes[k]].add([i], 1.0, "REPLACE")
for L in "LR":
    a, b = J[f"ear.{L}"], J[f"ear_fim.{L}"]
    d = dist_seg(V, a, b)
    sel = np.where((d < 0.06) & (Z > a.z) & ((X > 0) == (L == "L")))[0]
    for i in sel:
        zera(int(i))
        grupos[f"ear.{L}"].add([int(i)], 1.0, "REPLACE")
    # e a orelha não fica presa a outro osso
    for i in np.where((d >= 0.06) & ((X > 0) == (L == "L")))[0]:
        for gi in grupos_do(int(i)):
            if idx_nome.get(gi) == f"ear.{L}":
                malha.vertex_groups[gi].remove([int(i)])
# quem ficou sem peso vai para o osso mais perto
centros = {n: (h, t) for n, h, t, _ in OSSOS if n != "root"}
sem = [i for i, v in enumerate(me.vertices) if sum(g.weight for g in v.groups) < 1e-4]
if sem:
    # perto de cada osso, com mistura suave entre os mais próximos (o calor às vezes falha)
    nomes_c = [n for n in centros if not n.startswith(("tail.", "ear."))]
    P = V[sem]
    D = np.stack([dist_seg(P, *centros[n]) for n in nomes_c], axis=1)
    for k, i in enumerate(sem):
        d = D[k]
        ordem = np.argsort(d)[:3]
        dm = max(d[ordem[0]], 1e-4)
        ws = [(nomes_c[j], (dm / max(d[j], 1e-4)) ** 4) for j in ordem if d[j] < dm * 1.5]
        tot = sum(w for _, w in ws)
        for n, w in ws:
            grupos[n].add([int(i)], w / tot, "REPLACE")
print(f"[rig] {len(OSSOS)} ossos, {len(sem)} vértices sem peso corrigidos")

# faces que ligam o rabo a uma perna ou braço (o Tripo funde o que encosta) esticariam: saem
idx_nome = {g.index: g.name for g in malha.vertex_groups}
dom = {}
for i, v in enumerate(me.vertices):
    if v.groups:
        g = max(v.groups, key=lambda g: g.weight)
        dom[i] = idx_nome.get(g.group, "")
membros_nomes = ("thigh.", "shin.", "foot.", "forearm.", "hand.", "upper_arm.")
apagar = []
for p in me.polygons:
    ns = {dom.get(i, "") for i in p.vertices}
    ponte_rabo = any(n.startswith("tail.") and n != "tail.001" for n in ns) and \
        any(n.startswith(membros_nomes) for n in ns)
    # canela ou pé de um lado colado no outro também estica
    lados = {n[-1] for n in ns if n.startswith(("shin.", "foot."))}
    if ponte_rabo or len(lados) > 1:
        apagar.append(p.index)
if apagar:
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.faces[i] for i in apagar], context="FACES_ONLY")
    bm.to_mesh(me)
    bm.free()
print(f"[rig] {len(apagar)} faces de ponte rabo-membro removidas")

# --- animações -------------------------------------------------------------------------
acoes = rt.retargetar_tudo(rig, PASTA_ANIM, rt.ANIMACOES)
ad = rig.animation_data or rig.animation_data_create()
for acao in acoes:
    tr = ad.nla_tracks.new()
    tr.name = acao.name
    st = tr.strips.new(acao.name, int(acao.frame_range[0]), acao)
    st.name = acao.name
    tr.mute = True
ad.action = None

# o jogo desenha sem luz, então a normal só serve para o contorno (casco que cresce pela normal):
# normais suaves evitam que ele abra nas quinas
for p in me.polygons:
    p.use_smooth = True

if PREVIA:
    bpy.ops.wm.save_as_mainfile(filepath=PREVIA)
bpy.ops.object.select_all(action="DESELECT")
bpy.ops.export_scene.gltf(filepath=SAIDA, export_format="GLB", export_skins=True, export_animations=True,
                          export_animation_mode="NLA_TRACKS", export_yup=True, export_apply=False,
                          export_texcoords=True, export_normals=True, export_materials="EXPORT",
                          export_image_format="JPEG", export_jpeg_quality=90)
print("[rig] exportado:", SAIDA, os.path.getsize(SAIDA), "bytes")
