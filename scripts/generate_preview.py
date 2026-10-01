#!/usr/bin/env python3
"""
Omarchy Undercover - Long Showcase Preview Generator
Generates a comprehensive, ultra-high-resolution showcase banner (preview.png)
incorporating the signature half-macOS / half-Windows split hero banner on top,
native typography, anti-aliased geometry, realistic screenshot drop shadows,
feature badges, and v6.1.0 release highlights.
"""

import os
import subprocess
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)
OUTPUT_PATH = os.path.join(ROOT_DIR, "preview.png")
TMP_ASSETS = "/tmp/undercover_preview_assets"

# Canvas configuration (High-DPI 2560px width)
WIDTH = 2560
MARGIN_X = 140
CARD_WIDTH = WIDTH - (MARGIN_X * 2)  # 2280px
SCREENSHOT_WIDTH = 2176
SCREENSHOT_HEIGHT = 1224             # 16:9 ratio (2176 * 9 / 16 = 1224)
INNER_PAD = (CARD_WIDTH - SCREENSHOT_WIDTH) // 2  # 52px

# Colors
BG_TOP = (11, 15, 23)        # #0b0f17
BG_MID = (15, 21, 33)        # #0f1521
BG_BOT = (9, 12, 18)         # #090c12

CARD_BG = (19, 25, 38)       # #131926
CARD_BORDER = (45, 58, 86)   # #2d3a56
CARD_INNER_BG = (13, 17, 26) # #0d111a
CARD_BORDER_SUBTLE = (36, 48, 72)  # #243048

TEXT_WHITE = (255, 255, 255)
TEXT_TITLE = (248, 250, 252)
TEXT_BODY = (203, 213, 225)
TEXT_MUTED = (148, 163, 184)
TEXT_SUBTLE = (100, 116, 139)

ACCENT_BLUE = (14, 165, 233)
ACCENT_PURPLE = (168, 85, 247)
ACCENT_CYAN = (6, 182, 212)
ACCENT_AMBER = (245, 158, 11)
ACCENT_GREEN = (34, 197, 94)

# Full genuine system fonts
FONTS = {
    "sf_bold": "/home/mister/.local/share/fonts/SF-Pro/SF-Pro-Display-Bold.otf",
    "sf_semibold": "/home/mister/.local/share/fonts/SF-Pro/SF-Pro-Display-Semibold.otf",
    "sf_medium": "/home/mister/.local/share/fonts/SF-Pro/SF-Pro-Display-Medium.otf",
    "sf_regular": "/home/mister/.local/share/fonts/SF-Pro/SF-Pro-Display-Regular.otf",
    "segoe_bold": "/home/mister/.local/share/fonts/SegoeUI/segoeuib.ttf",
    "segoe_semibold": "/home/mister/.local/share/fonts/SegoeUI/seguisb.ttf",
    "segoe_regular": "/home/mister/.local/share/fonts/SegoeUI/segoeui.ttf",
    "mono": "/usr/share/fonts/TTF/CaskaydiaMonoNerdFont-Regular.ttf",
}

def get_font(key, size):
    path = FONTS.get(key, FONTS["sf_regular"])
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.load_default()

def prepare_raster_assets():
    os.makedirs(TMP_ASSETS, exist_ok=True)
    
    # Rasterize logo
    logo_svg = os.path.join(ROOT_DIR, "assets/omarchy-undercover-logo.svg")
    logo_png = os.path.join(TMP_ASSETS, "logo.png")
    subprocess.run(["magick", "-background", "none", "-density", "400", logo_svg, "-resize", "170x170", logo_png], check=True)
    
    # Rasterize apple logo (white)
    apple_svg = os.path.join(ROOT_DIR, "assets/icons/apple-logo.svg")
    apple_png = os.path.join(TMP_ASSETS, "apple.png")
    subprocess.run(["magick", "-background", "none", "-density", "400", apple_svg, "-fill", "#ffffff", "-resize", "56x56", apple_png], check=True)
    
    # Rasterize windows logo
    win_svg = os.path.join(ROOT_DIR, "assets/icons/win11/start.svg")
    win_png = os.path.join(TMP_ASSETS, "win.png")
    subprocess.run(["magick", "-background", "none", "-density", "400", win_svg, "-resize", "56x56", win_png], check=True)

    return logo_png, apple_png, win_png

