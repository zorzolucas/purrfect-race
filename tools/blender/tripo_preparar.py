"""Etapa 1 do import dos modelos do Tripo (arte/3d/*.glb): orienta, põe na altura, reduz a malha.

Os modelos do Tripo vêm com ~2 milhões de triângulos (facetas chapadas subdivididas) e textura
8K. Aqui a malha cai para ~TRIS triângulos (o visual low-poly é o mesmo) e a textura vai para
TEX px. O resultado (.blend) segue para tools/blender/tripo_rig.py.

    python tools/blender/tripo_preparar.py <entrada.glb> <saida.blend> [tris] [tex]
"""
import math
import sys

import bpy
from mathutils import Matrix, Vector

ALTURA = 1.6
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
ENTRADA, SAIDA = args[0], args[1]
TRIS = int(args[2]) if len(args) > 2 else 14000
TEX = int(args[3]) if len(args) > 3 else 1024

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=ENTRADA)
malhas = [o for o in bpy.context.scene.objects if o.type == "MESH"]
assert len(malhas) == 1, malhas
obj = malhas[0]
for o in list(bpy.context.scene.objects):
    if o is not obj:
        bpy.data.objects.remove(o, do_unlink=True)
obj.parent = None
mw = obj.matrix_world.copy()
obj.data.transform(mw)
obj.matrix_world = Matrix.Identity(4)
obj.name = "Corpo"

import numpy as np  # noqa: E402

def verts():
    a = np.empty(len(obj.data.vertices) * 3)
    obj.data.vertices.foreach_get("co", a)
    return a.reshape(-1, 3)

v = verts()
mn, mx = v.min(0), v.max(0)
# o Tripo deixa a altura no eixo maior; Blender já converteu Y-up -> Z-up
alt = mx[2] - mn[2]
# frente: rabo e cabelo comprido ficam atrás, então o lado da profundidade que vai mais longe
# do centro (na faixa do meio do corpo) é as costas. A largura (braços em A) é o eixo mais largo.
meio = v[(v[:, 2] > mn[2] + 0.25 * alt) & (v[:, 2] < mn[2] + 0.75 * alt)]
lx = np.percentile(meio[:, 0], 99.5) - np.percentile(meio[:, 0], 0.5)
ly = np.percentile(meio[:, 1], 99.5) - np.percentile(meio[:, 1], 0.5)
eixo = 1 if lx > ly else 0  # índice do eixo de profundidade
d = meio[:, eixo] - np.median(meio[:, eixo])
costas_pos = np.percentile(d, 99.5) > -np.percentile(d, 0.5)
# queremos as costas em +Y (frente em -Y)
if eixo == 1:
    rot = Matrix.Identity(4) if costas_pos else Matrix.Rotation(math.pi, 4, "Z")
else:
    # costas em +X -> gira +90 (X vira Y); costas em -X -> gira -90
    rot = Matrix.Rotation(math.radians(90 if costas_pos else -90), 4, "Z")
obj.data.transform(rot)
v = verts()
mn, mx = v.min(0), v.max(0)
s = ALTURA / (mx[2] - mn[2])
pes = v[v[:, 2] < mn[2] + 0.06 * (mx[2] - mn[2])]
cx = (pes[:, 0].min() + pes[:, 0].max()) / 2
cy = np.median(pes[:, 1])
obj.data.transform(Matrix.Diagonal((s, s, s, 1)) @ Matrix.Translation((-cx, -cy, -mn[2])))
obj.data.update()

n0 = sum(len(p.vertices) - 2 for p in obj.data.polygons)
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0001)
bpy.ops.object.mode_set(mode="OBJECT")
mod = obj.modifiers.new("dec", "DECIMATE")
mod.decimate_type = "COLLAPSE"
mod.ratio = min(1.0, TRIS / n0)
mod.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier=mod.name)
n1 = len(obj.data.polygons)
for p in obj.data.polygons:
    p.use_smooth = False

# textura: 8K -> TEX
mat = obj.data.materials[0]
mat.name = "Garota"
img = next(n.image for n in mat.node_tree.nodes if n.type == "TEX_IMAGE")
if img.size[0] > TEX:
    img.scale(TEX, TEX)
img.name = "garota_textura"
img.file_format = "PNG"
img.pack()
print(f"[preparar] {ENTRADA}: {n0} -> {n1} triângulos, textura {img.size[0]}px")
bpy.ops.wm.save_as_mainfile(filepath=SAIDA)
