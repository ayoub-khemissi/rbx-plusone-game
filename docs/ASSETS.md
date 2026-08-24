# Assets visuels à produire

Liste exhaustive de ce qu'il faut créer pour que le jeu cesse d'être un prototype en
blocs colorés. Chaque entrée indique **où son identifiant se colle** dans le code.

---

## Avant de commencer : ce que le code attend aujourd'hui

Deux choses sont à savoir, parce qu'elles conditionnent le format de ce que tu vas
produire.

**Les icônes sont des emoji.** Dans `Config/`, chaque amélioration, pass et produit
porte un champ `icon = "💨"`. Remplacer un emoji par une image demande une petite
modification de code (passer d'un `TextLabel` à un `ImageLabel`) que je ferai quand tes
premiers fichiers seront prêts. Prévois donc les icônes en **image**, pas en police.

**Le monde est fait de `Part` colorées.** Aucun `MeshPart`, aucune texture. Le
générateur (`Server/World/SkyBuilder.luau`) pose des blocs et des anneaux composés de
segments. Chaque asset ci-dessous remplace un bloc précis, et je te dirai lesquels
deviennent des `MeshPart` et lesquels gardent leur forme mais reçoivent une texture.

**Rien n'est bloquant.** Le jeu tourne sans aucun de ces assets. On peut les intégrer
un par un, dans l'ordre que tu veux.

---

## 1. Le dragon du joueur

C'est l'asset le plus important : il est à l'écran en permanence.

| Asset | Format | Détail |
| --- | --- | --- |
| **Corps du dragon** | `.fbx` rigué | Le personnage que pilote le joueur. Vue de dos la plupart du temps : la silhouette et la queue comptent plus que le visage |
| **Animation de vol** | Animation Roblox | Battements d'ailes en boucle |
| **Animation de piqué** | Animation Roblox | Ailes repliées, corps allongé |
| **Animation d'attente** | Animation Roblox | Posé au Nest, ailes repliées |
| **Écailles — 6 variantes de couleur** | Texture ou `Color3` | Une par palier de **Molt** : le joueur change de couleur à chaque mue, et c'est visible par les autres |

Deux approches possibles, à toi de choisir :

- **Personnage complet** — un modèle R15 custom. Plus beau, plus de travail, et il faut
  gérer les accessoires Roblox du joueur (qui n'auront plus de sens).
- **Accessoires sur l'avatar** — ailes + queue + casque en `Accessory`. Le joueur garde
  son avatar, ce qui est un argument commercial fort sur Roblox, et le travail est
  bien plus léger. **C'est ce que je recommande pour la v1.**

Budget géométrie conseillé : sous 5 000 triangles pour un accessoire, sous 10 000 pour
un personnage complet. Vérifie les limites Roblox du moment avant de finaliser.

---

## 2. Les dix espèces de dragons

Ce sont les dragons de **collection** : ils ne se pilotent pas, ils s'exposent au Nest
et suivent le joueur. Ils apparaissent aussi en vignette dans le livre de collection.

| # | `id` (code) | Nom affiché | Rareté | Piste visuelle |
| --- | --- | --- | --- | --- |
| 1 | `emberling` | Emberling | commune | Braise, petit, rond |
| 2 | `mossback` | Mossback | commune | Mousse, dos végétal |
| 3 | `pebblewing` | Pebblewing | commune | Pierre, petites ailes |
| 4 | `sunspeck` | Sunspeck | commune | Doré pâle, lumineux |
| 5 | `stormtail` | Stormtail | rare | Nuage d'orage, queue longue |
| 6 | `glasswing` | Glasswing | rare | Ailes translucides |
| 7 | `cinderfang` | Cinderfang | rare | Cendre, crocs marqués |
| 8 | `aurorent` | Aurorent | épique | Aurore boréale, iridescent |
| 9 | `mistcaller` | Mistcaller | épique | Brume, contours flous |
| 10 | `crownwyrm` | Crownwyrm | légendaire | Or, couronne, imposant |

**Pour chacun** :

- un **modèle** `.fbx` (budget ~2 000 triangles, ils sont vus de loin) ;
- une **vignette carrée 256×256** pour le livre de collection.

→ Les identifiants se colleront dans `src/Shared/Config/Dragons.luau`, sur chaque
espèce, dans deux champs que j'ajouterai : `model` et `image`.

---

## 3. Icônes d'interface

Format commun : **PNG carré, 256×256**, fond transparent, lisible à 48 px puisque
c'est la taille réelle d'affichage.

### Améliorations — `Config/Upgrades.luau`

| `id` | Nom affiché | Sujet |
| --- | --- | --- |
| `speedGain` | Wingbeat | Aile en mouvement |
| `goldGain` | Hoard Sense | Pièce, museau qui flaire |
| `agility` | Tailfin | Queue, virage |
| `magnet` | Ring Pull | Aimant et anneau |
| `hatchSpeed` | Warm Scales | Œuf et chaleur |

### Gamepasses — `Config/Passes.luau`

| `id` | Nom affiché | Sujet |
| --- | --- | --- |
| `doubleGold` | x2 Gold | Deux pièces, « x2 » |
| `doubleEggs` | x2 Eggs | Deux œufs, « x2 » |
| `swiftWing` | Swift Wing | Aile stylisée, traînée |
| `phoenixFeather` | Phoenix Feather | Plume enflammée |
| `ringMagnet` | Ring Magnet | Aimant attirant des anneaux |
| `nestKeeper` | Nest Keeper | Nid avec emplacements |

### Produits — `Config/Products.luau`

| `id` | Nom affiché | Sujet |
| --- | --- | --- |
| `goldSmall` | Pouch of Gold | Petite bourse |
| `goldMedium` | Chest of Gold | Coffre |
| `goldLarge` | Hoard of Gold | Tas d'or |
| `goldHuge` | Dragon's Hoard | Montagne d'or, dragon dessus |
| `swiftRush` | Swift Rush | Éclair |
| `goldFever` | Gold Fever | Flamme dorée |
| `skyFestival` | Sky Festival | Feu d'artifice |
| `instantHatch` | Instant Hatch | Œuf qui éclot |
| `flightInsurance` | Flight Insurance | Bouclier |
| `instantMolt` | Instant Molt | Dragon en mue |
| `starterPack` | Hatchling Pack | Paquet cadeau |

### Menu latéral — 5 icônes, 96×96

`shop` (or) · `nest` (nid) · `molt` (dragon) · `gifts` (cadeau) · `store` (gemme Robux)

### Ressources et statuts — 128×128

`speed` (éclair) · `gold` (pièce) · `pouch` (bourse en jeu) · `molt` (mue) ·
`feather` (plume) · `insurance` (bouclier) · `tier` (barrière de vent)

### Œufs — 4 icônes 256×256

Un par rareté : `common`, `rare`, `epic`, `legendary`. Ce sont les mêmes qui servent
au couvoir et au stock. La couleur doit suivre la palette de rareté ci-dessous.

### Boosts actifs — 4 icônes 96×96

`swiftRush` · `goldFever` · `skyFestival` · `dailyGift`

### Cadres de rareté — 4 fichiers 256×256

Un contour décoratif par rareté, appliqué aux vignettes de dragons et d'œufs. C'est
ce qui rend une collection lisible d'un coup d'œil.

---

## 4. Le monde

### Le Nest

| Élément | Ce qu'il remplace | Format |
| --- | --- | --- |
| **Plateforme** | `Part` « Floor » | Texture de pierre/bois, 1024×1024, répétable |
| **Garde-corps** | `Part` « Rail » | `MeshPart` sculpté, ou texture |
| **Launch Pad** | `Part` orange | `MeshPart` + texture lumineuse |
| **Perch** | `Part` bleue | `MeshPart` de perchoir |
| **Couvoir** | *n'existe pas encore* | Un nid avec 3 emplacements visibles — je l'ajouterai au générateur |

### Les couloirs de vol

| Élément | Ce qu'il remplace | Détail |
| --- | --- | --- |
| **Ring** | 12 segments + capteur | Un `MeshPart` de tore remplacerait avantageusement les 12 blocs, et diviserait le nombre de parts par 12 |
| **Altar** | Anneau doré + colonne | Version plus riche du Ring : socle, gravures, lumière |
| **Gate** (barrière de vent) | Grand anneau | Doit exister en **deux états** : verrouillé (rouge) et franchissable (vert) |
| **Wall statique** | Dalle rouge | Texture de pierre/cristal selon le Tier |
| **Wall dérivant** | Idem | Même modèle, animé par le serveur |
| **Barre rotative** | Barre néon | `MeshPart` allongé, motif de vent |

### Les dix Tiers

Chaque Tier a besoin d'une **ambiance visuelle distincte**. C'est ce qui donne le
sentiment de progresser.

| # | Tier | Îles flottantes | Ciel |
| --- | --- | --- | --- |
| 1 | Hanging Meadows | Prairie, fleurs | Brume basse, matin |
| 2 | Gilded Ruins | Ruines dorées, colonnes | Soleil bas |
| 3 | Upturned Falls | Roche humide, cascades inversées | Arcs-en-ciel |
| 4 | Cloud Grove | Arbres dans les nuages | Blanc laiteux |
| 5 | Amber Arches | Ambre, arches translucides | Lumière chaude |
| 6 | Wind Sanctuary | Temples ouverts | Vent visible |
| 7 | Sea of Mist | Silhouettes dans la brume | Visibilité réduite |
| 8 | Crystal Spires | Pics de cristal | Réfractions |
| 9 | The Aurora | Roche polaire | Aurores boréales |
| 10 | The Crown | Éclats d'or dans le vide | Étoiles |

**Pour chaque Tier** : 2 à 3 variantes d'île (`MeshPart`, ~1 500 triangles), une texture
de sol 1024×1024, et un réglage de `Sky` / `Atmosphere` Roblox. Les couleurs actuelles
sont déjà dans `Config/Tiers.luau`, champ `color` — garde-les comme base.

### Skybox

Une skybox par grande ambiance (6 faces, 1024×1024 chacune) : **3 suffisent** pour la
v1 — basse altitude, moyenne, sommet. Le passage de l'une à l'autre se fait au
franchissement d'un Tier.

---

## 5. Effets visuels

| Effet | Déclencheur | Format |
| --- | --- | --- |
| **Traînée de vitesse** | En vol, au-delà d'un seuil | Texture de traînée 256×512, dégradé alpha |
| **Passage d'anneau** | Ring franchi | Onde circulaire, sprite 512×512 |
| **Impact de mur** | Mort | Éclat + poussière, sprite-sheet |
| **Encaissement à l'Altar** | Pouch banked | Gerbe dorée montante |
| **Perte de la Pouch** | Mur sans plume | Pièces qui s'échappent et disparaissent |
| **Plume consommée** | Phoenix Feather | Flamme brève autour du dragon |
| **Éclosion** | Œuf collecté | Coquille qui se brise, lumière selon rareté |
| **Mue** | Molt | Transformation, changement d'écailles |
| **Franchissement de barrière** | Gate passée | Souffle de vent traversé |
| **Sky Festival** | Achat serveur | Feux d'artifice visibles de tous |

Les particules Roblox acceptent des PNG simples : **512×512, fond transparent**, un
sprite par effet suffit dans la plupart des cas.

---

## 6. Assets de la boutique Roblox

Ceux-là ne sont pas dans le jeu : ils décident si quelqu'un clique.

| Asset | Dimensions | Quantité |
| --- | --- | --- |
| **Icône du jeu** | 512×512 | 1 |
| **Vignettes** | 1920×1080 | 3 à 10 — les deux premières font l'essentiel du travail |
| **Icônes de gamepass** | 512×512 | 6 (peuvent reprendre les icônes d'interface, recadrées) |
| **Icônes de produit** | 512×512 | 11 |
| **Badges** | 256×256 | 6 à 10 |

Badges suggérés, alignés sur la progression réelle du jeu : premier vol · premier
encaissement · Tier 5 atteint · Tier 10 atteint · première mue · premier légendaire ·
collection complète.

L'icône du jeu est l'asset au meilleur retour sur temps investi de toute cette liste.
Un dragon de face, très lisible en 128 px, forte saturation.

---

## 7. Charte

### Palette de rareté

Déjà utilisée par le code, dans `Config/Monetization.luau` et `Client/UI/Theme.luau` :

| Rareté | RGB | Usage |
| --- | --- | --- |
| `common` | `176, 186, 178` | Gris-vert |
| `rare` | `96, 172, 232` | Bleu |
| `epic` | `168, 112, 226` | Violet |
| `legendary` | `244, 196, 84` | Or |

### Palette d'interface

| Rôle | RGB |
| --- | --- |
| Fond | `24, 28, 40` |
| Panneau | `36, 42, 60` |
| Accent | `250, 206, 110` |
| Positif | `120, 214, 150` |
| Négatif | `226, 96, 92` |
| **Pouch (l'or en jeu)** | `236, 168, 96` |

Cette dernière couleur mérite attention : c'est celle de la carte « AT RISK ». Elle ne
doit ressembler à aucune autre, parce qu'elle signale ce que le joueur peut perdre.

### Conventions de nommage

```
icon_upgrade_speedGain.png
icon_pass_phoenixFeather.png
icon_product_goldHuge.png
icon_egg_legendary.png
dragon_crownwyrm.fbx
dragon_crownwyrm_thumb.png
world_tier09_island_a.fbx
tex_tier09_ground.png
vfx_ring_pass.png
```

L'`id` du code est repris **tel quel**, à la casse près. C'est ce qui me permettra de
brancher les assets sans t'interroger fichier par fichier.

---

## 8. Récapitulatif

| Catégorie | Quantité |
| --- | --- |
| Modèles 3D | ~45 (1 dragon joueur + 10 espèces + ~30 éléments de monde) |
| Animations | 3 |
| Icônes d'interface | 44 |
| Textures | ~25 |
| Sprites d'effets | 10 |
| Skybox | 3 × 6 faces |
| Assets boutique Roblox | ~28 |

### Par où commencer

**Le strict nécessaire pour que le jeu ait l'air fini** — dans cet ordre :

1. **L'icône du jeu et deux vignettes.** C'est ce qui amène les joueurs. Rien d'autre
   ne sert tant que personne n'entre.
2. **Le dragon du joueur** (version accessoires) et son animation de vol.
3. **Ring, Altar et Gate** en `MeshPart`. Ce sont les trois objets que le joueur
   regarde en permanence, et le Ring divisera par douze le nombre de parts de la carte.
4. **Les 44 icônes d'interface.** Elles transforment l'impression générale d'un coup, et
   c'est le lot le plus mécanique à produire.
5. **Les 10 espèces de dragons.** Le moteur de rétention.
6. Le reste : îles, textures de Tier, skybox, effets.

Les points 1 à 3 suffisent à faire passer le jeu de « prototype » à « jeu qui a l'air
vrai ». Le reste creuse la différence.

---

## Hors périmètre : l'audio

Tu as demandé le visuel, mais la liste serait malhonnête sans le mentionner — sur ce
genre de jeu, le son porte la moitié de la sensation de vitesse.

Le minimum : vent en vol (boucle), passage d'anneau, impact de mur, encaissement,
éclosion, achat, et une musique d'ambiance par grande altitude. Sept fichiers.

---

*Quand tes premiers fichiers sont prêts, dis-le-moi : j'ajoute les champs `image` et
`model` dans `Config/`, je remplace les `TextLabel` d'emoji par des `ImageLabel`, et je
bascule le générateur sur les `MeshPart`.*
