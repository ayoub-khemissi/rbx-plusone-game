# Balance — the shape of the economy

Every number lives in `src/Shared/Config/`. This is what they mean together, and what
breaks when one of them moves.

Read this before touching `Balance.luau`, `Stages.luau`, `Worlds.luau` or
`Upgrades.luau`. The numbers are not independent: four of them are pinned to each
other, and changing one alone silently breaks a promise the game makes to the player.

---

## The four quantities

| | What it is | Where it lives |
| --- | --- | --- |
| **Speed** | Experience. Every metre run adds to it, permanently. Never spent. | `profile.speed` |
| **Level** | Speed read as a rank. A readout, nothing more — it grants nothing. | derived |
| **Coins** | Currency. Earned by running, spent in the shop, reset by a rebirth. | `profile.coins` |
| **Rebirths** | How many times the player has reset. Never resets. | `profile.prestiges` |

Speed and Coins are earned by the same act at a fixed ratio: one Speed and 0.4 Coins
per step, before multipliers (`progression`). A step is 4 studs (`movement`).

The word for a rebirth in code is *prestige*; the player reads *Rebirth*. The theme
owns the word, the code owns the mechanic.

---

## The shape of a world

A world is **200 levels, 10 stages, 7 rebirths, four and a half hours**.

```
level      1 ──────────────────────────────────────────────── 200
stage      1    2    3    4    5    6    7    8    9    10
           every 20 levels; stage 10 opens at level 180

rebirth    1 ──────────── 2 ─── 3 ── 4 ─ 5 ─ 6 ─ 7
           109 min        40    33   28  23  19  15     = 4 h 30

walk       16 ─────────────────────────────────────────── 119 studs/s
speed      22 at 8 min · 41 at 1 h · 53 at the first rebirth · 76 at level 100
```

Four hours and a half is the **floor for a free player farming without pause**, and
it is what the treadmills are sold against. A floor that can be walked around is not
worth measuring.

The seventh rebirth lands exactly on level 200, which is exactly where the walk speed
clamps. Those three numbers — the top of the ladder, the top of the level curve, the
top of the speed curve — are the same moment on purpose. If they drift apart, either
the last courses belong to nobody or the character stops getting faster before the
world is over.

---

## The one rule everything else follows

**Every quantity in the game is multiplied by the same number: `1.6` per rebirth.**

```
income          × 1.6 per rebirth     prestige.multiplierGrowth
rebirth cost    × 1.6 per rebirth     prestige.requirementGrowth
shop prices     × 1.6 per rebirth     UpgradeCatalog priceGrowthPerPrestige
Robux grants    × 1.6 per rebirth     Grants
world scale     × 1.6^7 per world     Worlds.scale = 26.84
```

That is what makes the game **self-similar**: the fiftieth rebirth is the same
experience as the first, in bigger numbers, and the fifth world costs the same four
and a half hours as the first. Each of those lines was, at some point, the one that
was not scaled, and each time the result was the same kind of collapse:

- prices left unscaled → the shop is free by the third world, and a world melts from
  4 h 30 to 14 minutes;
- Robux coin grants left unscaled → a 100 000 Coin pack buys a shop row on the first
  evening and a rounding error two worlds later;
- the rebirth cost growing faster than the multiplier → every world takes longer than
  the last, by the same factor, forever.

`requirementGrowth` and `multiplierGrowth` must stay **equal**. A spec enforces it.

---

## The level curve

```lua
requirement(level) = base * level ^ exponent      -- base 17.6, exponent 2.3
```

**The exponent decides the shape, the base decides the length.** They are set
together and only together:

- `exponent` 2.3 puts the first level twenty seconds away and the two-hundredth at a
  third of the world. It was 1.9 and the first level took **two minutes** to arrive —
  which is the wrong first impression for a game whose promise is that running pays.
- `base` 17.6 puts level 200 on exactly the experience seven rebirths add up to.

If you change the exponent, recompute the base so `requirement(200)` stays equal to
`prestige.baseRequirement * 1.6^6`, then recompute every `requiredSpeed` in
`Stages.luau` as `requirement(requiredLevel)`. Three specs check the three halves of
that; none of them can tell you a curve is *pleasant*, only that it is consistent.

A world scales this curve and the stage ladder **by the same factor**, which is why a
level reads the same in every world. Only the raw number grows.

---

## Catching up after a rebirth

A rebirth takes the Speed and leaves the multiplier. With an exponent above two, nine
tenths of a world sits in its last tenth of levels — so without help, most of every
cycle is spent re-walking ground the player already walked, at a pace they had
already outgrown.

**The catch-up is paid on the GAIN, never on the price of a level.**
`progression.catchUp = 12`: below your best level ever, you climb twelve times
faster; above it, nothing.

