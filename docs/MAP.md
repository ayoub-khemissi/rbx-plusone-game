# Map contract

You build the maps in Studio, the server reads them. This document is the contract
between the two: **there is nothing to respect beyond what is written here.**

Everything goes through **tags** (CollectionService) and **attributes**. No naming
convention, no imposed hierarchy: arrange your parts however you like, only the
tags count.

> In Studio, tags are added from **View → Tag Editor**, and attributes from the
> **Properties** panel, *Attributes* section, at the bottom.

---

## The tags

| Tag | Put it on | What the server does with it |
| --- | --- | --- |
| `TrapPart` *(or `Killzone`)* | Part or Model | Kills; back at the Hub after 2 s |
| `Conveyor` | Part | Conveyor belt: pushes along the front face |
| `BouncePad` | Part | Trampoline: launches the player upwards |
| `Coin` | Part **or Model** | Drawn in and collected, per player, back after 30 s |
| `SpeedGate` | Solid part | Blocks while the player's Speed is too low |
| `FinishPad` | Part | Ends a course: pays out and sends the player to the lobby |
| `ShopPad` | Part | Opens the shop |
| `PrestigePad` | Part | Opens the Rebirth window |
| `Treadmill` | Part | Pays as if running on the spot, multiplied |

**A tag can be placed on a Model**: every part inside it is then wired. That is what
lets a decorated pad be tagged once instead of six times.

Only some way to die is genuinely needed, and the void provides that for free. The
rest is added when you want it.

---

## Each tag in detail

### Where a Stage begins

**Nowhere in the map.** A Stage opens when the player's Speed passes what
`Config/Stages.luau` asks of it, and the Stage they are IN is the deepest one they
have opened. There is no marker to place, nothing to tag, and nothing that can fall
out of step with the profile.

So lay the course out in order and put a `SpeedGate` where each section begins. The
gate is the announcement; the Speed is the rule.

### `TrapPart` *(or `Killzone`)*

Anything lethal: lava, spikes, a deadly obstacle. Both names are accepted.

No attributes. The character **dies**, comes back after `Balance.run.respawnDelay`
seconds — two — at the Hub, **keeps their Speed and their Coins**, and loses only
time.

It kills rather than teleports. Snatching a falling character back onto solid ground
reads as a glitch; a death is punctuation the player already knows how to read, and
the seconds before the new body are the price of the mistake.

**The void needs no tag.** At start-up the server finds the lowest part of the map and
treats any fall below that level the same way. There is no invisible slab to lay, and
therefore none to forget.

If your map does lay one anyway — a catcher under the whole course — **tag it**. An
untagged slab is floor: the player lands on it, alive, under the map, with nothing to
run back to. A tagged one is ignored when the void level is measured, so both work
and neither cancels the other.

### `Conveyor`

| Attribute | Type | Required | Role |
| --- | --- | --- | --- |
| `Speed` | number | no | Belt speed. Default: 10 |

The belt pushes along its **front face**: rotate the part in Studio to change the
direction. There is no per-player logic — the Roblox physics engine does the work.

### `BouncePad`

| Attribute | Type | Required | Role |
| --- | --- | --- | --- |
| `BounceImpulse` | number | no | Vertical velocity given. Default: 200 |

The vertical velocity is **replaced**, not added: a pad launches the same whether you
arrive falling or rising.

### `Coin`

| Attribute | Type | Required | Role |
| --- | --- | --- | --- |
| `Value` | number | no | Raw value. Without it, the configured default applies |

A Coin is a **marker**, and it may be a Part **or a Model** — tag whichever one you
want to see turn, and place it where a runner will pass. Everything else is done for
you: a model is measured, turned, drawn in and hidden by its **pivot**, so put the
pivot at the centre of the coin and it will spin on the spot rather than orbit.

The theme names a Coin model of its own (`Config.Theme.models.coin`), which is what
the test platform builds with. A real map does not need it: whatever you tag is what
the player sees.

`Value` is the raw value. What the player receives is that value multiplied by the
Stage they are standing in and by everything they have earned, and the amount thrown
off the character is the multiplied one — the only number that means anything to
them.

**Every player has their own Coins.** Nothing that happens to a Coin is replicated:
each client turns it, draws it in, hides it and brings it back on their own machine.
A course swept clean by whoever ran it a minute ago is still full for the next
player, and two friends running it together are never racing for the same pickup.

A Coin comes back **thirty seconds** after it was taken, or **as soon as the player
respawns** — a fall costs the run, not the money left on it. Both delays live in
`Balance.run`.

