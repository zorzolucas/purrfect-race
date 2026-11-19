"""Passa animações do Mixamo (FBX sem skin) para o esqueleto da garota.

O corpo usa a variação de orientação de cada osso no espaço do mundo, a partir da pose T do
Mixamo: a garota é posta "em T" (cada osso alinhado à direção do osso do Mixamo em repouso)
e recebe a mesma rotação que o osso do Mixamo fez. Assim funciona mesmo com o nosso rig em
pose A e proporções diferentes. Rabo e orelhas não existem no Mixamo: ganham uma camada
procedural por cima (balanço e reação ao movimento).

Uso (dentro do Blender, chamado pelo tools/blender/lira.py):
    acoes = retargetar_tudo(rig, pasta_fbx, ANIMACOES)
"""

import math
import os

import bpy
from mathutils import Matrix, Quaternion, Vector

# osso da garota -> osso do Mixamo
MAPA = {
    "hips": "Hips", "spine": "Spine", "chest": "Spine2", "neck": "Neck", "head": "Head",
    "shoulder.L": "LeftShoulder", "upper_arm.L": "LeftArm", "forearm.L": "LeftForeArm", "hand.L": "LeftHand",
    "shoulder.R": "RightShoulder", "upper_arm.R": "RightArm", "forearm.R": "RightForeArm", "hand.R": "RightHand",
    "thigh.L": "LeftUpLeg", "shin.L": "LeftLeg", "foot.L": "LeftFoot",
    "thigh.R": "RightUpLeg", "shin.R": "RightLeg", "foot.R": "RightFoot",
}

# nome no jogo: (arquivo do Mixamo, tirar deslocamento horizontal?, tipo da camada de rabo/orelhas)
ANIMACOES = {
    "parada": ("idle.fbx", False, "calma"),
    "andar": ("Walking.fbx", True, "andar"),
    "trote": ("Medium Run.fbx", True, "correr"),
    "correr": ("Running.fbx", True, "correr"),
    "sprint": ("Fast Run.fbx", True, "correr"),
    "largada": ("Idle To Sprint.fbx", True, "correr"),
    "comemorar": ("Victory Idle.fbx", False, "animada"),
    "animada": ("Excited.fbx", False, "animada"),
    "perder": ("Defeated.fbx", False, "triste"),
    "pular": ("jump.fbx", False, "animada"),
    "treino_vel": ("Fast Run.fbx", True, "correr"),
    "treino_est": ("Jumping Jacks.fbx", False, "animada"),
    "treino_pod": ("Air Squat.fbx", False, "calma"),
    "treino_det": ("Burpee.fbx", False, "calma"),
    "treino_int": ("Thinking.fbx", False, "calma"),
    "prancha": ("Plank.fbx", False, "calma"),
    "sentar": ("Sitting.fbx", False, "calma"),
    "bocejar": ("Yawn.fbx", False, "calma"),
    "apoio": ("weight shift.fbx", False, "calma"),
    "sim": ("head nod yes.fbx", False, "animada"),
    "nao": ("shaking head no.fbx", False, "calma"),
    "concordar": ("acknowledging.fbx", False, "calma"),
    "brava": ("angry gesture.fbx", False, "brava"),
    "irritada": ("annoyed head shake.fbx", False, "brava"),
    "convencida": ("being cocky.fbx", False, "animada"),
    "desdenhar": ("dismissing gesture.fbx", False, "brava"),
    "gesto_feliz": ("happy hand gesture.fbx", False, "animada"),
    "suspiro": ("relieved sigh.fbx", False, "calma"),
    "desviar_olhar": ("look away gesture.fbx", False, "triste"),
    "sarcasmo": ("sarcastic head nod.fbx", False, "calma"),
    "pensativa": ("thoughtful head shake.fbx", False, "calma"),
}


def _rot(m):
    return m.to_3x3().normalized()


