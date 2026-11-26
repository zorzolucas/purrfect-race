# Plano: o jogo rodando num site

Objetivo: abrir um link e jogar o protótipo no navegador, sem instalar nada, com o
site atualizado sozinho a cada merge na `main`.

## Resumo

- **Dá para fazer, e já foi testado.** Em 2026-11-26 o projeto foi exportado para
  Web com o Godot 4.7.2 na nuvem, sem mudar nenhum script, e rodou no Chromium:
  tela de escolha, guia, academia, e o save continuou lá depois de recarregar a
  página.
- **Recomendação:** GitHub Pages, com deploy automático por GitHub Actions, em
  `https://zorzolucas.github.io/stelar-gallop/jogo/`. Custo zero (o repositório é
  público). itch.io como segunda vitrine, se quiser mostrar para outras pessoas.
- **Download:** cerca de 63 MB brutos, **34 MB comprimidos** (gzip). Dá para
  baixar para uns 20 a 25 MB com as otimizações da etapa 4.
- **Trabalho estimado:** etapas 1 a 3 cabem num PR pequeno (meio dia). As etapas 4
  e 5 são melhorias opcionais.

## O que já está a favor

| Ponto | Situação no repositório | Efeito na Web |
|---|---|---|
| Renderer | `gl_compatibility` no `project.godot` | É o único que roda na Web (WebGL 2). Nada a mudar. |
| Linguagem | Só GDScript, nenhum `.cs` | C# não exporta para Web no Godot 4. Sem problema aqui. |
| Modelos 3D | `modelos/*.glb` com ~2,6 MB cada (já reduzidos no PR #30) | Os .glb de 60 MB do Tripo ficam fora; no pacote entram ~1,3 MB de malha + ~1,2 MB de textura por garota. |
| Arte bruta | `arte/` tem `.gdignore` | Os 37 MB de conceito/Blender não entram no pacote. |
| Saves | `user://` em `perfil.gd` e `carreira.gd` | Vira IndexedDB do navegador automaticamente. Testado: o save sobrevive ao recarregar. |
| Threads | Jogo por turnos, sem `Thread` | Export **sem threads** funciona, e aí não precisa dos headers COOP/COEP (que o GitHub Pages não deixa configurar). |
| Áudio | O jogo ainda não tem som | Nada a resolver agora. Quando tiver: o navegador só libera áudio depois do primeiro clique. |
| Dados | JSON lidos de `res://data/` com `FileAccess` | JSON não é "recurso" do Godot: precisa do filtro `data/*.json` no preset. Com ele, carregou certo. |

Medição do export (release, sem threads):

| Arquivo | Bruto | gzip |
|---|---|---|
| `index.wasm` (motor) | 39,5 MB | 10,1 MB |
| `index.pck` (jogo) | 24,1 MB | 23,7 MB |
| js/html/ícones | 0,3 MB | ~0,1 MB |
| **Total** | **~63 MB** | **~34 MB** |

O `.pck` quase não comprime porque as texturas já vão comprimidas. Os 8 modelos
respondem por ~21 MB dele (malha + textura).

## Etapas

### 1. Preset de export Web (no repositório)

Criar `export_presets.cfg` com um preset "Web":

- `variant/thread_support=false` (sem threads, dispensa COOP/COEP)
- `include_filter="data/*.json"` (os dados do jogo)
- `exclude_filter="testes/*, tools/*, visualizador/*, docs/*, arte/*"`
- `html/canvas_resize_policy=2` (o jogo ocupa a janela toda; o stretch
  `canvas_items` + `expand` que já existe cuida da proporção)

O preset usado no teste está no apêndice. Com ele, o Lucas também consegue
exportar pelo editor no PC (Projeto > Exportar > Web), depois de instalar os
templates de export do 4.7.2 pelo próprio editor.

### 2. Deploy automático (GitHub Actions + Pages)

Workflow novo `.github/workflows/site.yml`, a cada push na `main`:

1. Baixa o Godot 4.7.2 e só os templates Web (com cache, igual ao `testes.yml`).
2. `godot --headless --path . --import` e
   `godot --headless --path . --export-release "Web" build/site/jogo/index.html`.
3. Monta o site: `index.html` da raiz (página inicial com links), `jogo/` e o
   `visualizador/` que já existe.
4. Publica com `actions/upload-pages-artifact` + `actions/deploy-pages`.

Ação única do Lucas: em Settings > Pages, escolher **Source: GitHub Actions**.
O `index.html` da raiz hoje só redireciona para o visualizador; ele vira uma
página com dois botões ("Jogar" e "Visualizador da corrida").

Opcional: um export de cada PR como artefato do Actions, para testar antes do
merge.

### 3. Ajustes de navegador (pequenos)

- **Teclas que o navegador usa:** F1 abre o guia (`main.gd`) e Esc fecha telas
  (`tela_guia.gd`, `tela_carreira.gd`). No navegador, Esc também sai da tela
  cheia e F1 pode abrir a ajuda do Chrome. Já existem botões na tela para as duas
  coisas ("Como jogar", "Fechar"); vale conferir que toda ação por tecla tem
  botão.
- **Tela cheia:** botão de tela cheia no menu (precisa vir de um clique).
- **Tela de carregamento:** trocar o logo padrão do Godot (`index.png`) por uma
  arte do jogo e o título pelo nome do jogo (`html/head_include` ou um shell HTML
  próprio).
- **Aviso de save:** dizer na página que o progresso fica no navegador.

### 4. Otimização do download (opcional)

Em ordem de custo/benefício:

1. **Texturas das garotas:** importar as 8 `*_garota_textura.jpg` em 512 px ou
   como WebP com perda. A câmera de corrida mostra as garotas pequenas. Corta
   perto de 8 MB.
2. **Malhas:** as cenas importadas têm ~1,3 MB cada, provavelmente por levarem as 31 animações cada uma (a conferir).
   Compartilhar uma `AnimationLibrary` única entre as 8 (o esqueleto já é o
   mesmo) tira as cópias repetidas. Corta 5 a 8 MB.
3. **Compressão melhor:** hosts que servem Brotli (Netlify, itch.io) baixam o
   `.wasm` para ~7 MB. No GitHub Pages fica gzip.
4. **Motor sob medida:** compilar um template Web sem módulos não usados (física
   3D avançada, navegação, XR etc.) reduz o `.wasm` de 39 para ~25 MB. Exige
   compilar o Godot com Emscripten no CI; só vale se o tamanho incomodar.

### 5. Celular (opcional, depois)

- O toque já vira clique (padrão do Godot), então os botões funcionam.
- A tela é 1280x720 deitada; no celular em pé fica pequena. Mostrar um aviso
  "gire o celular" e testar se os textos ficam legíveis.
- Texturas: o export comprime para desktop (S3TC). Celular que não tem S3TC
  descomprime ao carregar (funciona, mas usa mais memória). Se o iPhone sofrer,
  ligar também ETC2 no preset (aumenta o download) ou usar WebP (item 4.1).
- Testar num iPhone e num Android médio: o 3D com 8 garotas animadas é o ponto
  mais pesado.

## Hospedagem: comparação

| Opção | Custo | Prós | Contras |
|---|---|---|---|
| **GitHub Pages** (recomendado) | Grátis | Tudo no repo, deploy no mesmo Actions, junto do visualizador | Sem headers próprios (por isso o export sem threads); só gzip; limite de 1 GB de site e ~100 GB/mês de tráfego, sobra |
| Vercel (já ligado ao repo) | Grátis (plano Hobby, uso não comercial) | Já publica cada PR com link de preview; aceita headers próprios (`vercel.json`) e Brotli | O build da Vercel não tem Godot: o export teria que rodar no Actions e subir com `vercel deploy --prebuilt` (precisa de token como segredo). Conferir o limite de tamanho de arquivo do plano antes |
| itch.io | Grátis | Vitrine de jogos, tem opção de SharedArrayBuffer, Brotli | Upload manual ou via `butler` no CI (precisa de chave de API como segredo) |
| Netlify | Grátis (100 GB/mês) | Headers próprios, Brotli, preview por PR | Mais uma conta e um token |
| Cloudflare Pages | Grátis | Rápido | **Limite de 25 MB por arquivo**: o `.wasm` (39,5 MB) não passa sem motor sob medida |

**Observação:** o repositório já tem a Vercel ligada (ela comentou no PR #37 com um
preview, que hoje só mostra o visualizador). Se o Lucas preferir manter tudo na
Vercel, ela vira a alternativa principal: ganha preview do jogo em cada PR, mas
custa configurar um token. Sem isso, o GitHub Pages continua o caminho mais
simples.

## Riscos

| Risco | Chance | O que fazer |
|---|---|---|
| Save some: o Safari apaga dados de sites não visitados por 7 dias; limpar dados do navegador apaga tudo | Média | Botão "Exportar/Importar save" (baixa e lê o JSON via `JavaScriptBridge`) |
| Save de versão antiga quebra depois de um deploy | Média | Campo de versão no save e migração/descarte com aviso |
| Carregamento lento no 4G (~34 MB) | Média | Etapa 4; tela de carregamento com barra (o Godot já mostra progresso) |
| 3D pesado em celular fraco | Média | Testar cedo (etapa 5); opção de qualidade baixa (menos garotas animadas, sombras off) |
| Cache do navegador servindo versão velha | Baixa | O Godot já usa nomes fixos; colocar a versão no caminho (`jogo/?v=<commit>`) ou desligar cache do `.pck` |
| Atalhos F1/Esc brigando com o navegador | Baixa | Botões na tela (etapa 3) |

## Fora do escopo agora

- Multiplayer ou ranking online (precisaria de servidor).
- PWA instalável (o Godot gera, mas complica o cache de versões; dá para ligar
  depois).

## Apêndice: preset usado no teste

```ini
[preset.0]

name="Web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter="data/*.json"
exclude_filter="testes/*, tools/*, visualizador/*, docs/*, arte/*"
export_path="build/web/index.html"

[preset.0.options]

variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
progressive_web_app/enabled=false
```

Comando usado: `godot --headless --path . --export-release "Web" build/web/index.html`
(depois de `--import`), com os templates `web_nothreads_release.zip` do 4.7.2 em
`~/.local/share/godot/export_templates/4.7.2.stable/`.
