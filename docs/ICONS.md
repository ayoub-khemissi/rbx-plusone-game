# Icons

Every image the interface shows comes from one icon pack, and every one of them
has a **slot**: a stable name that is at once the staged file name, the name
Roblox lists the upload under, and the `-- icon:<slot>` marker in the
configuration. Keeping those three in step is what turns forty-odd asset ids
from an afternoon of copy-paste into one command.

---

## Uploading a new set

```powershell
./tools/stage-icons.ps1                            # pack  -> icons/, renamed
./tools/upload-icons.ps1 -CreatorId <your user id> # icons/ -> Roblox, ids collected
./tools/apply-icon-ids.ps1                         # ids    -> the four config files
./scripts/check.ps1
```

`upload-icons.ps1` goes through the Open Cloud Assets API and needs an API key
with the `asset:write` scope, created at **create.roblox.com → Settings →
Credentials → API Keys**. Put it in `icons/api-key.txt` (ignored by git, never
printed) or in `ROBLOX_API_KEY`. Add `-Group` if the assets belong to a group
rather than to your account.

The run is **resumable**: each id is appended to `icons/ids.txt` the moment it
comes back, and a slot already listed is skipped. A rate limit or a closed
terminal costs only the uploads that had not finished — run the same command
again.

### Image, not Decal

The Assets API accepts both `Image` and `Decal` for a PNG. **Only `Image` renders
in an `ImageLabel`.** `upload-icons.ps1` sends `Image`; `-AssetType Decal` exists
for the day that changes, and is otherwise a trap.

A Decal uploaded through Open Cloud fails in the most expensive way available: it
reports `Approved` and `Active`, appears in the creator dashboard showing the
right picture, and draws nothing in a label. There is no error, no warning, and
no console output — the interface simply comes up blank.

Three checks were run before that was found, and none of them could have
distinguished a broken asset from a working one:

| Looks like a problem | What it actually means |
| --- | --- |
| Every asset returns the same placeholder thumbnail | The asset is private. Says nothing about content |
| Its page on the store is broken | That is the public view of a private asset |
| The creator dashboard shows it correctly | The dashboard renders any type. Says nothing about labels |

What settled it was a **controlled comparison**: the same PNG uploaded twice,
once as each type, and both ids put side by side in one place. One rendered, one
did not, and there was nothing left to interpret.

Keep the recipe for the next silent failure — one file, two uploads, one
parameter different, both on screen at once:

```lua
-- Studio command bar. Renders immediately, no Play needed.
local g = Instance.new("ScreenGui", game.CoreGui) g.Name = "Probe"
local a = Instance.new("ImageLabel", g)
a.Size = UDim2.fromOffset(220, 220) a.Position = UDim2.fromOffset(60, 240)
a.BackgroundColor3 = Color3.new(1, 0, 0) a.Image = "rbxassetid://FIRST"
local b = a:Clone() b.Position = UDim2.fromOffset(300, 240)
b.BackgroundColor3 = Color3.new(0, 0, 1) b.Image = "rbxassetid://SECOND" b.Parent = g
-- Clean up:  game.CoreGui.Probe:Destroy()
```

The coloured backgrounds are not decoration. A label that loads nothing is
invisible, so without them a blank result cannot be told apart from a label you
failed to find.

### By hand instead

1. Studio → **View → Asset Manager** → **Images** → right-click → *Add Images…*
2. Select everything in `icons/` and upload
3. For each one, right-click → *Copy Asset ID*
4. Write them into `icons/ids.txt`, one `slot=id` per line, then run
   `./tools/apply-icon-ids.ps1`

The staged files are named after their slot precisely so that this stays a
lookup: Roblox lists uploads under their file name.

`apply-icon-ids.ps1 -DryRun` reports what it would change without saving.

An id you do not have yet is simply left out of `ids.txt`: the slot keeps
whatever it holds today, and nothing breaks while a set is half uploaded.

---

## Choosing a different icon for a slot

`tools/icon-map.json` maps each slot to a file in the pack. Change the path,
re-run `stage-icons.ps1`, upload that one file, and put its id in `ids.txt`.
The configuration never has to be touched by hand.

The pack ships several variants of most icons — colours, a `1st` and a `2nd`
shape, and an `Outline` version. **The outlined ones are the right choice here**:
the interface is built on heavy dark strokes, and a flat icon dropped into it
reads as a hole rather than a symbol.

---

## The slots

