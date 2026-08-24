# Business model

Four pillars that feed each other. The principle: **nothing sells while the player
is not playing**, and it is play time that drives both the Roblox ranking and the
occasions to buy.

```
   RETENTION            →  play time  →  Roblox visibility  →  new players
   (daily, chests,                          │
    AFK area, codes)                        ▼
                                     OCCASIONS TO BUY
                                (a Speed gate, a Prestige threshold)
                                            │
                        ┌───────────────────┴───────────────────┐
                        ▼                                       ▼
              PERMANENT (gamepasses)                 REPEATABLE (products)
              one purchase, high perceived value     the main revenue
```

## 1. Retention — free

| Mechanic | Rhythm | Intent |
| --- | --- | --- |
| Daily reward | 1 / day, streak of 7 | Bring them back tomorrow |
| Session chest | every 5 min | Keep them here now |
| AFK area | during the session | Keep servers populated |
| Promo codes | occasional | Acquisition through social media |
| Checkpoints | continuous | Make failure cheap |

**On the AFK area.** It is the waiting system of the game, and it is deliberately
mediocre: the income is slow and **capped per session**. Its job is to keep servers
populated — which matters for Roblox recommendations — without ever becoming a better
strategy than playing. The day standing still pays more than running, the game is
dead.

**On checkpoints.** A fall costs neither Speed nor Coins, only time. That is an
economic choice as much as a design one: a player who loses their progress closes the
game, a player who loses thirty seconds starts again.

## 2. Permanent — gamepasses

One purchase, high perceived value, no content locked behind any of them.

| Gamepass | Effect |
| --- | --- |
| x2 Coins | Doubles every Coin earned |
| x2 Speed | Doubles the Speed gained on every stretch |
| Swift Boots | ×1.5 Speed and a permanently higher jump |
| Extra Jump | One more air jump than the upgrades allow |
| Coin Magnet | Collects Coins from much further away |
| Auto Run | The character keeps running on its own |

None of them unlocks content. **Extra Jump** is the best seller of the six, because it
is bought right after missing the same jump three times — the player knows exactly
what they are buying and why.

## 3. Repeatable — developer products

The main revenue: the player comes back to buy at every hard step.

| Product | Indicative price | Contents |
| --- | --- | --- |
| Handful / Bag / Chest / Vault of Coins | 99 / 199 / 499 / 999 R$ | 2 500 → 100 000 Coins |
| Speed Rush | 149 R$ | ×2 Speed, 20 min |
| Coin Rush | 149 R$ | ×3 Coins, 20 min |
| Party Time | 299 R$ | A bonus for **every** player on the server, 10 min |
| Instant Chest | 149 R$ | Opens the session chest right now |
| Instant Prestige | 399 R$ | Prestige immediately, **keeping the upgrades** |
| Starter Pack | 199 R$ | Welcome offer: Coins plus a boost |

The 99 / 199 / 499 / 999 ladder is the one Roblox players are used to, with a *best
value* tier highlighted to lift the average basket.

**Instant Prestige keeps the upgrades**, unlike the free Prestige which resets them.
That is precisely what is being sold: not the multiplier, which stays reachable by
playing, but not having to buy the whole tree again.

## 4. Social and acquisition

- **Party Time**: the buyer is named in a notification everyone sees. The purchase
  becomes a social gesture, highly visible, often imitated.
- **Limited-time offers**: one at a time, never blocking. The Starter Pack appears
  after a few minutes of play; a Coin offer is proposed at the precise moment the
  player has just been turned away by a Speed gate.
- **Promo codes**: shareable on TikTok, YouTube or Discord, they bring players in
  with no advertising budget.

The gate-triggered offer is the more profitable of the two, and that follows: it
arrives at the only moment when the player has a precise, named problem and a priced
solution in front of them.

## Purchase reliability

A lost purchase is a lost player. Receipt handling applies three rules:

1. **Profile not loaded → do not confirm.** Roblox will replay the receipt, including
   at the player's next session.
2. **Receipt already handled → do not credit twice.** A purchase ledger kept in the
   save guarantees idempotence, even across a server restart.
3. **Save failed → do not confirm.** A replay is better than a purchase credited in
   memory and then lost.

All three cases are covered by automated tests.

## Going live

1. Create the gamepasses and products on the Roblox site.
2. Paste the identifiers into `src/Shared/Config/Passes.luau` and
   `src/Shared/Config/Products.luau`.
3. An identifier left at `0` hides the item everywhere — the game stays playable and
   the store stays clean until anything exists.

No line of code has to change to switch the monetization on.

## Tuning

Everything lives in `src/Shared/Config/Monetization.luau`: boost durations and
stacking, the daily reward table, the session chest interval, promo codes and offers.
Upgrade prices in Coins are in `Upgrades.luau`, and the AFK rate in `Balance.luau`.