def draw_rounded_rect_aa(target_img, rect, radius, fill, outline=None, outline_width=1):
    """Draws a mathematically smooth, anti-aliased rounded rectangle."""
    x0, y0, x1, y1 = [int(v) for v in rect]
    w = x1 - x0
    h = y1 - y0
    if w <= 0 or h <= 0:
        return
    
    scale = 3
    sw, sh = w * scale, h * scale
    mask_high = Image.new("L", (sw, sh), 0)
    d_mh = ImageDraw.Draw(mask_high)
    d_mh.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=radius * scale, fill=255)
    mask = mask_high.resize((w, h), Image.Resampling.LANCZOS)
    
    patch = Image.new("RGBA", (w, h), fill)
    if outline and outline_width > 0:
        out_high = Image.new("L", (sw, sh), 0)
        d_oh = ImageDraw.Draw(out_high)
        d_oh.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=radius * scale, outline=255, width=outline_width * scale)
        out_mask = out_high.resize((w, h), Image.Resampling.LANCZOS)
        b_patch = Image.new("RGBA", (w, h), outline)
        patch.paste(b_patch, (0, 0), out_mask)
        
    target_img.paste(patch, (x0, y0), mask)

def draw_pill(canvas, x, y, text, font, bg_color, text_color, padding=(20, 8), border_color=None, border_width=1):
    bbox = font.getbbox(text)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    w = tw + (padding[0] * 2)
    h = th + (padding[1] * 2)
    radius = h // 2
    
    draw_rounded_rect_aa(canvas, [x, y, x + w, y + h], radius=radius, fill=bg_color, outline=border_color, outline_width=border_width)
    
    draw = ImageDraw.Draw(canvas)
    ty = y + padding[1] - bbox[1]
    tx = x + padding[0] - bbox[0]
    draw.text((tx, ty), text, font=font, fill=text_color)
    return w, h

def draw_centered_text(draw, y, text, font, fill, width=WIDTH):
    bbox = font.getbbox(text)
    tw = bbox[2] - bbox[0]
    x = (width - tw) // 2
    draw.text((x, y), text, font=font, fill=fill)
    return y + (bbox[3] - bbox[1])

def create_shadowed_screenshot(im, radius=18, shadow_blur=26, shadow_offset=(0, 14), shadow_alpha=175, border_color=(255, 255, 255, 45), border_width=1):
    """
    Renders screenshot with anti-aliased rounded corners, realistic drop shadow,
    and crisp semi-translucent inner border.
    """
    w, h = im.size
    pad = shadow_blur * 2 + abs(shadow_offset[1]) + 16
    canvas_w = w + pad * 2
    canvas_h = h + pad * 2
    
    # 1. Multi-tier drop shadow
    shadow_mask = Image.new("L", (canvas_w, canvas_h), 0)
    d_sm = ImageDraw.Draw(shadow_mask)
    sx0 = pad + shadow_offset[0]
    sy0 = pad + shadow_offset[1]
    d_sm.rounded_rectangle([sx0, sy0, sx0 + w, sy0 + h], radius=radius, fill=shadow_alpha)
    shadow_blurred = shadow_mask.filter(ImageFilter.GaussianBlur(shadow_blur))
    
    shadow_layer = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    black = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 255))
    shadow_layer.paste(black, (0, 0), shadow_blurred)
    
    # 2. Anti-aliased rounded screenshot
    scale = 3
    mask_high = Image.new("L", (w * scale, h * scale), 0)
    d_mh = ImageDraw.Draw(mask_high)
    d_mh.rounded_rectangle([0, 0, w * scale - 1, h * scale - 1], radius=radius * scale, fill=255)
    mask = mask_high.resize((w, h), Image.Resampling.LANCZOS)
    
    im_rounded = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    im_rounded.paste(im.convert("RGBA"), (0, 0), mask)
    
    # 3. Inner border
    if border_color and border_width > 0:
        out_high = Image.new("L", (w * scale, h * scale), 0)
        d_oh = ImageDraw.Draw(out_high)
        d_oh.rounded_rectangle([0, 0, w * scale - 1, h * scale - 1], radius=radius * scale, outline=255, width=border_width * scale)
        out_mask = out_high.resize((w, h), Image.Resampling.LANCZOS)
        b_patch = Image.new("RGBA", (w, h), border_color)
        im_rounded.paste(b_patch, (0, 0), out_mask)
        
    shadow_layer.paste(im_rounded, (pad, pad), im_rounded)
    return shadow_layer, pad

