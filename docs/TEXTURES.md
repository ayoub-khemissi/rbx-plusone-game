# Textures

The pack you imported arrives as **display blocks**: 482 parts whose only job is to
show the textures off. You need none of those blocks to build a map — only the
identifiers, and they are all below.

> **Delete the `Textures` model from the Workspace** once this document is at hand.
> It is 3894 instances loaded by every player, for nothing.

---

## Putting a texture on YOUR parts

### The right way: a Material Variant

This is the answer to "I want the texture, not the block". A Material Variant is a
material you create once and then apply to any part, exactly like Brick or Wood.

1. In Studio, open **View → Material Manager**
2. Pick a base material in the left column (`Plastic` works for everything)
3. Click the **+** at the top of the panel: a `MaterialVariant` appears
4. Rename it (`StoneFloor`, `LavaRock`…) — that name is what you will see everywhere
5. Paste an identifier from the catalogue into the **ColorMap** field
6. Set **StudsPerTile**: the size of one tile in studs. 4 is a good start for a
   floor, 8 for a wall seen from a distance

To paint: select your parts and click the material in the Material Manager. The
texture covers **all six faces**, repeats on its own whatever the size of the part,
and follows you when you resize.

**Why not the `Texture` objects** the pack uses on its demo blocks: a `Texture` covers
**one face only**. A cube needs six, a 300-part course needs 1800, and each one is
another instance to replicate. A Material Variant needs one, for the whole map.

### The special case of PBR materials

The 10 `PBRTextures` materials are not flat images but `SurfaceAppearance` objects:
they react to light, with relief, gloss and metalness. They apply to **MeshPart**
only, never to an ordinary part. To keep one, copy the `SurfaceAppearance` from its
demo block into your MeshPart **before** deleting the pack.

### What this does not change

No texture changes anything about the game. The server reads only the **tags**
described in [MAP.md](MAP.md): a beautiful part without a `TrapPart` tag kills nobody,
and a grey part with the tag kills perfectly well. Decorate once the geometry works,
not before.

---

## The catalogue

The *tile* column repeats the pack's original `StudsPerTile`: a starting point, not a
rule.

### Floors

| Name | ColorMap | Tile |
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

### Walls

| Name | ColorMap | Tile |
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

### Ceilings

| Name | ColorMap | Tile |
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

### Roofs

| Name | ColorMap | Tile |
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

### Terrain

| Name | ColorMap | Tile |
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

### Glass and translucent surfaces

| Name | ColorMap | Tile |
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

### Named — stone, wood, metal, snow, sand

| Name | ColorMap | Tile |
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

### PBR materials — MeshPart only

| Name | ColorMap |
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

| Name | ColorMap |
| --- | --- |
| LowPoly | `rbxassetid://6794063173` |
| LowPoly2 | `rbxassetid://6904986063` |

---

## Textures in the interface

The theme lays two of these textures over the interface, at around a quarter
opacity, tinted with a darker shade of whatever they lie on.
Colour alone renders as vinyl; a grain under it reads as a moulded object, which is
the look every simulator interface is after. Two lines in
`src/Shared/Config/Themes/Default.luau`:

```lua
textures = {
	panelPattern = "rbxassetid://4621488899", -- large_square_pattern
	panelOpacity = 0.18,
	panelTile = 64,
	buttonPattern = "rbxassetid://4549727994", -- metal
	buttonOpacity = 0.22,
	buttonTile = 96,
},
```

**The opacities are the dial, and the tiles are how big one repeat is drawn.** Too
faint and the grain is a rumour nobody sees; too strong and it becomes a pattern the
eye reads instead of the words on top of it. The buttons carry more than the panels —
they are small, saturated and glossy, and the same value on both leaves them looking
bare beside the windows.

A tile wants to be large enough that a button shows one or two repeats rather than a
mosaic of them: the texture should read as the surface the thing is made of, not as
something printed on it.

**The grain darkens; it never lightens.** Every tile in this pack is a light image,
and laying one over a saturated fill bleaches it — which costs the white text on top
exactly the contrast the texture was meant to be worth. Each surface tints its own
grain with a darker shade of its own colour, so a button gains shading in its own hue
and the text gains contrast rather than losing it. That is also why the veil over a
button's glyphs is harmless: it darkens them slightly, and they are white.

**They are chosen for what they sit on.** The panels wear a grid of large squares —
the plate a simulator window is built from, and a motif that reads well across a wide
surface. The buttons wear a fine rough plaster, because a grid on something the size
of a button becomes a pattern competing with the word written across it.

Set either to `nil` and that surface goes smooth again. Other clean candidates:
`marble`, `plaster_grey`, `large_floor_tiles` for panels; `white_plaster_rough`,
`plaster_grey`, `marble` for buttons.

An interface pattern must be **seamless and low contrast**. A brick or wood texture
works badly here: the motif shows through, and the text sits on top of it.

A button writes its words in a child label rather than in itself, which is what keeps
the grain **under** them — and it is not only the grain: a UIGradient tints the glyphs
of the object it is on, so the gloss on a button used to dim its own white text
towards the bottom. A gradient does not reach descendants. The label also carries the
dark outline every big number in the game wears, which a TextButton could never have
had: it spends its single UIStroke on its border.

Set a button's words through `Widgets.setButtonText`, never by assigning `.Text` —
that writes into a string nothing draws.
