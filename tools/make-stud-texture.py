"""
Draws the seamless stud plate the interface buttons wear.

WHY A MADE TEXTURE. Everything in the imported pack is a photograph of a real
material — plaster, metal, marble, snow. At the size of a button, a photograph of
anything reads as grime: the game wants moulded plastic, and nothing photographic
says toy. This draws the one thing that does.

SEAMLESS BY CONSTRUCTION, not by touching up an edge. The studs sit on a lattice
whose period divides the tile, and every one is drawn nine times — at the tile and
at each of its eight neighbours — so a stud crossing an edge comes back whole on
the other side.

The rows are STAGGERED. A square lattice grows visible lines the moment it is
tiled, because the eye joins the dots along the axes; offsetting every other row
leaves it nothing to join.

The tile is greyscale and near white on purpose. Widgets tints it with the colour
of whatever it lies on, which multiplies: white areas come back as that exact
colour and vanish, and only the shading draws. See docs/TEXTURES.md.

    python tools/make-stud-texture.py
    # then upload textures/studs.png as an Image asset and put the id in the theme
"""

from PIL import Image, ImageDraw, ImageFilter

SIZE = 256  # one tile, in pixels
SPACING = 64  # distance between stud centres
RADIUS = 21

# The three tones of a dome: what it casts, what it is, and what the light hits.
SHADOW = 168
BODY = 205
CAP = 246
GROUND = 255


def stud(draw: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    # Shadow below, body on top of it, lit cap up and to the left. The offset
    # between the three is the whole illusion; drawn concentric it is a flat disc.
    draw.ellipse([cx - RADIUS, cy - RADIUS + 4, cx + RADIUS, cy + RADIUS + 4], fill=SHADOW)
    draw.ellipse([cx - RADIUS, cy - RADIUS, cx + RADIUS, cy + RADIUS], fill=BODY)
    draw.ellipse([cx - RADIUS + 4, cy - RADIUS + 3, cx + RADIUS - 7, cy + RADIUS - 9], fill=CAP)


def main() -> None:
    image = Image.new("L", (SIZE, SIZE), GROUND)
    draw = ImageDraw.Draw(image)

    for row in range(-1, SIZE // SPACING + 2):
        for col in range(-1, SIZE // SPACING + 2):
            x = col * SPACING + (SPACING // 2 if row % 2 else 0)
            y = row * SPACING
            for dx in (-SIZE, 0, SIZE):
                for dy in (-SIZE, 0, SIZE):
                    stud(draw, x + dx, y + dy)

    # Just enough to take the aliasing off the rims without losing the dome.
    image.filter(ImageFilter.GaussianBlur(1.1)).convert("RGB").save("textures/studs.png")
    print("textures/studs.png")


if __name__ == "__main__":
    main()