### Theme labels — `Config/Themes/Default.luau`

| Slot | Icon from the pack | Shown in |
| --- | --- | --- |
| `speed` | Main/Lighting/Lighting 1st Outline | HUD counter |
| `coins` | Currency/Coin/Golden Coin 1st Outline | HUD counter |
| `prestige` | Main/Rebirth and Auto Open/Rebirth 1st Outline | HUD counter and sidebar |
| `stage` | Main/Star/Golden Star 1st Outline | Stage names |
| `hub` | Main/House/Blue House 1st Outline | Starting area |
| `charm` | Item/Potion/Purple Potion 1st Outline | Reserved for a later milestone |

### Theme icons — `Config/Themes/Default.luau`

| Slot | Icon from the pack | Shown in |
| --- | --- | --- |
| `shop` | Main/Shopping Bag/Red Shopping Bag 1st Outline | Sidebar |
| `gifts` | Item/Gift/Green Gift 1st Outline | Sidebar |
| `store` | Currency/Robux/Golden Robux 1st Outline | Sidebar |
| `codes` | Main/Codes/Codes 1st Outline | Gifts window |
| `settings` | Main/Settings/Settings 1 1st Outline | Reserved |
| `jump` | Item/Coil/Blue Coil 1st Outline | Ability chip |
| `dash` | Item/Rocket/Rocket 1st Outline | Ability chip |
| `upgrade` | Main/Upgrade/Green Upgrade 1st Outline | Shop |
| `magnet` | Item/Magnet/Golden Magnet 1st Outline | Reserved |
| `locked` | Item/Lock/Lock 1st Outline | Reserved |
| `unlocked` | Item/Lock/Unlock 1st Outline | Reserved |
| `playtime` | Item/Clock/Clock 1st Outline | Reserved |
| `boost` | Main/Fire/Fire 1st Outline | Active boosts |
| `luck` | Nature/Clover/Clover 1st Outline | Reserved |

### Upgrades — `Config/Upgrades.luau`

| Slot | Icon from the pack |
| --- | --- |
| `upgradeStride` | Item/Shoe/Yellow Shoe 1st Outline |
| `upgradeFortune` | Currency/Cash/Golden Cash 1st Outline |
| `upgradeSpring` | Item/Coil/Red Coil 1st Outline |
| `upgradeAirJump` | Nature/Cloud/Cloud 1st Outline |
| `upgradeDash` | Item/Rocket/Rocket 2nd Outline |
| `upgradeMagnet` | Item/Magnet/Magnet 1st Outline |

### Gamepasses — `Config/Passes.luau`

| Slot | Icon from the pack |
| --- | --- |
| `passDoubleCoins` | Currency/Coin/Golden Coin 2nd Outline |
| `passDoubleSpeed` | Main/Lighting/Blue Lighting 1st Outline |
| `passSwiftBoots` | Item/Shoe/Blue Shoe 1st Outline |
| `passExtraJump` | Item/Coil/Yellow Coil 2nd Outline |
| `passCoinMagnet` | Item/Magnet/Golden Magnet 2nd Outline |
| `passAutoRun` | Main/Hoverboard/Blue Hoverboard 1st Outline |

### Products — `Config/Products.luau`

| Slot | Icon from the pack |
| --- | --- |
| `productCoinsSmall` | Currency/Cash/Blue Cash 1st Outline |
| `productCoinsMedium` | Main/Shopping Bag/Golden Shopping Bag 1st Outline |
| `productCoinsLarge` | Item/Chest/Chest 1st Outline |
| `productCoinsHuge` | Item/Crown/Crown 1st Outline |
| `productSpeedRush` | Main/Lighting/Red Lighting 1st Outline |
| `productCoinRush` | Main/Fire/Fire 2nd Outline |
| `productPartyTime` | Player/4 Players/4 Players 1st Outline |
| `productInstantChest` | Item/Chest/Chest 2nd Outline |
| `productInstantPrestige` | Main/Rebirth and Auto Open/Rebirth 2nd Outline |
| `productStarterPack` | Item/Gift/Purple Gift 1st Outline |

---

## Licence

The pack is *Free Icon Pack v3.1* by **@gvesster**. Commercial use and client
work are allowed; reselling the icons, or editing them to build another pack,
is not. Crediting the author is optional and appreciated.

Neither the pack nor `icons/` is committed: both are large, neither is project
source, and the staged copies are reproducible with one command.
