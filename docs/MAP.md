# Contrat de map

Tu construis les maps dans Studio, le serveur les lit. Ce document est le contrat entre
les deux : **il n'y a rien d'autre à respecter que ce qui est écrit ici.**

Tout passe par des **tags** (CollectionService) et des **attributs**. Aucune convention
de nom, aucune hiérarchie imposée : tu ranges tes parts comme tu veux, seuls les tags
comptent.

> Dans Studio, les tags s'ajoutent avec le panneau **View → Tag Editor**, et les
> attributs dans le panneau **Properties**, section *Attributes*, en bas.

---

## Les tags

| Tag | À poser sur | Ce que le serveur en fait |
| --- | --- | --- |
| `Checkpoint` | Part **ou Model** | Enregistre le point de réapparition du joueur |
| `TrapPart` *(ou `Killzone`)* | Part ou Model | Renvoie le joueur à son dernier checkpoint |
| `Conveyor` | Part | Tapis roulant : pousse dans le sens de la face avant |
| `BouncePad` | Part | Trampoline : propulse le joueur vers le haut |
| `Coin` | Part | Donne des Coins, disparaît, réapparaît |
| `SpeedGate` | Part solide | Bloque tant que la Speed du joueur est trop basse |
| `ShopPad` | Part | Ouvre la boutique |
| `PrestigePad` | Part | Déclenche le Prestige |
| `AfkPad` | Part | Zone de revenu passif |

**Un tag peut être posé sur un Model** : toutes ses parts sont alors câblées. C'est ce
qui permet de taguer un checkpoint décoré une seule fois.

Seuls `Checkpoint` et un moyen de mourir sont vraiment nécessaires. Le reste s'ajoute
quand tu en as besoin.

---

## Détail de chaque tag

### `Checkpoint`

La colonne vertébrale du parcours : c'est ce qui découpe la map en **Stages** et ce qui
définit où le joueur réapparaît.

| Attribut | Type | Obligatoire | Rôle |
| --- | --- | --- | --- |
| `StageId` | number | non | Le Stage auquel ce checkpoint appartient. **Sans lui, Stage 1** |

Une map d'un seul Stage n'a donc rien à déclarer. Le `StageId` ne devient utile que le
jour où tu veux une barrière de vitesse entre deux portions.

**Conseils de pose.** Fais-en une part large et fine posée en travers du parcours, en
`CanCollide = false`, `Transparency = 1` si tu ne veux pas la voir — mets un décor
visible à côté. Le joueur réapparaît **au-dessus du centre de la part**, alors place-la
sur du sol plat.

Le premier checkpoint d'un Stage sert aussi de point d'entrée du Stage.

### `TrapPart` *(ou `Killzone`)*

Tout ce qui tue : la lave, les piques, un obstacle mortel. Les deux noms sont acceptés.

Aucun attribut. Le joueur revient à son dernier `Checkpoint`, **garde sa Speed et ses
Coins**, et perd seulement du temps.

**Le vide n'a rien à taguer.** Le serveur cherche la part la plus basse de la map au
démarrage et considère toute chute sous ce niveau comme mortelle. Pas de dalle
invisible à poser, et rien à oublier.

### `Conveyor`

| Attribut | Type | Obligatoire | Rôle |
| --- | --- | --- | --- |
| `Speed` | number | non | Vitesse du tapis. Défaut : 10 |

Le tapis pousse dans le sens de sa **face avant** : tourne la part dans Studio pour
changer la direction. Aucune logique par joueur, c'est la physique Roblox qui travaille.

### `BouncePad`

| Attribut | Type | Obligatoire | Rôle |
| --- | --- | --- | --- |
| `BounceImpulse` | number | non | Vitesse verticale donnée. Défaut : 200 |

La vitesse verticale est **remplacée**, pas ajoutée : un pad propulse pareil qu'on
arrive en tombant ou en montant.

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
2. Un premier `Checkpoint` à l'entrée du parcours

C'est tout. Sans checkpoint, le joueur réapparaît simplement au spawn ; le vide est
géré tout seul.

Quand tu voudras la boucle économique complète, ajoute un `ShopPad`, un `PrestigePad`
et un `AfkPad` dans la zone de départ.

---

## Ce que le serveur ne fera jamais

Pour que tu saches où s'arrête ma responsabilité :

- il ne **déplace** ni ne **crée** aucune part de ta map ;
- il ne dépend d'aucun nom d'objet ni d'aucune hiérarchie ;
- il ignore poliment toute part taguée mais mal configurée, en écrivant un
  avertissement dans la console plutôt qu'en plantant.

Un attribut manquant prend une valeur par défaut et la console te le dit. Tu ne peux
pas casser le serveur avec une map, seulement obtenir un comportement partiel.

---

## Vérifier ta map

Une commande listera ce que le serveur a trouvé au démarrage :

```
[Runner] Map loaded: 6 checkpoints, 11 hazards, 0 coins, 4 conveyors, 1 bounce pads, 0 idle pads
[Runner] 6 checkpoints without a StageId, assigned to Stage 1
[Runner] Void level set to -184 studs
```

Si le compte ne correspond pas à ce que tu as posé, c'est un tag oublié.