def _limpar_importados(antes_obj, antes_act):
    for o in list(bpy.data.objects):
        if o.name not in antes_obj:
            bpy.data.objects.remove(o, do_unlink=True)
    for a in list(bpy.data.actions):
        if a.name not in antes_act:
            bpy.data.actions.remove(a)
    for arm in list(bpy.data.armatures):
        if arm.users == 0:
            bpy.data.armatures.remove(arm)


def _curvas(acao, rig):
    """Garante as F-curves de rotação e posição de cada osso e devolve {(osso, prop, i): fcurve}."""
    curvas = {}
    for pb in rig.pose.bones:
        if pb.name.startswith("eye."):  # os olhos ficam livres para o jogo mexer (olhar)
            continue
        for prop, n in (("rotation_quaternion", 4), ("location", 3)):
            caminho = f'pose.bones["{pb.name}"].{prop}'
            for i in range(n):
                fc = acao.fcurve_ensure_for_datablock(rig, caminho, index=i, group_name=pb.name)
                curvas[(pb.name, prop, i)] = fc
    return curvas


def _gravar(curvas, amostras):
    """amostras: {(osso, prop, i): [(quadro, valor), ...]}"""
    for chave, pts in amostras.items():
        fc = curvas[chave]
        fc.keyframe_points.clear()
        fc.keyframe_points.add(len(pts))
        co = [c for p in pts for c in p]
        fc.keyframe_points.foreach_set("co", co)
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
        fc.update()


def _camada(tipo, t, i_osso, eh_orelha, lado):
    """Rotação procedural (eixo do mundo, graus) para rabo e orelhas. t em segundos."""
    if eh_orelha:
        base = {"calma": 0, "andar": 0, "correr": -20, "animada": 8, "triste": -35, "brava": -25}[tipo]
        tremida = 10 if (tipo == "animada" and (t * 3) % 1 < 0.15) else 0
        return [("X", base), ("Y", -lado * (3 * math.sin(t * 1.7 + lado) + tremida))]
    fase = t * (2.6 if tipo in ("correr", "animada") else 1.2) - i_osso * 0.55
    if tipo == "correr":
        return [("X", -36 if i_osso == 1 else -12), ("Z", 8 * math.sin(fase * math.pi))]
    if tipo == "triste":
        return [("X", 22 if i_osso == 1 else 6), ("Z", 3 * math.sin(fase))]
    amp = 9 if tipo == "animada" else 6
    return [("Z", amp * math.sin(fase))]