def create_split_hero_backdrop(hero_w, hero_h):
    """
    Creates the half macOS Sequoia, half Windows 11 Bloom banner
    with a perfectly anti-aliased diagonal glass divider line, ambient glow, and bottom fade.
    """
    mac_wp = os.path.join(ROOT_DIR, "assets/wallpapers/macOS-Sequoia-Dark.jpg")
    win_wp = os.path.join(ROOT_DIR, "assets/wallpapers/win11_bloom_dark.jpg")
    
    im_mac = Image.open(mac_wp).resize((hero_w, hero_h), Image.Resampling.LANCZOS)
    im_win = Image.open(win_wp).resize((hero_w, hero_h), Image.Resampling.LANCZOS)
    
    # 4x supersampled mask for flawless diagonal edge
    scale = 4
    mask_high = Image.new("L", (hero_w * scale, hero_h * scale), 0)
    d_mask = ImageDraw.Draw(mask_high)
    x_top = int(hero_w * 0.45)
    x_bot = int(hero_w * 0.55)
    d_mask.polygon([(0, 0), (x_top * scale, 0), (x_bot * scale, hero_h * scale), (0, hero_h * scale)], fill=255)
    mask = mask_high.resize((hero_w, hero_h), Image.Resampling.LANCZOS)
    
    hero = im_win.convert("RGBA").copy()
    hero.paste(im_mac.convert("RGBA"), (0, 0), mask)
    
    # Glass divider line with multi-layer glow
    line_layer = Image.new("RGBA", (hero_w, hero_h), (0, 0, 0, 0))
    d_line = ImageDraw.Draw(line_layer)
    d_line.line([(x_top, 0), (x_bot, hero_h)], fill=(255, 255, 255, 70), width=12)
    line_blurred = line_layer.filter(ImageFilter.GaussianBlur(5))
    
    sharp_line = Image.new("RGBA", (hero_w, hero_h), (0, 0, 0, 0))
    d_sharp = ImageDraw.Draw(sharp_line)
    d_sharp.line([(x_top, 0), (x_bot, hero_h)], fill=(255, 255, 255, 140), width=5)
    d_sharp.line([(x_top, 0), (x_bot, hero_h)], fill=(255, 255, 255, 240), width=2)
    
    hero = Image.alpha_composite(hero, line_blurred)
    hero = Image.alpha_composite(hero, sharp_line)
    
    # Dark vignette overlay to guarantee perfect contrast and legibility
    overlay = Image.new("RGBA", (hero_w, hero_h), (11, 15, 23, 105))
    hero = Image.alpha_composite(hero, overlay)
    
    # Bottom fade into BG_TOP (11, 15, 23)
    fade_start = hero_h - 340
    fade_layer = Image.new("RGBA", (hero_w, hero_h), (0, 0, 0, 0))
    d_fade = ImageDraw.Draw(fade_layer)
    for y in range(fade_start, hero_h):
        alpha = int(255 * ((y - fade_start) / (hero_h - fade_start)))
        d_fade.line([(0, y), (hero_w, y)], fill=(11, 15, 23, alpha))
    hero = Image.alpha_composite(hero, fade_layer)
    
    return hero