The server forces a Coin anchored, non-colliding and untouchable: a Coin is run
through, not into, and it is the client that decides when the player reached it. It
is collected from `Balance.run.coinReach` studs away, plus whatever the Magnet
upgrade adds — the flight towards the player is that radius made visible.

Cost follows what is on screen: Coins further than 200 studs are not touched at all,
and the ones nearer are only measured a few times a second. A map may hold hundreds
of them.

### `SpeedGate`

The barrier guarding the entrance to a Stage. The player only passes if they are fast
enough.

| Attribute | Type | Required | Role |
| --- | --- | --- | --- |
| `RequiredSpeed` | number | **yes** | Minimum Speed to pass |
| `StageId` | number | no | Only used to name the Stage in the message |

Leave it `CanCollide = true`. The client makes it **locally passable** as soon as the
player has the required speed, and the server checks again on its side: there is no
way through by cheating.

### `FinishPad`

The plate at the end of a course. Touching it pays what the course is worth and
returns the player to the lobby.

| Attribute | Type | Required | Role |
| --- | --- | --- | --- |
| `StageId` | number | **yes** | The course this plate ends |

Touching it is a **choice**. A player may walk straight past and carry on into the
next course; the plate is there for anyone who would rather bank the reward and
start again from the lobby.

It is also what records the deepest course a player has cleared — opening one
only says they walked in, the plate says they got through. Put it after the last
obstacle, never before one.

Without a `StageId` the plate names no course, so it is ignored and the console
says so rather than paying out the wrong one.

### `Treadmill`

A belt that pays as if the player were running, while they stand still.

| Attribute | Type | Required | Role |
| --- | --- | --- | --- |
| `Multiplier` | number | no | What the belt is worth. Default: 1 |

It runs the character at **their own** walk speed, multiplied — so a belt
accelerates what a player earned rather than replacing it, and a fast player gets
more out of the same belt.

A belt REPLACES the movement measurement while it is stood on, never adds to it:
walking on the spot must not pay twice.

Nothing is verified here, and nothing needs to be. Ordinary running is checked
against what is physically reachable because the client reports where it went; a
belt is the server deciding how far the character ran, so there is no claim to
check.

### `ShopPad`, `PrestigePad`

The three pads of the starting area. No attributes.

- **`ShopPad`** — opens the upgrade shop when the player steps on it.
- **`PrestigePad`** — triggers a Prestige. The server declines politely if the
  threshold is not met, so there is nothing to handle on your side.


---

## What the map decides, what the configuration decides

This is the split that keeps your hands free:

| The **map** decides | The **configuration** decides |
| --- | --- |
| Where the gaps and the Coins are | What a Coin is worth, how fast it comes back |
| Where the gates are, and their `RequiredSpeed` | The Coin multiplier of each Stage |
| The geometry, the scenery, the mood | The speed curve, the upgrade prices |
| How many Stages there are | The Prestige threshold |

Add a Stage 6 to the map, add it a line in `Config/Stages.luau`, and it exists.
Nothing else.

---

## Starting area: the minimum list

For the game to be playable you need, at a minimum:

1. A standard Roblox **SpawnLocation** (no tag, Roblox handles it)

That is all. A player who falls comes back there, and the void needs no tag of its
own.

When you want the full economic loop, add a `ShopPad`, a `PrestigePad` and a
`Treadmill` or two to the starting area.

---

## What the server will never do

So you know where its responsibility stops:

- it never **moves** and never **creates** a part of your map;
- it depends on no object name and no hierarchy;
- it politely ignores any part that is tagged but misconfigured, writing a warning to
  the console instead of crashing.

A missing attribute takes a default value and the console says so. You cannot break
the server with a map, only get partial behaviour.

---

## Checking your map

At start-up the server writes what it found to the console:

```
[Runner] Map loaded: 11 hazards, 24 coins, 4 conveyors, 1 bounce pads, 7 treadmills
[Runner] Void level set to -184 studs
```

If the count does not match what you placed, a tag was forgotten.

**Without opening Studio**, the same thing can be read straight out of the place
file:

```
./.tools/lune.exe run tools/probe maps/YourMap.rbxl
```

It lists every tagged part with its position and attributes, the SpawnLocation, the
void level, and the scripts embedded in the place. It is the fastest answer to "why
does this obstacle do nothing": if it is not in the list, the tag is missing.

> ⚠️ If the place contains **your own manager scripts** (a `StageManager`, a
> `TrapManager`…), they run **at the same time** as the server, which reads the same
> tags. Two teleports, two velocities. The probe reports them; delete them.
