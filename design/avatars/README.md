# Avatares do Cashly

As 220 ilustrações de perfil, além das iniciais e dos símbolos (200 em 9 seções e 20 na seção Ouro, exclusiva do Cashly Pro), vêm da biblioteca [ipaslogo.com](https://ipaslogo.com), feita com a skill `ip-as-logo` (s1dashu/ip-as-logo-skill, MIT). O site declara as imagens livres para download e uso comercial; o crédito fica na tela Sobre.

- `select_ipaslogo.py [catálogo]`: escolhe 200 bichos em 9 seções (Cats, Dogs, Forest, Farm, Ocean, Birds, Jungle, Tiny Friends, Fantasy) a partir do catálogo do site (`ipaslogo-catalog.json`, a lista pública que o site carrega), baixa a versão de 512 px em webp para `downloaded/` (fora do git) e grava `manifest.json` com a origem de cada imagem.
- `import.py [tamanho] [--allow-missing]`: converte para JPEG de 360 px, qualidade 85 (o fundo é sólido e o app recorta o círculo), e recria o catálogo `CashlyResource/Assets/Media.xcassets/Avatars` com `avatar-<seção>-<nn>`.

`manifest.json` é a fonte de verdade das seções e dos ids que o app usa.
- `select_gold.py [catálogo]`: acrescenta ao `manifest.json` a seção exclusiva do Cashly Pro (`gold`, 20 bichos dourados escolhidos por aparência, lista fixa no script) e baixa as imagens que faltam. Para importar só essa seção sem regerar as outras, converta as entradas `gold` como o `import.py` faz.