def render_screenshot_card(canvas, card_x, card_y, screenshot_rel_path,
                           badge_text, badge_bg, badge_fg, badge_border,
                           title_text, subtitle_text, callouts, font_family="sf"):
    bold_key = f"{font_family}_bold"
    reg_key = f"{font_family}_regular"
    semi_key = f"{font_family}_semibold"
    
    f_badge = get_font(semi_key, 15)
    f_title = get_font(bold_key, 34)
    f_sub = get_font(reg_key, 21)
    f_callout_tag = get_font(bold_key, 13)
    f_callout_desc = get_font(semi_key, 16)
    
    card_h = 1530
    card_rect = [card_x, card_y, card_x + CARD_WIDTH, card_y + card_h]
    
    # Draw card background & border with anti-aliasing
    draw_rounded_rect_aa(canvas, card_rect, radius=28, fill=CARD_BG, outline=CARD_BORDER, outline_width=1)
    draw = ImageDraw.Draw(canvas)
    
    # Header inside card
    inner_x = card_x + INNER_PAD
    curr_y = card_y + 36
    
    # Badge
    bw, bh = draw_pill(canvas, inner_x, curr_y, badge_text, f_badge, badge_bg, badge_fg, padding=(18, 6), border_color=badge_border)
    draw = ImageDraw.Draw(canvas)
    
    # Title
    title_x = inner_x + bw + 20
    draw.text((title_x, curr_y + 2), title_text, font=f_title, fill=TEXT_TITLE)
    
    # Subtitle
    curr_y += 46
    draw.text((inner_x, curr_y), subtitle_text, font=f_sub, fill=TEXT_MUTED)
    
    # Load and render screenshot with drop shadow
    curr_y += 42
    shot_path = os.path.join(ROOT_DIR, screenshot_rel_path)
    with Image.open(shot_path) as shot_raw:
        shot_resized = shot_raw.resize((SCREENSHOT_WIDTH, SCREENSHOT_HEIGHT), Image.Resampling.LANCZOS)
        shot_shadowed, pad = create_shadowed_screenshot(shot_resized, radius=16, border_color=(255, 255, 255, 45), border_width=1)
        canvas.paste(shot_shadowed, (inner_x - pad, curr_y - pad), shot_shadowed)
        
    curr_y += SCREENSHOT_HEIGHT + 32
    
    # Callout boxes row (3 boxes side by side)
    num_callouts = len(callouts)
    gap = 24
    box_w = (SCREENSHOT_WIDTH - (gap * (num_callouts - 1))) // num_callouts
    box_h = 56
    
    for i, (tag_label, tag_desc) in enumerate(callouts):
        bx = inner_x + i * (box_w + gap)
        draw_rounded_rect_aa(canvas, [bx, curr_y, bx + box_w, curr_y + box_h], radius=12, fill=CARD_INNER_BG, outline=CARD_BORDER_SUBTLE, outline_width=1)
        
        # Mini pill tag inside box
        ptw, pth = draw_pill(canvas, bx + 14, curr_y + 12, tag_label, f_callout_tag, badge_bg, badge_fg, padding=(10, 5), border_color=badge_border)
        
        # Text next to tag
        draw = ImageDraw.Draw(canvas)
        draw.text((bx + 22 + ptw, curr_y + 17), tag_desc, font=f_callout_desc, fill=TEXT_BODY)
        
    return card_y + card_h

