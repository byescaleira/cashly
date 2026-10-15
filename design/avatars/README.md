# Avatares do Cashly

Os 100 avatares ilustrados do perfil (além das iniciais e dos símbolos) são personagens gerados com a skill [`ip-as-logo`](https://github.com/s1dashu/ip-as-logo-skill), em 10 seções de 10.

## Gerar

1. No Codex (ou outro agente compatível com Agent Skills) instale a skill: `npx skills@latest add s1dashu/ip-as-logo-skill --global`.
2. Use um modelo de imagem de ponta (de preferência GPT Image 2).
3. Para cada item de `prompts.md`, gere **uma** imagem com o prompt exato e salve como PNG quadrado (1024 px ou mais) com o nome indicado, em `design/avatars/generated/`. A composição foi ajustada para avatar circular (personagem centralizado subindo pela base), então peça ao agente para seguir o prompt sem trocar para canto inferior.
4. Gere uma seção por vez e confira antes de seguir. Para refazer um avatar, gere de novo com o mesmo prompt e substitua o arquivo.

## Importar

`python3 design/avatars/import.py [tamanho]` confere que os 100 arquivos existem (`--allow-missing` importa o que houver), reduz para JPEG de 360 px, qualidade 85 (padrão; o fundo é sólido e o app recorta o círculo) e recria o catálogo `CashlyResource/Assets/Media.xcassets/Avatars` com `avatar-<seção>-<nn>`.

## Editar a lista

As seções, os bichos, as cores do personagem e os fundos ficam em `generate_prompts.py`. Rode-o para regenerar `prompts.md` e `manifest.json` (o manifesto é a fonte de verdade que o app e o importador usam).
