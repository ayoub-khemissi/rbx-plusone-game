# Contrat de map

Tu construis les maps dans Studio, le serveur les lit. Ce document est le contrat entre
les deux : **il n'y a rien d'autre à respecter que ce qui est écrit ici.**

Tout passe par des **tags** (CollectionService) et des **attributs**. Aucune convention
de nom, aucune hiérarchie imposée : tu ranges tes parts comme tu veux, seuls les tags
comptent.

> Dans Studio, les tags s'ajoutent avec le panneau **View → Tag Editor**, et les
> attributs dans le panneau **Properties**, section *Attributes*, en bas.

---

## Les sept tags

| Tag | À poser sur | Ce que le serveur en fait |
| --- | --- | --- |
| `Checkpoint` | Une part traversable | Enregistre le point de réapparition du joueur |
| `Killzone` | Une part traversable | Renvoie le joueur à son dernier checkpoint |
| `Coin` | Une part traversable | Donne des Coins, disparaît, réapparaît |
| `SpeedGate` | Une part solide | Bloque tant que la Speed du joueur est trop basse |
| `ShopPad` | Une part traversable | Ouvre la boutique |
| `PrestigePad` | Une part traversable | Déclenche le Prestige |
| `AfkPad` | Une part traversable | Zone de revenu passif |

C'est tout. Sept tags pour une map complète.

---

## Détail de chaque tag

### `Checkpoint`

La colonne vertébrale du parcours : c'est ce qui découpe la map en **Stages** et ce qui
définit où le joueur réapparaît.

| Attribut | Type | Obligatoire | Rôle |
| --- | --- | --- | --- |
| `StageId` | number | **oui** | Le Stage auquel ce checkpoint appartient (1, 2, 3…) |
| `Order` | number | non | Ordre dans le Stage, pour l'affichage « 3 / 8 » |

**Conseils de pose.** Fais-en une part large et fine posée en travers du parcours, en
`CanCollide = false`, `Transparency = 1` si tu ne veux pas la voir — mets un décor
visible à côté. Le joueur réapparaît **au-dessus du centre de la part**, alors place-la
sur du sol plat.

Le premier checkpoint d'un Stage sert aussi de point d'entrée du Stage.

### `Killzone`

Tout ce qui tue : le vide sous le parcours, la lave, les piques, un obstacle mortel.

Aucun attribut. Le joueur revient à son dernier `Checkpoint`, **garde sa Speed et ses
Coins**, et perd seulement du temps.

**Le vide.** Ne compte pas sur la chute libre : pose une **grande dalle invisible**
(`Transparency = 1`, `CanCollide = false`) taguée `Killzone` sous tout le parcours. Elle
attrape toutes les chutes, quelle que soit la hauteur.

### `Coin`

| Attribut | Type | Obligatoire | Rôle |
| --- | --- | --- | --- |
| `Value` | number | non | Valeur brute. Sans attribut, la valeur par défaut de la config s'applique |

Le Coin disparaît au ramassage et réapparaît après un délai réglé dans la config. Pose
un modèle visuel si tu veux : tague **la part de détection**, pas le décor.

### `SpeedGate`

La barrière qui garde l'entrée d'un Stage. Le joueur ne passe que s'il est assez rapide.

| Attribut | Type | Obligatoire | Rôle |
| --- | --- | --- | --- |
| `RequiredSpeed` | number | **oui** | Speed minimale pour traverser |
| `StageId` | number | non | Sert à l'affichage du nom du Stage dans le message |

Laisse-la en `CanCollide = true`. Le client la rend **traversable localement** dès que
le joueur a la vitesse requise, et le serveur revérifie de son côté : impossible de
passer en trichant.

### `ShopPad`, `PrestigePad`, `AfkPad`

Trois pads de la zone de départ. Aucun attribut.

- **`ShopPad`** — ouvre la boutique d'améliorations à l'entrée sur le pad.
- **`PrestigePad`** — déclenche le Prestige. Le serveur refuse poliment si le seuil
  n'est pas atteint, tu n'as rien à gérer.
- **`AfkPad`** — tant que le joueur est dessus, il gagne des Coins à un rythme lent et
  plafonné. Fais-en une zone confortable, avec des sièges si tu veux.

---

## Ce que la config décide, ce que la map décide

C'est la séparation qui te laisse les mains libres :

| La **map** décide | La **config** décide |
| --- | --- |
| Où sont les checkpoints, les trous, les Coins | Combien vaut un Coin, en combien de temps il réapparaît |
| Où sont les barrières, et leur `RequiredSpeed` | Le multiplicateur de Coins de chaque Stage |
| La géométrie, le décor, l'ambiance | La courbe de vitesse, les prix des améliorations |
| Le nombre de Stages | Le seuil de Prestige |

Si tu ajoutes un Stage 6 dans la map, ajoute-lui une ligne dans `Config/Stages.luau` et
il existe. Rien d'autre.

---

## Zone de départ : la liste minimale

Pour que le jeu soit jouable, il faut au minimum :

1. Un **SpawnLocation** Roblox standard (pas de tag, Roblox s'en occupe)
2. Un `ShopPad`
3. Un `PrestigePad`
4. Un `AfkPad`
5. Un premier `Checkpoint` avec `StageId = 1`, à l'entrée du parcours
6. Une dalle `Killzone` sous tout le niveau

Les points 5 et 6 sont les seuls vraiment indispensables : sans checkpoint le joueur
réapparaît au spawn, sans killzone il tombe indéfiniment.

---

## Ce que le serveur ne fera jamais

Pour que tu saches où s'arrête ma responsabilité :

- il ne **déplace** ni ne **crée** aucune part de ta map ;
- il ne dépend d'aucun nom d'objet ni d'aucune hiérarchie ;
- il ignore poliment toute part taguée mais mal configurée, en écrivant un
  avertissement dans la console plutôt qu'en plantant.

Si un `Checkpoint` n'a pas de `StageId`, il est ignoré et la console te le dit. Tu ne
peux pas casser le serveur avec une map, seulement obtenir un comportement partiel.

---

## Vérifier ta map

Une commande listera ce que le serveur a trouvé au démarrage :

```
[Game] Map loaded: 4 stages, 27 checkpoints, 180 coins, 3 speed gates
[Game] Warning: a Checkpoint has no StageId, ignored
```

Si le compte ne correspond pas à ce que tu as posé, c'est un tag oublié.