def build_showcase():
    print("Preparing vector assets at High-DPI...")
    logo_path, apple_path, win_path = prepare_raster_assets()
    
    TOTAL_HEIGHT = 11200
    print(f"Creating canvas {WIDTH}x{TOTAL_HEIGHT} (High-DPI)...")
    canvas = Image.new("RGBA", (WIDTH, TOTAL_HEIGHT), BG_TOP)
    draw = ImageDraw.Draw(canvas)
    
    # 1. Background vertical gradient
    print("Drawing background gradient...")
    for y in range(TOTAL_HEIGHT):
        t = y / TOTAL_HEIGHT
        if t < 0.5:
            factor = t * 2.0
            r = int(BG_TOP[0] * (1 - factor) + BG_MID[0] * factor)
            g = int(BG_TOP[1] * (1 - factor) + BG_MID[1] * factor)
            b = int(BG_TOP[2] * (1 - factor) + BG_MID[2] * factor)
        else:
            factor = (t - 0.5) * 2.0
            r = int(BG_MID[0] * (1 - factor) + BG_BOT[0] * factor)
            g = int(BG_MID[1] * (1 - factor) + BG_BOT[1] * factor)
            b = int(BG_MID[2] * (1 - factor) + BG_BOT[2] * factor)
        draw.line([(0, y), (WIDTH, y)], fill=(r, g, b, 255))
        
    # 2. Hero Section with Half-macOS & Half-Windows split wallpaper aesthetic
    print("Rendering Split Hero section (Half macOS, Half Windows)...")
    HERO_HEIGHT = 1120
    hero_split = create_split_hero_backdrop(WIDTH, HERO_HEIGHT)
    canvas.paste(hero_split, (0, 0), hero_split)
    
    draw = ImageDraw.Draw(canvas)
    
    f_hero_title = get_font("sf_bold", 76)
    f_hero_sub = get_font("sf_medium", 33)
    f_hero_p = get_font("sf_regular", 23)
    f_badge = get_font("sf_semibold", 16)
    
    y = 80
    # Centered Logo
    with Image.open(logo_path) as logo_img:
        lw, lh = logo_img.size
        canvas.paste(logo_img, ((WIDTH - lw) // 2, y), logo_img)
    y += 186
    
    # Title
    draw_centered_text(draw, y, "OMARCHY UNDERCOVER", f_hero_title, TEXT_WHITE)
    y += 92
    
    # Subtitle
    draw_centered_text(draw, y, "Desktop Camouflage & Transformation Suite for Omarchy Hyprland", f_hero_sub, (224, 231, 255))
    y += 68
    
    # Hero Badges Row (Updated for v6.1.0 and Verified Plugin)
    hero_badges = [
        ("✓ Verified Omarchy Plugin", (6, 78, 59), (110, 231, 183), (16, 185, 129)),
        ("v6.1.0 Release", (30, 58, 138), (147, 197, 253), (59, 130, 246)),
        ("Hyprland Wayland", (19, 78, 74), (94, 234, 212), (20, 184, 166)),
        ("Native Lua Dispatchers", (88, 28, 135), (216, 180, 254), (168, 85, 247)),
        ("Quickshell 4.0+ & Waybar", (67, 56, 202), (199, 210, 254), (99, 102, 241)),
        ("Pixel-Accurate Snapping", (120, 53, 15), (254, 243, 199), (217, 119, 6)),
        ("Safe State Rollback", (20, 83, 45), (134, 239, 172), (34, 197, 94))
    ]
    total_badge_w = 0
    badge_widths = []
    for text, bg, fg, border in hero_badges:
        bbox = f_badge.getbbox(text)
        w = (bbox[2] - bbox[0]) + 40
        badge_widths.append(w)
        total_badge_w += w
    total_badge_w += 14 * (len(hero_badges) - 1)
    
    bx = (WIDTH - total_badge_w) // 2
    for i, (text, bg, fg, border) in enumerate(hero_badges):
        draw_pill(canvas, bx, y, text, f_badge, bg, fg, padding=(20, 8), border_color=border)
        bx += badge_widths[i] + 14
    y += 76
    
    # Description lines
    draw = ImageDraw.Draw(canvas)
    draw_centered_text(draw, y, "Instantly transform your Omarchy Hyprland desktop into a native Apple macOS Sequoia or Windows 11 Fluent environment.", f_hero_p, (241, 245, 249))
    y += 38
    draw_centered_text(draw, y, "Engineered for presentation disguise and privacy with authentic typography, physics, and seamless rollback protection.", f_hero_p, (203, 213, 225))
    y += 120
    
    # Section separator
    draw.line([(MARGIN_X, y), (WIDTH - MARGIN_X, y)], fill=(40, 52, 78), width=1)
    y += 60
    
    # 3. Apple macOS Sequoia Section
    print("Rendering Apple macOS Sequoia section...")
    f_sec_title = get_font("sf_bold", 44)
    f_sec_desc = get_font("sf_regular", 22)
    f_chip = get_font("sf_semibold", 16)
    
    sec_x = MARGIN_X
    with Image.open(apple_path) as a_img:
        canvas.paste(a_img, (sec_x, y + 2), a_img)
    draw.text((sec_x + 68, y), "Apple macOS Sequoia Mode", font=f_sec_title, fill=TEXT_TITLE)
    y += 58
    draw.text((sec_x, y), "Authentic Cupertino desktop experience featuring frosted menu bar, dynamic spring-physics dock, Spotlight search, and Control Center.", font=f_sec_desc, fill=TEXT_MUTED)
    y += 48
    
    mac_chips = [
        ("Frosted Glass Top Bar", (30, 41, 59), (226, 232, 240), (51, 65, 85)),
        ("Dynamic Magnifying Dock", (30, 41, 59), (226, 232, 240), (51, 65, 85)),
        ("Apple Control Center", (30, 41, 59), (226, 232, 240), (51, 65, 85)),
        ("Spotlight Search", (30, 41, 59), (226, 232, 240), (51, 65, 85)),
        ("SF Pro Typography", (30, 41, 59), (226, 232, 240), (51, 65, 85)),
        ("Spring Physics Animations", (30, 41, 59), (226, 232, 240), (51, 65, 85)),
    ]
    cx = sec_x
    for text, bg, fg, border in mac_chips:
        w, _ = draw_pill(canvas, cx, y, text, f_chip, bg, fg, padding=(16, 7), border_color=border)
        cx += w + 12
    y += 66
    
    # Card 1: macOS Dark
    print(" - Card 1: macOS Dark...")
    y = render_screenshot_card(
        canvas, MARGIN_X, y,
        screenshot_rel_path="assets/screenshots/MacOS_Dark.png",
        badge_text="DARK PRESET",
        badge_bg=(59, 7, 100), badge_fg=(233, 213, 255), badge_border=(147, 51, 234),
        title_text="macOS Sequoia — Dark Mode",
        subtitle_text="Night-mode frosted menu bar with polygraph monitor, control center, and dynamic floating dock",
        callouts=[
            ("TOP BAR", "Global menus, polygraph monitor, volume & clock"),
            ("DOCK", "Dynamic magnification, active app dots & trash"),
            ("SHORTCUTS", "Super+Space Spotlight, Super+Tab Mission Control")
        ],
        font_family="sf"
    )
    y += 60
    
    # Card 2: macOS Light
    print(" - Card 2: macOS Light...")
    y = render_screenshot_card(
        canvas, MARGIN_X, y,
        screenshot_rel_path="assets/screenshots/MacOS_Light.png",
        badge_text="LIGHT PRESET",
        badge_bg=(120, 53, 15), badge_fg=(254, 243, 199), badge_border=(217, 119, 6),
        title_text="macOS Sequoia — Light Mode",
        subtitle_text="Daylight aesthetic with high-vibrancy frosted menu bar, authentic light-mode dock, and Sequoia day wallpaper",
        callouts=[
            ("CONTRAST", "Crisp daylight typography, translucent blur & shadow"),
            ("DOCK STYLING", "Light theme glass dock with native Sequoia icons"),
            ("HARMONY", "Seamless light wallpaper and system palette integration")
        ],
        font_family="sf"
    )
    y += 90
    
    draw.line([(MARGIN_X, y), (WIDTH - MARGIN_X, y)], fill=(40, 52, 78), width=1)
    y += 60
    
    # 4. Windows 11 Fluent Section
    print("Rendering Windows 11 Fluent section...")
    f_win_title = get_font("segoe_bold", 44)
    f_win_desc = get_font("segoe_regular", 22)
    f_win_chip = get_font("segoe_bold", 16)
    
    with Image.open(win_path) as w_img:
        canvas.paste(w_img, (sec_x, y + 2), w_img)
    draw.text((sec_x + 68, y), "Windows 11 Fluent Mode", font=f_win_title, fill=TEXT_TITLE)
    y += 58
    draw.text((sec_x, y), "Authentic Redmond desktop experience featuring centered taskbar, live weather widget, Start menu, Quick Settings, and snap layouts.", font=f_win_desc, fill=TEXT_MUTED)
    y += 48
    
    win_chips = [
        ("Centered Taskbar", (30, 41, 59), (226, 232, 240), (51, 65, 85)),
        ("Start Menu & Search", (30, 41, 59), (226, 232, 240), (51, 65, 85)),
        ("Live Weather Flyout", (30, 41, 59), (226, 232, 240), (51, 65, 85)),
        ("Action Center & Quick Toggles", (30, 41, 59), (226, 232, 240), (51, 65, 85)),
        ("Snap Assist Tiling", (30, 41, 59), (226, 232, 240), (51, 65, 85)),
        ("Segoe UI Typography", (30, 41, 59), (226, 232, 240), (51, 65, 85)),
    ]
    cx = sec_x
    for text, bg, fg, border in win_chips:
        w, _ = draw_pill(canvas, cx, y, text, f_win_chip, bg, fg, padding=(16, 7), border_color=border)
        cx += w + 12
    y += 66
    
    # Card 3: Windows 11 Dark
    print(" - Card 3: Windows 11 Dark...")
    y = render_screenshot_card(
        canvas, MARGIN_X, y,
        screenshot_rel_path="assets/screenshots/Windows11_Dark.png",
        badge_text="DARK PRESET",
        badge_bg=(12, 74, 110), badge_fg=(186, 230, 253), badge_border=(2, 132, 199),
        title_text="Windows 11 Fluent — Dark Mode",
        subtitle_text="Centered taskbar with Start button, live weather feed, dark Bloom wallpaper, and system tray",
        callouts=[
            ("WEATHER", "Real-time temperature, condition icon & quick flyout"),
            ("TASKBAR", "Centered apps, search, Task View & Start button"),
            ("SYSTEM TRAY", "Volume, network, battery status & calendar clock")
        ],
        font_family="segoe"
    )
    y += 60
    
    # Card 4: Windows 11 Light
    print(" - Card 4: Windows 11 Light...")
    y = render_screenshot_card(
        canvas, MARGIN_X, y,
        screenshot_rel_path="assets/screenshots/Windows11_Light.png",
        badge_text="LIGHT PRESET",
        badge_bg=(30, 58, 138), badge_fg=(191, 219, 254), badge_border=(59, 130, 246),
        title_text="Windows 11 Fluent — Light Mode",
        subtitle_text="Daylight acrylic taskbar with centered launcher, light Bloom wallpaper, and clean Segoe UI styling",
        callouts=[
            ("ACRYLIC", "Clean light-mode taskbar with subtle top border"),
            ("NAVIGATION", "Start menu, Explorer shortcut, and Action Center"),
            ("SHORTCUTS", "Super (tap) Start, Super+A Action Center, Super+I Settings")
        ],
        font_family="segoe"
    )
    y += 60
    
    # Card 5: Windows 11 Transparent
    print(" - Card 5: Windows 11 Transparent...")
    y = render_screenshot_card(
        canvas, MARGIN_X, y,
        screenshot_rel_path="assets/screenshots/Windows11_Transparent.png",
        badge_text="TRANSPARENT PRESET",
        badge_bg=(22, 78, 99), badge_fg=(165, 243, 252), badge_border=(8, 145, 178),
        title_text="Windows 11 Fluent — Transparent Taskbar",
        subtitle_text="Zero-border glass taskbar blending directly into wallpaper with floating centered icons",
        callouts=[
            ("BORDERLESS", "Full wallpaper visibility with floating icons"),
            ("MINIMALIST", "Refined, distraction-free modern desktop design"),
            ("CONFIGURABLE", "Toggle via settings or TASKBAR_TRANSPARENT=true")
        ],
        font_family="segoe"
    )
    y += 90
    
    draw.line([(MARGIN_X, y), (WIDTH - MARGIN_X, y)], fill=(40, 52, 78), width=1)
    y += 60
    
    # 5. Architecture & Controls Grid (2x2)
    print("Rendering Architecture & Controls section...")
    draw.text((sec_x, y), "Engineered for Performance, Privacy & Safety", font=f_sec_title, fill=TEXT_TITLE)
    y += 58
    draw.text((sec_x, y), "Designed natively for Omarchy Hyprland with zero configuration conflicts, native Lua dispatchers, and instant keyboard toggling.", font=f_sec_desc, fill=TEXT_MUTED)
    y += 54
    
    grid_cards = [
        (
            "SUPER + ALT + U",
            (88, 28, 135), (216, 180, 254), (168, 85, 247),
            "Instant Camouflage Switcher",
            "Toggle between disguised mode and standard Omarchy instantly. Multi-state status bar tray widget provides left-click control flyout and right-click fast cycling."
        ),
        (
            "NATIVE LUA API",
            (14, 116, 144), (165, 243, 252), (6, 182, 212),
            "Direct Hyprland Dispatchers",
            "Hyprlang hl.dsp.* direct bindings replace shell subprocess forks for sub-millisecond snapping, window cycling, and silky-smooth layout management."
        ),
        (
            "CLEAN ROLLBACK",
            (20, 83, 45), (134, 239, 172), (34, 197, 94),
            "Safe Baseline Protection",
            "Automated baseline backup & restore ensures your original Hyprland and Waybar configs remain pristine. Zero destructive file deletions during mode transitions."
        ),
        (
            "QUICKSHELL + WAYBAR",
            (30, 58, 138), (191, 219, 254), (59, 130, 246),
            "Universal Shell Support",
            "Native Quickshell (Omarchy 4.0+) integration with dynamic C++ QML services, low-latency animations, and automatic fallback to Waybar for legacy installations."
        ),
    ]
    
    gw = (CARD_WIDTH - 36) // 2  # 1122px
    gh = 210
    
    f_card_badge = get_font("sf_semibold", 14)
    f_card_title = get_font("sf_bold", 26)
    f_card_body = get_font("sf_regular", 18)
    
    for idx, (badge, bbg, bfg, bbord, title, body) in enumerate(grid_cards):
        row = idx // 2
        col = idx % 2
        gx = MARGIN_X + col * (gw + 36)
        gy = y + row * (gh + 28)
        
        draw_rounded_rect_aa(canvas, [gx, gy, gx + gw, gy + gh], radius=22, fill=CARD_BG, outline=CARD_BORDER, outline_width=1)
        
        bw, bh = draw_pill(canvas, gx + 28, gy + 24, badge, f_card_badge, bbg, bfg, padding=(14, 5), border_color=bbord)
        
        draw = ImageDraw.Draw(canvas)
        draw.text((gx + 28 + bw + 18, gy + 22), title, font=f_card_title, fill=TEXT_TITLE)
        
        words = body.split()
        lines = []
        cur_line = []
        for word in words:
            test_line = " ".join(cur_line + [word])
            bbox = f_card_body.getbbox(test_line)
            if bbox[2] - bbox[0] > (gw - 56):
                lines.append(" ".join(cur_line))
                cur_line = [word]
            else:
                cur_line.append(word)
        if cur_line:
            lines.append(" ".join(cur_line))
            
        by = gy + 76
        for line in lines:
            draw.text((gx + 28, by), line, font=f_card_body, fill=TEXT_MUTED)
            by += 30
            
    y += (gh * 2) + 28 + 80
    
    # 6. Quick Install & Footer Section
    print("Rendering Quick Install & Footer section...")
    foot_h = 280
    foot_rect = [MARGIN_X, y, MARGIN_X + CARD_WIDTH, y + foot_h]
    draw_rounded_rect_aa(canvas, foot_rect, radius=28, fill=(15, 20, 31), outline=(50, 64, 94), outline_width=1)
    
    ix = MARGIN_X + 48
    iy = y + 32
    
    f_foot_badge = get_font("sf_semibold", 15)
    draw_pill(canvas, ix, iy, "QUICK INSTALLATION VIA OMARCHY CLI", f_foot_badge, (30, 58, 138), (191, 219, 254), padding=(16, 6), border_color=(59, 130, 246))
    iy += 48
    
    f_mono = get_font("mono", 18)
    code_rect = [ix, iy, ix + 1400, iy + 130]
    draw_rounded_rect_aa(canvas, code_rect, radius=14, fill=(8, 11, 17), outline=(34, 46, 68), outline_width=1)
    
    draw = ImageDraw.Draw(canvas)
    draw.text((ix + 24, iy + 26), "$ omarchy plugin add https://github.com/MISTERNEGATIVE21/omarchy-undercover.git --enable --yes", font=f_mono, fill=(147, 197, 253))
    draw.text((ix + 24, iy + 74), "$ omarchy plugin enable omarchy-undercover --section right", font=f_mono, fill=(147, 197, 253))
    
    rx = MARGIN_X + 1520
    ry = y + 54
    with Image.open(logo_path) as l_img:
        l_small = l_img.resize((86, 86), Image.Resampling.LANCZOS)
        canvas.paste(l_small, (rx, ry), l_small)
        
    f_foot_title = get_font("sf_bold", 26)
    f_foot_sub = get_font("sf_regular", 17)
    draw.text((rx + 110, ry + 10), "Omarchy Undercover v6.1.0", font=f_foot_title, fill=TEXT_TITLE)
    draw.text((rx + 110, ry + 48), "Verified Omarchy Plugin • GPL-3.0 • misternegative21", font=f_foot_sub, fill=TEXT_MUTED)
    
    actual_bottom = y + foot_h + 90
    print(f"Total rendered height: {actual_bottom}px. Cropping excess if needed...")
    final_image = canvas.crop((0, 0, WIDTH, actual_bottom))
    
    # Convert to RGB (lossless, solid background, optimizes PNG compression)
    final_rgb = final_image.convert("RGB")
    
    print(f"Saving final preview to {OUTPUT_PATH}...")
    final_rgb.save(OUTPUT_PATH, "PNG", optimize=True)
    print(f"Successfully generated {OUTPUT_PATH}!")
    
    stat = os.stat(OUTPUT_PATH)
    print(f"Output size: {stat.st_size / 1024 / 1024:.2f} MB")

if __name__ == "__main__":
    build_showcase()