That distinction is the whole reason it exists, and it is worth stating plainly
because the obvious implementation is the wrong one. Discounting the *price* of known
levels does the same job for the player — and raises the level a given Speed reads
as, every rebirth, compounding. Measured: **level 723 at the end of a world built for
200**, with the character pinned at maximum walk speed from the second cycle on. The
gain-side version leaves the ladder exactly where it was.

`profile.bestLevel` is the high-water mark. It survives a rebirth and is cleared when
a world is (`PrestigePolicy.apply`).

---

## The shop

Prices are `baseCost * costGrowth ^ level`, **quoted at the first rebirth** and
multiplied by `1.6` for every rebirth taken. The player never sees a price list
change shape; it changes size, at exactly the rate their income does.

What one cycle buys, in every world:

| Row | Bought per cycle | Why it is priced that way |
| --- | --- | --- |
| **Stride** `speedGain` | ~20 levels | The main dial. +15% each, and the single biggest accelerator in the game |
| **Fortune** `coinGain` | ~20 levels | Feeds Stride. Kept slightly steeper so it never outruns it |
| **Spring** `jumpPower` | ~12 levels | Height, capped at 30 |
| **Magnet** | ~8 levels | Comfort, capped at 12 |
| **Dash** | once, ~33 min in | A milestone, not a stat: unlock only |
| **Dash Power** | 2 of 5 | Gated behind Dash. ×2 to ×6 |
| **Air Jump** | 1 of 2, ~53 min in | Steep on purpose: it changes which maps are crossable |

Upgrades are lost to a rebirth (`prestige.resetsUpgrades`), so the shop is a live
loop in every cycle rather than a tree you finish once. That is only true because
prices scale — with a fixed price list the whole shop is bought in the first minutes
of a late cycle and there is nothing left to decide.

---

## Retuning: the procedure

**The pacing cannot be reasoned about, only simulated.** The gain rate feeds back into
itself — running faster earns more, which buys more, which runs faster — and the shop
is part of that loop, not an aside. This was measured the wrong way once: the guard
rail simulated a player who never bought anything, asserted "over four hours", and
the real game took **fifty-five minutes**.

The simulation lives in `tests/specs/config.spec.luau` (`simulateWorld`). It buys the
way a player buys: whatever is affordable, cheapest first, every tick. To retune:

1. change the number;
2. run `./scripts/check.ps1`;
3. read what the pacing specs say.

Three of them encode the intent rather than the arithmetic:

| Spec | What it protects |
| --- | --- |
| *keeps a world out of reach for at least four hours* | The floor, shop included |
| *costs the same in every world* | Self-similarity, within 5% |
| *ends a world on level 200* | The ladder, the level curve and the stage list agreeing |
| *reaches the top speed exactly at the top of the world* | The speed curve agreeing with all three |

A change that moves one of these is not necessarily wrong. It is necessarily
**deliberate** — that is what the specs are for.

---

## The knobs, and what each one moves

| Knob | Moves | Watch out |
| --- | --- | --- |
| `level.exponent` | The shape: early levels vs late ones | Recompute `level.base` and every `Stages.requiredSpeed` |
| `level.base` | The length of a world | Must keep `requirement(200) = baseRequirement * 1.6^6` |
| `prestige.baseRequirement` | Where the first rebirth sits, and the whole ladder with it | Pinned to `level.base` |
| `prestige.requirementGrowth` | Nothing on its own | Must equal `multiplierGrowth` |
| `prestige.multiplierGrowth` | The rate the entire economy scales at | Prices and grants follow it automatically |
| `prestige.rebirthsPerWorld` | How many cycles a world is | Changes `Worlds.scale`, which is `growth ^ this` |
| `progression.catchUp` | How fast the climb back is | Not the level readout — see above |
| `speedCurve.softness` | How fast the game gets fast | Aimed at `maxWalkSpeed` by level 200 |
| `speedCurve.maxWalkSpeed` | The ceiling | Play-tested at 119: two studs between frames, so a 4-stud gap is never skipped |
| `Upgrades.baseCost` / `costGrowth` | How much of a cycle each row eats | Quoted at rebirth 0 |
| `Stages.coinMultiplier` | How much richer the late course is | Compounds with everything |

---

## What a fall costs, and what it does not

A fall costs **time**: the character dies and comes back after
`run.respawnDelay` (2 s) on the last checkpoint. It costs no Speed, no Coins and no
Stage. The Coins on the course come back with the player, per player — see
`docs/MAP.md`.

That is the promise the whole design rests on: **you always end a run faster than you
started it**. Nothing in this document may be tuned in a way that takes progress back.
