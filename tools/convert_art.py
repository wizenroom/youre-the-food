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

# (source path, destination path)
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
]


def remove_background(img: Image.Image) -> Image.Image:
    w, h = img.size
    px = img.load()

    # flood fill near-white from the borders so light strokes inside survive
    bg = bytearray(w * h)
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
