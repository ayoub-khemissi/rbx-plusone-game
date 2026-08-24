# Textures

Le pack que tu as importé arrive sous forme de **blocs de présentation** : 482 parts
qui ne servent qu'à montrer les textures. Tu n'as besoin d'aucun de ces blocs pour
construire ta map — seulement des identifiants, et ils sont tous ci-dessous.

> **Supprime le modèle `Textures` du Workspace** une fois ce document sous la main.
> Ce sont 3894 instances chargées chez chaque joueur, pour rien.

---

## Poser une texture sur TES parts

### La bonne méthode : un Material Variant

C'est la réponse à « je veux la texture, pas le bloc ». Un Material Variant est une
matière que tu crées une fois et que tu appliques ensuite à n'importe quelle part,
exactement comme Brique ou Bois.

1. Dans Studio, ouvre **View → Material Manager**
2. Choisis une matière de base dans la colonne de gauche (`Plastic` convient à tout)
3. Clique le **+** en haut du panneau : un `MaterialVariant` apparaît
4. Renomme-le (`StoneFloor`, `LavaRock`…) — c'est ce nom que tu reverras partout
5. Colle l'identifiant du catalogue dans le champ **ColorMap**
6. Règle **StudsPerTile** : la taille d'un carreau en studs. 4 est un bon départ pour
   un sol, 8 pour un mur vu de loin

Pour peindre ensuite : sélectionne tes parts et clique la matière dans le Material
Manager. La texture couvre les **six faces**, se répète toute seule quelle que soit la
taille de la part, et te suit quand tu redimensionnes.

**Pourquoi pas les objets `Texture`** — ceux que le pack utilise sur ses blocs de
démo : un `Texture` ne couvre qu'**une seule face**. Un cube en demande six, un
parcours de 300 parts en demande 1800, et chacun est une instance de plus à
répliquer. Le Material Variant en demande un, pour toute la map.

### Le cas particulier des matières PBR

Les 10 matières `PBRTextures` ne sont pas des images plates mais des
`SurfaceAppearance` : elles réagissent à la lumière (relief, brillance, métal). Elles
ne s'appliquent qu'à des **MeshPart**, jamais à une part ordinaire. Pour en garder
une, copie le `SurfaceAppearance` depuis son bloc de démo et colle-le dans ton
MeshPart **avant** de supprimer le pack.

### Ce que ça ne change pas

Aucune texture ne change quoi que ce soit au jeu. Le serveur ne lit que les **tags**
décrits dans [MAP.md](MAP.md) : une part magnifique sans tag `TrapPart` ne tue
personne, une part grise avec le tag tue très bien. Décore quand la géométrie
fonctionne, pas avant.

---

## Le catalogue

La colonne *carreau* reprend le `StudsPerTile` d'origine du pack : un point de
départ, pas une règle.

### Sols

| Nom | ColorMap | Carreau |
| --- | --- | --- |
| Floor A | `rbxassetid://248762273` | 1 |
| Floor B | `rbxassetid://76344979` | 1 |
| Floor C | `rbxassetid://27081546` | 1 |
| Floor D | `rbxassetid://117898943` | 1 |
| Floor E | `rbxassetid://83821818` | 1 |
| Floor F | `rbxassetid://1238075178` | 1 |
| Floor G | `rbxassetid://227806539` | 1 |
| Floor H | `rbxassetid://5138117462` | 1 |
| Floor I | `rbxassetid://6803357159` | 1 |
| Floor J | `rbxassetid://227806552` | 1 |
| Floor K | `rbxassetid://147149558` | 1 |
| Floor L | `rbxassetid://3222084099` | 1 |

### Murs

| Nom | ColorMap | Carreau |
| --- | --- | --- |
| Wall A | `rbxassetid://6768888247` | 1 |
| Wall B | `rbxassetid://137638982` | 1 |
| Wall C | `rbxassetid://6778948163` | 1 |
| Wall D | `rbxassetid://45115488` | 1 |
| Wall E | `rbxassetid://118774827` | 1 |
| Wall F | `rbxassetid://2423746253` | 1 |
| Wall G | `rbxassetid://6803349963` | 1 |
| Wall H | `rbxassetid://6803328432` | 1 |
| Wall I | `rbxassetid://47612638` | 1 |
| Wall J | `rbxassetid://5808312383` | 1 |
| Wall K | `rbxassetid://6880167231` | 1 |
| Wall L | `rbxassetid://136131018` | 1 |

### Plafonds

| Nom | ColorMap | Carreau |
| --- | --- | --- |
| Ceiling A | `rbxassetid://5120598571` | 1 |
| Ceiling B | `rbxassetid://324269515` | 1 |
| Ceiling C | `rbxassetid://3188977793` | 1 |
| Ceiling D | `rbxassetid://62793748` | 1 |
| Ceiling E | `rbxassetid://7307419972` | 1 |
| Ceiling F | `rbxassetid://1621958515` | 1 |
| Ceiling G | `rbxassetid://6774490996` | 1 |
| Ceiling H | `rbxassetid://6843024065` | 1 |
| Ceiling I | `rbxassetid://6859141178` | 1 |
| Ceiling J | `rbxassetid://7370047147` | 1 |
| Ceiling K | `rbxassetid://276587759` | 1 |
| Ceiling L | `rbxassetid://3059769545` | 1 |

### Toits

