"""Painted art (white bg, any format) -> cropped transparent PNG sprites.

Content is cropped to its bounding box and padded to a square. Tall art
(spikes) is bottom-aligned so the base sits on the texture's bottom edge,
which lets the game anchor it to the ground. Wide art is centered.
"""
from collections import deque

from PIL import Image

ASSETS = r"C:\Users\lenovo\Projects\youre-the-food\assets"
CURSOR_IMGS = (r"C:\Users\lenovo\.cursor\projects\c-Users-lenovo-Projects-youre-the-food"
               r"\assets")
NEAR_WHITE = 232
OUT_SIZE = 256
DIGIT_HEIGHT = 160

# (source path, destination path, mode)
# mode "square": pad to square (world sprites)
# mode "height": keep aspect, fixed height (font digits)
JOBS = [
    (f"{CURSOR_IMGS}\\c__Users_lenovo_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_spike-e5fd08e1-ea0d-467d-9fc9-3eee1daaca3e.png",
     f"{ASSETS}\\spike.png"),
    (f"{CURSOR_IMGS}\\c__Users_lenovo_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_spikebroken-d4c62471-8e4a-418f-af3b-f68a80bf9449.png",
     f"{ASSETS}\\spike_broken.png"),
    (f"{CURSOR_IMGS}\\c__Users_lenovo_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_exclemtationmark-0565cc49-32a0-4f1d-9ec6-29002c5dbf0f.png",
     f"{ASSETS}\\spike_warn.png"),
    (f"{CURSOR_IMGS}\\c__Users_lenovo_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_pointarrow-bf0af9ed-b128-4449-9e0e-41b961cb6a3f.png",
     f"{ASSETS}\\spike_arrow.png"),
    (f"{CURSOR_IMGS}\\c__Users_lenovo_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_antwalk1-715763cc-0dfd-4848-b232-ce117d3aa094.png",
     f"{ASSETS}\\ant_walk1.png"),
    (f"{CURSOR_IMGS}\\c__Users_lenovo_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_antwalk2-78bf8cad-8673-4c52-af2b-d82b63d09bda.png",
     f"{ASSETS}\\ant_walk2.png"),
    (f"{CURSOR_IMGS}\\c__Users_lenovo_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_lightingforspeedvis-8ee1c688-8672-4ead-9346-6ff0c3b777d2.png",
     f"{ASSETS}\\fx_speed_streak.png"),
    (f"{CURSOR_IMGS}\\c__Users_lenovo_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_antsquish-4a9c9c40-726b-4a02-a4b6-121a8306c323.png",
     f"{ASSETS}\\ant_squish.png"),
    (f"{CURSOR_IMGS}\\c__Users_lenovo_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_cutesquish-c3d6408b-7965-4c05-84ef-64e74a952602.png",
     f"{ASSETS}\\critter_squish.png"),
    (f"{CURSOR_IMGS}\\c__Users_lenovo_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_maceball-480e9889-fbf2-4cca-abc0-9e6ccd0ea038.png",
     f"{ASSETS}\\mace_ball.png"),
]

_DIGIT_SRC = {
    0: "number0-d0bab88f-dd25-4a0a-bc7a-b7cf619e34a1",
    1: "number1-510fe090-017d-46b7-8870-7c1e65b6b8b4",
    2: "number2-874e3e67-7747-41ce-b56a-1e611afc401c",
    3: "number3-c3e9caf1-b074-4a06-a9e5-c4cfd0ad2da3",
    4: "number4-35bcac7c-c9d7-45a2-af4e-9a83f1c935c2",
    5: "number5-1dbdb273-e943-49f9-8003-2b016a2554a8",
    6: "number6-6fa4adde-e9cb-4cac-8901-7d61be375d75",
    7: "number7-54949a5c-5373-4654-bf69-cb32f3c4e29e",
    8: "number8-b2e70388-fad9-4f82-9a9d-9368e028b070",
    9: "number9-1f409689-1032-4c5b-a76d-afd8354b1ac2",
}
DIGIT_JOBS = [
    (f"{CURSOR_IMGS}\\c__Users_lenovo_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_{name}.png",
     f"{ASSETS}\\digit_{n}.png")
    for n, name in _DIGIT_SRC.items()
]


