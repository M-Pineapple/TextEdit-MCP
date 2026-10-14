#!/usr/bin/env python3
"""Build docs/demo.gif: a simulated MCP client creating a formatted RTF.

This is not a live macOS capture. It shows the real tool flow: a chat host
asks for a document, create_rtf_document runs, and a TextEdit-style preview
of the saved RTF appears.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "demo.gif"
PREVIEW_DIR = Path("/tmp/textedit-demo-previews")

# Final GIF size (GitHub README column is ~880px; keep a little headroom).
W, H = 800, 460
SCALE = 2  # draw at 2x, then downsample for cleaner edges
FPS = 10
HOLD_END_S = 1.8

FONT_DIR = Path("/usr/share/fonts/truetype")
INTER = FONT_DIR / "macos"
JB = FONT_DIR / "jetbrains-mono"
NOTO = FONT_DIR / "noto"

# Palette aligned with assets/logo.svg
BG = (11, 18, 32)
WINDOW = (15, 23, 42)
CHROME = (30, 41, 59)
BORDER = (51, 65, 85)
MUTED = (100, 116, 139)
TEXT = (226, 232, 240)
SOFT = (148, 163, 184)
GOLD = (251, 191, 36)
GOLD_DIM = (180, 140, 40)
USER_BG = (30, 58, 95)
CLAUDE_BG = (20, 32, 52)
TOOL_BG = (8, 14, 26)
PAPER = (254, 252, 232)
PAPER_EDGE = (253, 230, 138)
INK = (30, 41, 59)
INK_SOFT = (71, 85, 105)
RED = (185, 28, 28)
BLUE = (37, 99, 235)
GREEN = (22, 163, 74)
HILITE = (253, 224, 71)
TABLE_HEAD = (30, 41, 59)
TRAFFIC = ((239, 68, 68), (234, 179, 8), (34, 197, 94))

USER_MSG = "Create a standup RTF on my Desktop with blockers in a table."
CLAUDE_MSG = "I'll call TextEdit MCP and save a formatted RTF."
TOOL_NAME = "create_rtf_document"
TOOL_PATH = "~/Desktop/Standup-14-Oct.rtf"
TOOL_META = "template: meeting"
TOOL_CONTENT = "content: # Standup + table"
SUCCESS = "Saved Standup-14-Oct.rtf"


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size * SCALE)


def load_fonts() -> dict[str, ImageFont.FreeTypeFont]:
    return {
        "ui": font(INTER / "Inter-Regular.ttf", 13),
        "ui_m": font(INTER / "Inter-Medium.ttf", 13),
        "ui_sb": font(INTER / "Inter-SemiBold.ttf", 13),
        "ui_sm": font(INTER / "Inter-Medium.ttf", 11),
        "caption": font(INTER / "Inter-Medium.ttf", 12),
        "title": font(INTER / "Inter-SemiBold.ttf", 12),
        "mono": font(JB / "JetBrainsMono-Regular.ttf", 11),
        "mono_b": font(JB / "JetBrainsMono-Medium.ttf", 11),
        "h1": font(NOTO / "NotoSerif-Bold.ttf", 20),
        "h2": font(NOTO / "NotoSerif-Bold.ttf", 13),
        "body": font(NOTO / "NotoSerif-Regular.ttf", 12),
        "body_b": font(NOTO / "NotoSerif-Bold.ttf", 12),
        "small": font(INTER / "Inter-Medium.ttf", 10),
        "table": font(INTER / "Inter-Regular.ttf", 11),
        "table_b": font(INTER / "Inter-SemiBold.ttf", 11),
        "status": font(INTER / "Inter-SemiBold.ttf", 11),
    }


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * max(0.0, min(1.0, t))


def ease(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def typed(text: str, t: float, start: float, cps: float = 32) -> tuple[str, bool]:
    if t < start:
        return "", False
    n = int((t - start) * cps)
    done = n >= len(text)
    return text[: min(n, len(text))], done


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont, width: int) -> list[str]:
    words = text.split(" ")
    lines: list[str] = []
    current = ""
    for word in words:
        trial = word if not current else f"{current} {word}"
        if draw.textlength(trial, font=fnt) <= width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines or [""]


def window_chrome(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    title: str,
    fonts: dict[str, ImageFont.FreeTypeFont],
    radius: int,
) -> int:
    x0, y0, x1, y1 = box
    draw.rounded_rectangle(box, radius=radius, fill=WINDOW, outline=BORDER, width=SCALE)
    bar_h = 34 * SCALE
    # Title bar: fill then re-round the top by covering the lower corners later
    draw.rounded_rectangle((x0, y0, x1, y0 + bar_h + 12 * SCALE), radius=radius, fill=CHROME)
    draw.rectangle((x0, y0 + bar_h, x1, y0 + bar_h + 14 * SCALE), fill=WINDOW)
    draw.line((x0, y0 + bar_h, x1, y0 + bar_h), fill=(11, 18, 32), width=SCALE)

    cx, cy, r = x0 + 18 * SCALE, y0 + bar_h // 2, 5 * SCALE
    for colour in TRAFFIC:
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=colour)
        cx += 16 * SCALE

    tw = draw.textlength(title, font=fonts["title"])
    tx = (x0 + x1 - tw) / 2
    draw.text((tx, y0 + 10 * SCALE), title, font=fonts["title"], fill=SOFT)
    return y0 + bar_h


def bubble(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    lines: list[str],
    fnt: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
    align: str,
    max_w: int,
    accent: tuple[int, int, int] | None = None,
    caret: bool = False,
) -> int:
    pad_x, pad_y, gap = 12 * SCALE, 9 * SCALE, 4 * SCALE
    line_h = 18 * SCALE
    text_w = max((draw.textlength(line, font=fnt) for line in lines), default=0)
    bw = min(max_w, int(text_w + pad_x * 2))
    bh = pad_y * 2 + line_h * len(lines) + gap * max(0, len(lines) - 1) - gap
    x, y = xy
    if align == "right":
        x = xy[0] - bw
    draw.rounded_rectangle((x, y, x + bw, y + bh), radius=10 * SCALE, fill=fill)
    if accent:
        draw.rounded_rectangle(
            (x, y, x + 4 * SCALE, y + bh),
            radius=2 * SCALE,
            fill=accent,
        )
    ty = y + pad_y
    for line in lines:
        draw.text((x + pad_x, ty), line, font=fnt, fill=TEXT)
        ty += line_h
    if caret:
        last = lines[-1] if lines else ""
        cx = x + pad_x + int(draw.textlength(last, font=fnt)) + 2 * SCALE
        cy = y + pad_y + line_h * max(0, len(lines) - 1)
        draw.rectangle((cx, cy, cx + 2 * SCALE, cy + 14 * SCALE), fill=GOLD)
    return bh


def draw_table(
    draw: ImageDraw.ImageDraw,
    origin: tuple[int, int],
    fonts: dict[str, ImageFont.FreeTypeFont],
    reveal: float,
) -> None:
    x, y = origin
    cols = [86 * SCALE, 58 * SCALE, 92 * SCALE]
    headers = ["Item", "Owner", "Status"]
    rows = [
        ("API review", "Sam", "blocked"),
        ("Docs pass", "Alex", "progress"),
    ]
    row_h = 22 * SCALE
    total_w = sum(cols)
    # header
    draw.rounded_rectangle((x, y, x + total_w, y + row_h), radius=4 * SCALE, fill=TABLE_HEAD)
    cx = x + 8 * SCALE
    for i, h in enumerate(headers):
        draw.text((cx, y + 5 * SCALE), h, font=fonts["table_b"], fill=PAPER)
        cx += cols[i]

    for r, (item, owner, status) in enumerate(rows):
        if reveal < 0.28 + r * 0.22:
            continue
        ry = y + row_h * (r + 1)
        bg = (255, 255, 255) if r % 2 == 0 else (254, 249, 214)
        draw.rectangle((x, ry, x + total_w, ry + row_h), fill=bg)
        draw.line((x, ry + row_h, x + total_w, ry + row_h), fill=(226, 216, 180), width=SCALE)
        vals = [item, owner, status]
        cx = x + 8 * SCALE
        for i, val in enumerate(vals):
            if i < 2:
                draw.text((cx, ry + 5 * SCALE), val, font=fonts["table"], fill=INK)
            elif val == "blocked":
                draw.text((cx, ry + 5 * SCALE), "Blocked", font=fonts["status"], fill=RED)
            else:
                tw = draw.textlength("In progress", font=fonts["status"])
                draw.rectangle(
                    (cx - 4 * SCALE, ry + 3 * SCALE, cx + tw + 4 * SCALE, ry + 18 * SCALE),
                    fill=HILITE,
                )
                draw.text((cx, ry + 5 * SCALE), "In progress", font=fonts["status"], fill=INK)
            cx += cols[i]
    draw.rectangle((x, y, x + total_w, y + row_h * 3), outline=(214, 201, 150), width=SCALE)


def draw_document(
    draw: ImageDraw.ImageDraw,
    paper: tuple[int, int, int, int],
    fonts: dict[str, ImageFont.FreeTypeFont],
    progress: float,
) -> None:
    x0, y0, x1, y1 = paper
    # Paper
    draw.rounded_rectangle(paper, radius=8 * SCALE, fill=PAPER)
    draw.rounded_rectangle(paper, radius=8 * SCALE, outline=PAPER_EDGE, width=SCALE)

    x = x0 + 18 * SCALE
    y = y0 + 16 * SCALE

    steps = [
        ("h1", "Standup"),
        ("date", "14 Oct 2026"),
        ("h2", "Wins"),
        ("li", "Shipped the path guard for new RTF files"),
        ("h2", "Blockers"),
        ("table", None),
        ("h2", "Next"),
        ("p", "Send the notes to the team."),
    ]
    n = len(steps)
    for i, (kind, value) in enumerate(steps):
        shown = ease((progress - i / n) * n * 1.15)
        if shown <= 0:
            continue
        # Simple fade via slightly lighter ink when appearing
        ink = tuple(int(lerp(PAPER[c], INK[c], shown)) for c in range(3))
        ink_soft = tuple(int(lerp(PAPER[c], INK_SOFT[c], shown)) for c in range(3))

        if kind == "h1":
            draw.text((x, y), value, font=fonts["h1"], fill=ink)
            y += 28 * SCALE
        elif kind == "date":
            draw.text((x, y), value, font=fonts["small"], fill=ink_soft)
            y += 20 * SCALE
        elif kind == "h2":
            y += 6 * SCALE
            draw.text((x, y), value, font=fonts["h2"], fill=ink)
            underline_w = int(draw.textlength(value, font=fonts["h2"]))
            draw.line(
                (x, y + 16 * SCALE, x + underline_w, y + 16 * SCALE),
                fill=tuple(int(lerp(PAPER[c], GOLD_DIM[c], shown)) for c in range(3)),
                width=SCALE,
            )
            y += 22 * SCALE
        elif kind == "li":
            r = 3 * SCALE
            cy = y + 8 * SCALE
            draw.ellipse((x, cy - r, x + 2 * r, cy + r), fill=ink)
            # Bold lead-in
            draw.text((x + 14 * SCALE, y), "Shipped", font=fonts["body_b"], fill=ink)
            lead = draw.textlength("Shipped ", font=fonts["body_b"])
            draw.text(
                (x + 14 * SCALE + lead, y),
                "the path guard for new RTF files",
                font=fonts["body"],
                fill=ink,
            )
            y += 20 * SCALE
        elif kind == "table":
            draw_table(draw, (x, y), fonts, shown)
            y += 74 * SCALE
        elif kind == "p":
            draw.text((x, y), value, font=fonts["body"], fill=ink)
            y += 18 * SCALE


def draw_frame(t: float, fonts: dict[str, ImageFont.FreeTypeFont]) -> Image.Image:
    img = Image.new("RGB", (W * SCALE, H * SCALE), BG)
    draw = ImageDraw.Draw(img)

    # Caption
    caption = "Simulated demo  ·  not a live macOS capture  ·  TextEdit MCP writes a real .rtf"
    cw = draw.textlength(caption, font=fonts["caption"])
    draw.text(((W * SCALE - cw) / 2, 12 * SCALE), caption, font=fonts["caption"], fill=MUTED)

    gap = 14 * SCALE
    top = 36 * SCALE
    side = 14 * SCALE
    bottom = H * SCALE - 14 * SCALE
    pane_w = (W * SCALE - side * 2 - gap) // 2
    left_box = (side, top, side + pane_w, bottom)
    right_box = (side + pane_w + gap, top, W * SCALE - side, bottom)

    # Left: chat
    content_top = window_chrome(draw, left_box, "Claude Desktop", fonts, 14 * SCALE)
    inner_pad = 14 * SCALE
    ix0 = left_box[0] + inner_pad
    ix1 = left_box[2] - inner_pad
    max_bubble = int((ix1 - ix0) * 0.92)

    user_text, user_done = typed(USER_MSG, t, 0.25, cps=28)
    y = content_top + 16 * SCALE
    if user_text:
        lines = wrap(draw, user_text, fonts["ui"], max_bubble - 24 * SCALE)
        blink = int(t * 4) % 2 == 0 and not user_done
        bh = bubble(
            draw,
            (ix1, y),
            lines,
            fonts["ui"],
            USER_BG,
            "right",
            max_bubble,
            caret=blink or (not user_done and user_text[-1:] != ""),
        )
        y += bh + 12 * SCALE

    if t >= 2.45:
        claude_text, _ = typed(CLAUDE_MSG, t, 2.45, cps=36)
        if claude_text:
            lines = wrap(draw, claude_text, fonts["ui"], max_bubble - 24 * SCALE)
            bh = bubble(
                draw,
                (ix0, y),
                lines,
                fonts["ui"],
                CLAUDE_BG,
                "left",
                max_bubble,
                accent=GOLD,
            )
            y += bh + 12 * SCALE

    if t >= 3.55:
        # Tool call card
        card_h = 108 * SCALE
        draw.rounded_rectangle(
            (ix0, y, ix1, y + card_h),
            radius=10 * SCALE,
            fill=TOOL_BG,
            outline=GOLD_DIM,
            width=SCALE,
        )
        draw.text((ix0 + 12 * SCALE, y + 10 * SCALE), "Tool", font=fonts["small"], fill=GOLD)
        name, _ = typed(TOOL_NAME, t, 3.6, cps=24)
        draw.text((ix0 + 12 * SCALE, y + 26 * SCALE), name, font=fonts["mono_b"], fill=GOLD)
        path_shown, _ = typed(TOOL_PATH, t, 4.15, cps=28)
        draw.text((ix0 + 12 * SCALE, y + 44 * SCALE), path_shown, font=fonts["mono"], fill=SOFT)
        if t >= 4.7:
            meta, _ = typed(TOOL_META, t, 4.7, cps=24)
            draw.text((ix0 + 12 * SCALE, y + 62 * SCALE), meta, font=fonts["mono"], fill=MUTED)
        if t >= 5.15:
            content, _ = typed(TOOL_CONTENT, t, 5.15, cps=26)
            draw.text((ix0 + 12 * SCALE, y + 80 * SCALE), content, font=fonts["mono"], fill=MUTED)
        y += card_h + 12 * SCALE

    if t >= 6.35:
        ok, _ = typed(SUCCESS, t, 6.35, cps=32)
        if ok:
            lines = wrap(draw, ok, fonts["ui_m"], max_bubble - 24 * SCALE)
            bubble(
                draw,
                (ix0, y),
                lines,
                fonts["ui_m"],
                (20, 50, 40),
                "left",
                max_bubble,
                accent=GREEN,
            )

    # Right: document preview
    right_title = "Standup-14-Oct.rtf" if t >= 5.35 else "TextEdit"
    r_content = window_chrome(draw, right_box, right_title, fonts, 14 * SCALE)
    paper = (
        right_box[0] + 16 * SCALE,
        r_content + 14 * SCALE,
        right_box[2] - 16 * SCALE,
        right_box[3] - 16 * SCALE,
    )
    draw.rounded_rectangle(
        (paper[0] + 3 * SCALE, paper[1] + 5 * SCALE, paper[2] + 3 * SCALE, paper[3] + 5 * SCALE),
        radius=8 * SCALE,
        fill=(8, 12, 22),
    )

    doc_progress = ease((t - 5.35) / 1.35) if t >= 5.35 else 0.0
    if doc_progress <= 0:
        draw.rounded_rectangle(paper, radius=8 * SCALE, fill=PAPER)
        draw.rounded_rectangle(paper, radius=8 * SCALE, outline=PAPER_EDGE, width=SCALE)
        placeholder = "Waiting for create_rtf_document…"
        pw = draw.textlength(placeholder, font=fonts["ui"])
        px = (paper[0] + paper[2] - pw) / 2
        py = (paper[1] + paper[3]) / 2 - 8 * SCALE
        draw.text((px, py), placeholder, font=fonts["ui"], fill=INK_SOFT)
    else:
        draw_document(draw, paper, fonts, doc_progress)

    # Footer strip on the document once saved
    if t >= 6.5:
        label = "Opens in TextEdit, Pages, and Word"
        lw = draw.textlength(label, font=fonts["small"])
        draw.text(
            ((paper[0] + paper[2] - lw) / 2, paper[3] - 22 * SCALE),
            label,
            font=fonts["small"],
            fill=INK_SOFT,
        )

    return img.resize((W, H), Image.Resampling.LANCZOS)


def timeline() -> list[float]:
    # Unique frames until the document is complete. The last frame holds.
    times = []
    t = 0.0
    step = 1.0 / FPS
    end = 7.2
    while t <= end + 1e-6:
        times.append(round(t, 4))
        t += step
    return times


def save_gif(frames: list[Image.Image], durations: list[int], path: Path) -> None:
    work = path.with_suffix(".raw.gif")
    frames[0].save(
        work,
        save_all=True,
        append_images=frames[1:],
        duration=durations,
        loop=0,
        optimize=False,
        disposal=2,
    )
    # Palette-compress with ffmpeg for a small, clean GIF.
    import subprocess

    pal = path.with_suffix(".palette.png")
    subprocess.run(
        [
            "ffmpeg", "-y", "-v", "error",
            "-i", str(work),
            "-vf", "palettegen=max_colors=72:stats_mode=diff",
            str(pal),
        ],
        check=True,
    )
    subprocess.run(
        [
            "ffmpeg", "-y", "-v", "error",
            "-i", str(work),
            "-i", str(pal),
            "-lavfi", "paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle",
            str(path),
        ],
        check=True,
    )
    work.unlink(missing_ok=True)
    pal.unlink(missing_ok=True)


def main() -> None:
    fonts = load_fonts()
    times = timeline()
    frames = [draw_frame(t, fonts) for t in times]
    durations = [int(1000 / FPS)] * len(frames)
    durations[-1] = int(HOLD_END_S * 1000)

    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    preview_at = [0.6, 2.4, 4.4, 5.6, 7.2]
    for stamp in preview_at:
        idx = min(range(len(times)), key=lambda i: abs(times[i] - stamp))
        frames[idx].save(PREVIEW_DIR / f"t{stamp:.1f}.png")

    save_gif(frames, durations, OUT)
    size_kb = OUT.stat().st_size / 1024
    print(f"Wrote {OUT} ({size_kb:.0f} KB, {len(frames)} frames)")
    if size_kb > 2048:
        raise SystemExit(f"GIF is {size_kb:.0f} KB, over the 2 MB cap")


if __name__ == "__main__":
    main()
