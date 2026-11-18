"""Sobrepõe a silhueta do modelo à da ficha conceitual (frente e lado), na mesma escala.

1) Blender renderiza as silhuetas do modelo:
   blender --background arte/lira.blend --python tools/blender/comparar_ficha.py -- render <pasta>
2) Python compara com a ficha e grava a sobreposição:
   python tools/blender/comparar_ficha.py compor <pasta> <ficha.png>

Azul = só a ficha, vermelho = só o modelo, roxo = os dois. Imprime a largura das partes por altura.
"""
import os
import sys

RES = 1000          # pixels de altura da renderização
ESCALA = 1.8        # metros cobertos pela câmera ortográfica (altura)
VISTAS = {"frente": ((0, -1, 0), 0.12, 0.50), "lado": ((1, 0, 0), 0.60, 0.88)}  # direção, faixa da ficha


def render(pasta):
    import bpy
    from mathutils import Vector
    os.makedirs(pasta, exist_ok=True)
    cena = bpy.context.scene
    cena.render.engine = "BLENDER_WORKBENCH"
    cena.render.film_transparent = True
    cena.render.resolution_x = cena.render.resolution_y = RES
    cena.display.shading.light = "FLAT"
    cena.display.shading.color_type = "SINGLE"
    for o in bpy.data.objects:
        if o.name.endswith("Contorno"):
            o.hide_render = True
    cam_d = bpy.data.cameras.new("CamSil")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = ESCALA
    cam = bpy.data.objects.new("CamSil", cam_d)
    cena.collection.objects.link(cam)
    cena.camera = cam
    centro = Vector((0, 0, ESCALA / 2))
    for nome, (d, _, _) in VISTAS.items():
        d = Vector(d)
        cam.location = centro - d * 5
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        cena.render.filepath = os.path.join(pasta, f"modelo_{nome}.png")
        bpy.ops.render.render(write_still=True)


def compor(pasta, ficha):
    import numpy as np
    from PIL import Image
    from scipy import ndimage

    def mascara_ficha(img, x0, x1):
        a = np.asarray(img.convert("RGB")).astype(float)
        h, w, _ = a.shape
        a = a[:, int(x0 * w):int(x1 * w)]
        escuro = a.mean(axis=2) < 95
        # linha do chão: a linha escura mais larga da metade de baixo
        larg = escuro.sum(axis=1)
        chao = h // 2 + int(np.argmax(larg[h // 2:]))
        escuro[chao - 3:] = False
        cont = ndimage.binary_dilation(escuro, iterations=1)
        rot, _ = ndimage.label(~cont)
        bordas = set(np.unique(np.concatenate([rot[0], rot[-1], rot[:, 0], rot[:, -1]]))) - {0}
        fig = ~np.isin(rot, list(bordas))
        fig[chao - 3:] = False
        rot2, n = ndimage.label(fig)
        tam = ndimage.sum(fig, rot2, range(1, n + 1))
        return rot2 == (1 + int(np.argmax(tam))), chao

    def caixa(m):
        ys = np.where(m.any(axis=1))[0]
        xs = np.where(m.any(axis=0))[0]
        return ys[0], ys[-1], xs[0], xs[-1]

    img = Image.open(ficha)
    for nome, (_, x0, x1) in VISTAS.items():
        fig, _ = mascara_ficha(img, x0, x1)
        mod = np.asarray(Image.open(os.path.join(pasta, f"modelo_{nome}.png")))[..., 3] > 128
        if nome == "lado":  # na ficha o perfil olha para a esquerda
            mod = mod[:, ::-1]
        ft, fb, fl, fr = caixa(fig)
        mt, mb, ml, mr = caixa(mod)
        # escala pela altura total (chão ao topo das orelhas), alinhando chão e centro
        s = (fb - ft) / (mb - mt)
        mod_img = Image.fromarray((mod * 255).astype(np.uint8))
        nw, nh = int(mod.shape[1] * s), int(mod.shape[0] * s)
        mod_s = np.asarray(mod_img.resize((nw, nh), Image.NEAREST)) > 128
        tela = np.zeros_like(fig)
        mt2, mb2, ml2, mr2 = caixa(mod_s)
        dy = fb - mb2
        # alinha pelo centro das pernas (entre 15% e 35% da altura), que não tem rabo nem braços
        def centro_pernas(m, base, alt):
            faixa = m[int(base - 0.35 * alt):int(base - 0.15 * alt)]
            return np.where(faixa)[1].mean()
        dx = int(round(centro_pernas(fig, fb, fb - ft) - centro_pernas(mod_s, mb2, mb2 - mt2)))
        ys, xs = np.where(mod_s)
        ys2, xs2 = ys + dy, xs + dx
        ok = (ys2 >= 0) & (ys2 < tela.shape[0]) & (xs2 >= 0) & (xs2 < tela.shape[1])
        tela[ys2[ok], xs2[ok]] = True
        rgb = np.full(fig.shape + (3,), 255, np.uint8)
        rgb[fig & ~tela] = (70, 120, 230)
        rgb[tela & ~fig] = (230, 70, 60)
        rgb[fig & tela] = (150, 90, 170)
        Image.fromarray(rgb).save(os.path.join(pasta, f"comparar_{nome}.png"))
        altura_m = 1.68
        px_m = (fb - ft) / altura_m
        print(f"== {nome}: px/m {px_m:.1f}  diferença de área {((fig ^ tela).sum() / fig.sum()):.2%}")
        for z in np.arange(0.04, altura_m, 0.08):
            y = int(fb - z * px_m)

            def runs(linha):
                xs = np.where(linha)[0]
                if not len(xs):
                    return []
                cortes = np.where(np.diff(xs) > 1)[0]
                ini = np.concatenate([[xs[0]], xs[cortes + 1]])
                fim = np.concatenate([xs[cortes], [xs[-1]]])
                return [round((b - a + 1) / px_m, 3) for a, b in zip(ini, fim)]
            print(f"  z {z:4.2f}  ficha {runs(fig[y])}  modelo {runs(tela[y])}")


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    if args[0] == "render":
        render(args[1])
    else:
        compor(args[1], args[2])