def remove_background(img: Image.Image, punch_holes: bool = False) -> Image.Image:
    w, h = img.size
    px = img.load()

    bg = bytearray(w * h)
    if punch_holes:
        # every near-white pixel is background, even enclosed ones
        # (digit holes like 0/6/8/9)
        for y in range(h):
            for x in range(w):
                if min(px[x, y]) >= NEAR_WHITE:
                    bg[y * w + x] = 1
    else:
        # flood fill from the borders so light strokes inside survive
        q = deque()
        for x in range(w):
            q.append((x, 0))
            q.append((x, h - 1))
        for y in range(h):
            q.append((0, y))
            q.append((w - 1, y))
        while q:
            x, y = q.popleft()
            i = y * w + x
            if bg[i]:
                continue
            r, g, b = px[x, y]
            if min(r, g, b) < NEAR_WHITE:
                continue
            bg[i] = 1
            if x > 0:
                q.append((x - 1, y))
            if x < w - 1:
                q.append((x + 1, y))
            if y > 0:
                q.append((x, y - 1))
            if y < h - 1:
                q.append((x, y + 1))

    out = Image.new("RGBA", (w, h))
    opx = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if bg[y * w + x]:
                opx[x, y] = (r, g, b, 0)
                continue
            # feather: near-white pixels touching background fade out
            a = 255
            whiteness = min(r, g, b)
            if whiteness >= NEAR_WHITE - 30:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and bg[ny * w + nx]:
                        a = max(0, min(255, int(
                            (255 - whiteness) * 255 / (255 - NEAR_WHITE + 30))))
                        break
            opx[x, y] = (r, g, b, a)
    return out


def neutralize(img: Image.Image) -> Image.Image:
    """Turn the painted color into white (keeping brush texture and the black
    outline) so the game can modulate it with any color at runtime."""
    px = img.load()
    w, h = img.size
    brightest = 1
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            mx = max(r, g, b)
            if a > 0 and mx > 40 and (mx - min(r, g, b)) / mx > 0.25:
                brightest = max(brightest, mx)
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            mx = max(r, g, b)
            if mx > 40 and (mx - min(r, g, b)) / mx > 0.25:
                v = min(255, round(mx * 255 / brightest))
                px[x, y] = (v, v, v, a)
    return img


def crop_square(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()  # alpha-aware on RGBA
    content = img.crop(bbox)
    w, h = content.size
    side = max(w, h)
    canvas = Image.new("RGBA", (side, side))
    x = (side - w) // 2
    # tall art sits on the bottom edge, wide art is centered
    y = side - h if h == side or h > w else (side - h) // 2
    canvas.paste(content, (x, y))
    return canvas


for src, dst in JOBS:
    img = remove_background(Image.open(src).convert("RGB"))
    img = crop_square(img)
    img = img.resize((OUT_SIZE, OUT_SIZE), Image.LANCZOS)
    img.save(dst)
    print(f"{dst}: {img.size}")

# digits keep their natural width so they can be laid out like a font,
# get their enclosed holes punched out, and are neutralized to white so
# the game can tint them any color
for src, dst in DIGIT_JOBS:
    img = remove_background(Image.open(src).convert("RGB"), punch_holes=True)
    img = neutralize(img)
    img = img.crop(img.getbbox())
    w = max(1, round(img.width * DIGIT_HEIGHT / img.height))
    img = img.resize((w, DIGIT_HEIGHT), Image.LANCZOS)
    img.save(dst)
    print(f"{dst}: {img.size}")

# critter squish gets tinted at runtime too
_sq = f"{ASSETS}\\critter_squish.png"
neutralize(Image.open(_sq).convert("RGBA")).save(_sq)
print(f"{_sq}: neutralized")