| Nom | ColorMap | Carreau |
| --- | --- | --- |
| Roof A | `rbxassetid://4971127464` | 1 |
| Roof B | `rbxassetid://4971114520` | 1 |
| Roof C | `rbxassetid://2875933` | 1 |
| Roof D | `rbxassetid://6465058128` | 1 |
| Roof E | `rbxassetid://92574443` | 1 |
| Roof F | `rbxassetid://736580931` | 1 |
| Roof G | `rbxassetid://145560459` | 1 |
| Roof H | `rbxassetid://5342286207` | 1 |
| Roof I | `rbxassetid://6738995` | 1 |
| Roof J | `rbxassetid://2695627581` | 1 |
| Roof K | `rbxassetid://738060692` | 1 |
| Roof L | `rbxassetid://736594463` | 1 |

### Terrains

| Nom | ColorMap | Carreau |
| --- | --- | --- |
| Terrain A | `rbxassetid://736593217` | 1 |
| Terrain B | `rbxassetid://122076991` | 1 |
| Terrain C | `rbxassetid://152538736` | 1 |
| Terrain D | `rbxassetid://6917005656` | 1 |
| Terrain E | `rbxassetid://6277758528` | 1 |
| Terrain F | `rbxassetid://96526835` | 1 |
| Terrain G | `rbxassetid://259213301` | 1 |
| Terrain H | `rbxassetid://104943746` | 1 |
| Terrain I | `rbxassetid://2222799730` | 1 |
| Terrain J | `rbxassetid://198207073` | 1 |
| Terrain K | `rbxassetid://465111359` | 1 |
| Terrain L | `rbxassetid://5837480614` | 1 |

### Verres et surfaces translucides

| Nom | ColorMap | Carreau |
| --- | --- | --- |
| Glass B | `rbxassetid://477873990` | 1 |
| Glass C | `rbxassetid://19886465` | 1 |
| Glass D | `rbxassetid://336784813` | 1 |
| Glass E | `rbxassetid://51334801` | 1 |
| Glass F | `rbxassetid://3257121187` | 1 |
| Glass G | `rbxassetid://7217669931` | 1 |
| Glass H | `rbxassetid://6612446236` | 1 |
| Glass I | `rbxassetid://7480438284` | 1 |
| Glass J | `rbxassetid://4576475446` | 1 |
| Glass K | `rbxassetid://24334001` | 1 |
| Glass L | `rbxassetid://520946063` | 1 |

### Nommées — pierre, bois, métal, neige, sable

| Nom | ColorMap | Carreau |
| --- | --- | --- |
| BlueFloor | `rbxassetid://4621421263` | 1 |
| BrownMud | `rbxassetid://4621374467` | 1 |
| BrownMud2 | `rbxassetid://4621416751` | 1 |
| CobbleStone | `rbxassetid://4621367944` | 1 |
| Concrete | `rbxassetid://2054347968` | 10 |
| ForestGround | `rbxassetid://4621408203` | 1 |
| GreenMetal | `rbxassetid://4621474020` | 1 |
| MetalPlate | `rbxassetid://4621477365` | 1 |
| PS1/PS2 | `rbxassetid://7141934705` | 1 |
| RustyMetal | `rbxassetid://4621480916` | 1 |
| Sand | `rbxassetid://4621444383` | 1 |
| ShellFloor | `rbxassetid://4621424604` | 1 |
| Snow | `rbxassetid://4621414283` | 1 |
| Snow2 | `rbxassetid://4621460944` | 1 |
| TerrainRed | `rbxassetid://4621451505` | 1 |
| brick_floor | `rbxassetid://4621497703` | 1 |
| brown_planks | `rbxassetid://4621512699` | 1 |
| cobblestone2 | `rbxassetid://4621394396` | 1 |
| cobblestone_floor | `rbxassetid://4621501940` | 1 |
| large_floor_tiles | `rbxassetid://4621495999` | 1 |
| large_square_pattern | `rbxassetid://4621488899` | 1 |
| marble | `rbxassetid://4621489901` | 1 |
| metal | `rbxassetid://4549727994` | 1 |
| moss_wood | `rbxassetid://4621514910` | 1 |
| planks_brown | `rbxassetid://4621506509` | 1 |
| plaster_grey | `rbxassetid://4621519312` | 1 |
| white_plaster_rough | `rbxassetid://4621516946` | 1 |

### Matières PBR — MeshPart uniquement

| Nom | ColorMap |
| --- | --- |
| FakePaint | `rbxassetid://8565017965` |
| MeshPart | `rbxassetid://8440504192` |
| MudColored | `rbxassetid://7823940036` |
| OldGold | `rbxassetid://8564992852` |
| Pedra | `rbxassetid://8090159314` |
| RawBronze | `rbxassetid://8565040234` |
| RawGold | `rbxassetid://8565017965` |
| Rust | `rbxassetid://8565194019` |
| agua1 | `rbxassetid://8090165970` |
| damascus | `rbxassetid://8565087369` |

### Low poly

| Nom | ColorMap |
| --- | --- |
| LowPoly | `rbxassetid://6794063173` |
| LowPoly2 | `rbxassetid://6904986063` |

---

## Les textures dans l'interface

Le thème pose une de ces textures en trame sur les panneaux de menus, à 8 %
d'opacité : elle donne du grain à la surface sans jamais gêner la lecture. C'est une
ligne dans `src/Shared/Config/Themes/Default.luau` :

```lua
textures = {
	panelPattern = "rbxassetid://4621488899", -- large_square_pattern
},
```

Mets `nil` et les panneaux redeviennent lisses. Les autres candidats propres pour cet
usage : `marble`, `white_plaster_rough`, `plaster_grey`, `large_floor_tiles`.

Une trame de menu doit être **seamless et peu contrastée**. Une texture de brique ou
de bois marche mal ici : le motif se voit, et le texte passe dessus.
