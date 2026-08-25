# Runner — every step makes you faster

A Roblox parkour game where **running is the only progression**. The character
speeds up with every metre covered, unlocks a double then a triple jump, and a dash
that grows in power — until it clears courses it was physically unable to cross an
hour earlier.

> ⚡ Every metre run raises your **Speed**, permanently
> 🪙 Collect **Coins** and buy whatever takes you further
> 🪽 Double jump, triple jump, dash level 1 to 3
> 🚩 Break through the speed gates gating each Stage
> 🔁 Start over with a **Prestige**, and go much faster

---

## The loop

**Running pays.** Every metre covered raises Speed — permanently — and pays Coins.
None of it is lost by falling: a fall costs time, never progress.

**Coins buy the ability to go further.** Jump higher, jump twice then three times,
dash harder, collect from further away, gain faster. Those purchases are what open
the shortcuts and the routes that were out of reach.

**Gates cut the course into pieces.** The entrance to each Stage is guarded by a
barrier that only opens above a certain Speed. It cannot be walked around: it is
earned by running, or bought in advance by upgrading Stride.

**Prestige resets everything, harder.** Speed, Coins and upgrades all go, in exchange
for a permanent multiplier on every future gain. The second run through a course is a
different experience from the first.

---

## Moving

| Control | Effect |
| --- | --- |
| Directions / joystick | Run |
| Space, or the jump button | Jump — then jump again in mid-air once the double jump is unlocked |
| **Q** or **Left Shift**, or the dedicated button | Dash |

Jump and dash answer **immediately**, without waiting for the server: control must
never depend on latency.

**Speed is its own difficulty.** The faster you go, the less time you have to read a
gap or a trap. The game hardens at exactly your pace, and that is why jump and dash
are bought separately from speed: there is a trade-off, not a slider to push right.

---

## The Stages

The course is cut into five segments, each guarded by a speed gate and more generous
than the last.

| # | Stage | Speed required | Coins |
| --- | --- | --- | --- |
| 1 | Warm-up | — | ×1 |
| 2 | Ramp | 250 | ×1.6 |
| 3 | Climb | 1 000 | ×2.4 |
| 4 | Gauntlet | 4 000 | ×3.5 |
| 5 | Summit | 15 000 | ×5 |

**Checkpoints** are laid along the route. Falling into the void or touching a trap
sends the player back to the last checkpoint reached, **losing nothing**: not Speed,
not Coins, not progress through the Stage.

---

## The upgrades

Bought with Coins, and lost only to a Prestige.

| Upgrade | Effect |
| --- | --- |
| **Stride** | +15% Speed gained on every stretch |
| **Fortune** | +20% Coins on everything |
| **Spring** | Jump higher |
| **Air Jump** | Double jump, then triple jump |
| **Dash** | A burst forward — three levels of power |
| **Magnet** | Collect Coins from further away |

---

## What the player gets for free

- **Daily reward** — a seven-day streak, more generous each day
- **Session chest** — a chest of Coins every five minutes of play
- **AFK area** — slow, capped passive income while standing in it
- **Promo codes** — shared on social media, redeemed in game
- **Limited offers** — never blocking, one at a time

---

## What is offered for sale

Nothing is required: all the content can be finished without spending. Purchases buy
**time** and **comfort**, never access.

**Permanent perks**
x2 Coins · x2 Speed · Swift Boots · Extra Jump · Coin Magnet · Auto Run

**One-off purchases**
Coin packs (four sizes) · Speed Rush (×2 Speed, 20 min) · Coin Rush (×3 Coins,
20 min) · **Party Time** (a bonus given to *every* player on the server) · Instant
chest · Instant prestige · Starter Pack

---

## Documentation

| Document | What it covers |
| --- | --- |
| [`docs/BALANCE.md`](docs/BALANCE.md) | The economy: levels, worlds, rebirths, shop prices, and how to retune any of it |
| [`docs/MAP.md`](docs/MAP.md) | Building a map: every tag, every attribute |
| [`docs/MONETISATION.md`](docs/MONETISATION.md) | The business model and what is sold |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | How the code is laid out |
| [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) | Working on it: tests, lint, the loop |
| [`docs/ICONS.md`](docs/ICONS.md), [`docs/TEXTURES.md`](docs/TEXTURES.md) | Art assets and how they are uploaded |

---

## Several themes, one game

The rules know only neutral notions — speed, currency, prestige, segment, checkpoint.
What the player reads and sees, the words as much as the icons and the colours, is
decided separately.

A new theme therefore re-skins the entire game **without touching a single rule**, and
several can ship side by side. The balancing never moves from one theme to the next:
two players on two themes stay comparable.

---

## The courses

Maps are **built by hand**, not generated. The server only reads what the map
declares: where the checkpoints, the traps, the conveyors, the trampolines, the Coins,
the gates and the starting-area pads are.

The void declares nothing: any fall below the lowest point of the map is detected
automatically.

---

## Worth knowing

- Progress is **saved automatically**. If a save fails, the game stays playable and
  the existing save is never overwritten.
- Speed is **measured by the server** from real displacement: actually running is the
  only way to progress.
- Purchases are **credited exactly once** and cannot be lost, even if the connection
  drops during payment.