def retargetar(rig, caminho_fbx, nome, tirar_deslocamento, tipo, fps=30):
    antes_obj = {o.name for o in bpy.data.objects}
    antes_act = {a.name for a in bpy.data.actions}
    bpy.ops.import_scene.fbx(filepath=caminho_fbx)
    src = next(o for o in bpy.data.objects if o.name not in antes_obj and o.type == "ARMATURE")
    acao_src = src.animation_data.action
    q0, q1 = (int(round(x)) for x in acao_src.frame_range)
    prefixo = next(b.name for b in src.data.bones if b.name.endswith("Hips"))[:-4]
    sw = _rot(src.matrix_world)

    # repouso: direção e orientação no mundo
    def rest_src(nome_m):
        b = src.data.bones[prefixo + nome_m]
        return sw @ _rot(b.matrix_local), (sw @ (b.tail_local - b.head_local)).normalized()

    t_rest = {b.name: _rot(b.matrix_local) for b in rig.data.bones}  # rig sem transformação de objeto
    t_dir = {b.name: (b.tail_local - b.head_local).normalized() for b in rig.data.bones}
    ref = {}
    s_rest = {}
    for alvo, m in MAPA.items():
        r, d = rest_src(m)
        s_rest[alvo] = r
        alinhar = t_dir[alvo].rotation_difference(d).to_matrix()
        ref[alvo] = alinhar @ t_rest[alvo]

    hips_src = src.pose.bones[prefixo + "Hips"]
    altura_src = (src.matrix_world @ src.data.bones[prefixo + "Hips"].head_local).z
    altura_alvo = rig.data.bones["hips"].head_local.z
    escala = altura_alvo / max(altura_src, 1e-4)
    hips_rest_src = src.matrix_world @ src.data.bones[prefixo + "Hips"].head_local

    quadros = list(range(q0, q1 + 1))
    if len(quadros) > 150:  # parada longa: 15 quadros por segundo já basta, o Godot interpola
        quadros = quadros[::2] + ([q1] if quadros[-1] != q1 else [])
    cena = bpy.context.scene
    desloc = []
    poses = []
    for f in quadros:
        cena.frame_set(f)
        poses.append({alvo: sw @ _rot(src.pose.bones[prefixo + m].matrix) for alvo, m in MAPA.items()})
        desloc.append((src.matrix_world @ hips_src.head) - hips_rest_src)
    if tirar_deslocamento and len(desloc) > 1:
        # tira a tendência linear (o caminhar para frente) e deixa só o balanço
        n = len(desloc)
        ini, fim = desloc[0], desloc[-1]
        for k in range(n):
            tend = ini.lerp(fim, k / (n - 1))
            desloc[k] = Vector((desloc[k].x - tend.x, desloc[k].y - tend.y, desloc[k].z))

    pais = {b.name: (b.parent.name if b.parent else None) for b in rig.data.bones}
    amostras = {}

    def add(chave, f, v):
        amostras.setdefault(chave, []).append((f, v))

    orelhas = {"ear.L": 1, "ear.R": -1}
    rabo = [b.name for b in rig.data.bones if b.name.startswith("tail.")]
    for k, f in enumerate(quadros):
        quadro = f - q0 + 1
        t = (f - q0) / fps
        mundo = {}
        for b in rig.data.bones:  # pais antes dos filhos (ordem de criação)
            nome_b = b.name
            if nome_b.startswith("eye."):
                continue
            pai = pais[nome_b]
            p_rest = t_rest[pai] if pai else Matrix.Identity(3)
            p_pose = mundo.get(pai, p_rest) if pai else Matrix.Identity(3)
            if nome_b in MAPA:
                delta = poses[k][nome_b] @ s_rest[nome_b].inverted()
                alvo_w = delta @ ref[nome_b]
                base = t_rest[nome_b].inverted() @ p_rest @ p_pose.inverted() @ alvo_w
                q = base.to_quaternion()
            elif nome_b in orelhas or nome_b in rabo:
                rots = _camada(tipo, t, rabo.index(nome_b) + 1 if nome_b in rabo else 0, nome_b in orelhas,
                               orelhas.get(nome_b, 0))
                q = Quaternion()
                for eixo, g in rots:
                    r = Matrix.Rotation(math.radians(g), 3, eixo)
                    q = (t_rest[nome_b].inverted() @ r @ t_rest[nome_b]).to_quaternion() @ q
            else:
                q = Quaternion()
            mundo[nome_b] = p_pose @ p_rest.inverted() @ t_rest[nome_b] @ q.to_matrix()
            for i in range(4):
                add((nome_b, "rotation_quaternion", i), quadro, q[i])
            loc = Vector()
            if nome_b == "hips":
                loc = t_rest["hips"].inverted() @ (desloc[k] * escala)
            for i in range(3):
                add((nome_b, "location", i), quadro, loc[i])

    _limpar_importados(antes_obj, antes_act)
    acao = bpy.data.actions.new(nome)
    acao.use_fake_user = True
    if rig.animation_data is None:
        rig.animation_data_create()
    rig.animation_data.action = acao
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
    _gravar(_curvas(acao, rig), amostras)
    acao.frame_range = (1, quadros[-1] - q0 + 1)
    rig.animation_data.action = None
    return acao


def retargetar_tudo(rig, pasta, lista=ANIMACOES):
    acoes = []
    for nome, (arquivo, tirar, tipo) in lista.items():
        caminho = os.path.join(pasta, arquivo)
        if not os.path.exists(caminho):
            print("[retarget] falta:", arquivo)
            continue
        acoes.append(retargetar(rig, caminho, nome, tirar, tipo))
        print(f"[retarget] {nome:14s} <- {arquivo}  ({int(acoes[-1].frame_range[1])} quadros)")
    return acoes
