#!/usr/bin/env python3
"""
Omarchy Undercover - Long Showcase Preview Generator
Generates a comprehensive, high-resolution vertical showcase banner (preview.png)
incorporating the signature half-macOS / half-Windows split hero banner on top,
all 5 screenshots, native typography, feature badges, and clear descriptions.
"""

import os
import subprocess
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)
OUTPUT_PATH = os.path.join(ROOT_DIR, "preview.png")
TMP_ASSETS = "/tmp/undercover_preview_assets"

# Canvas configuration
WIDTH = 1920
MARGIN_X = 120
CARD_WIDTH = WIDTH - (MARGIN_X * 2)  # 1680px
SCREENSHOT_WIDTH = 1600
SCREENSHOT_HEIGHT = 900  # 16:9 ratio (1600 * 9 / 16 = 900)

# Colors
BG_TOP = (11, 15, 23)        # #0b0f17
BG_MID = (15, 21, 33)        # #0f1521
BG_BOT = (9, 12, 18)         # #090c12

CARD_BG = (19, 25, 38)       # #131926
CARD_BORDER = (40, 52, 78)   # #28344e
CARD_INNER_BG = (13, 17, 26) # #0d111a
CARD_BORDER_SUBTLE = (34, 44, 66)  # #222c42

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
    subprocess.run(["magick", "-background", "none", "-density", "300", logo_svg, "-resize", "130x130", logo_png], check=True)
    
    # Rasterize apple logo (white)
    apple_svg = os.path.join(ROOT_DIR, "assets/icons/apple-logo.svg")
    apple_png = os.path.join(TMP_ASSETS, "apple.png")
    subprocess.run(["magick", "-background", "none", "-density", "300", apple_svg, "-fill", "#ffffff", "-resize", "48x48", apple_png], check=True)
    
    # Rasterize windows logo
    win_svg = os.path.join(ROOT_DIR, "assets/icons/win11/start.svg")
    win_png = os.path.join(TMP_ASSETS, "win.png")
    subprocess.run(["magick", "-background", "none", "-density", "300", win_svg, "-resize", "48x48", win_png], check=True)

    return logo_png, apple_png, win_png

def draw_pill(draw, x, y, text, font, bg_color, text_color, padding=(16, 7), border_color=None):
    bbox = font.getbbox(text)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    w = tw + (padding[0] * 2)
    h = th + (padding[1] * 2)
    radius = h // 2
    
    draw.rounded_rectangle([x, y, x + w, y + h], radius=radius, fill=bg_color, outline=border_color, width=1)
    
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

def create_rounded_image(im, radius, border_color=(255, 255, 255, 35), border_width=1):
    mask = Image.new("L", im.size, 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, im.size[0] - 1, im.size[1] - 1], radius=radius, fill=255)
    
    output = Image.new("RGBA", im.size, (0, 0, 0, 0))
    im_rgba = im.convert("RGBA")
    output.paste(im_rgba, (0, 0), mask)
    
    if border_color and border_width > 0:
        border_layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
        border_draw = ImageDraw.Draw(border_layer)
        border_draw.rounded_rectangle(
            [0, 0, im.size[0] - 1, im.size[1] - 1],
            radius=radius,
            outline=border_color,
            width=border_width
        )
        output = Image.alpha_composite(output, border_layer)
        
    return output

def create_split_hero_backdrop(hero_w, hero_h):
    """
    Creates the half macOS Sequoia, half Windows 11 Bloom banner
    with the crisp diagonal glass divider line and bottom fade.
    """
    mac_wp = os.path.join(ROOT_DIR, "assets/wallpapers/macOS-Sequoia-Dark.jpg")
    win_wp = os.path.join(ROOT_DIR, "assets/wallpapers/win11_bloom_dark.jpg")
    
    im_mac = Image.open(mac_wp).resize((hero_w, hero_h), Image.Resampling.LANCZOS)
    im_win = Image.open(win_wp).resize((hero_w, hero_h), Image.Resampling.LANCZOS)
    
    mask = Image.new("L", (hero_w, hero_h), 0)
    d_mask = ImageDraw.Draw(mask)
    x_top = 860
    x_bot = 1060
    d_mask.polygon([(0, 0), (x_top, 0), (x_bot, hero_h), (0, hero_h)], fill=255)
    
    hero = im_win.copy()
    hero.paste(im_mac, (0, 0), mask)
    
    # Glass divider line with multi-layer glow
    line_layer = Image.new("RGBA", (hero_w, hero_h), (0, 0, 0, 0))
    d_line = ImageDraw.Draw(line_layer)
    d_line.line([(x_top, 0), (x_bot, hero_h)], fill=(255, 255, 255, 50), width=8)
    d_line.line([(x_top, 0), (x_bot, hero_h)], fill=(255, 255, 255, 130), width=4)
    d_line.line([(x_top, 0), (x_bot, hero_h)], fill=(255, 255, 255, 240), width=2)
    hero = Image.alpha_composite(hero.convert("RGBA"), line_layer)
    
    # Dark vignette overlay to guarantee perfect text legibility
    overlay = Image.new("RGBA", (hero_w, hero_h), (11, 15, 23, 95))
    hero = Image.alpha_composite(hero, overlay)
    
    # Bottom fade into BG_TOP (11, 15, 23)
    fade_start = hero_h - 300
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
    draw = ImageDraw.Draw(canvas)
    
    bold_key = f"{font_family}_bold"
    reg_key = f"{font_family}_regular"
    semi_key = f"{font_family}_semibold"
    
    f_badge = get_font(semi_key, 13)
    f_title = get_font(bold_key, 28)
    f_sub = get_font(reg_key, 17)
    f_callout_tag = get_font(bold_key, 11)
    f_callout_desc = get_font(semi_key, 13)
    
    card_h = 1130
    card_rect = [card_x, card_y, card_x + CARD_WIDTH, card_y + card_h]
    
    # Draw card background & border
    draw.rounded_rectangle(card_rect, radius=24, fill=CARD_BG, outline=CARD_BORDER, width=1)
    
    # Header inside card
    inner_x = card_x + 40
    curr_y = card_y + 30
    
    # Badge
    bw, bh = draw_pill(draw, inner_x, curr_y, badge_text, f_badge, badge_bg, badge_fg, padding=(14, 5), border_color=badge_border)
    
    # Title
    title_x = inner_x + bw + 16
    draw.text((title_x, curr_y + 1), title_text, font=f_title, fill=TEXT_TITLE)
    
    # Subtitle
    curr_y += 38
    draw.text((inner_x, curr_y), subtitle_text, font=f_sub, fill=TEXT_MUTED)
    
    # Load and render screenshot
    curr_y += 34
    shot_path = os.path.join(ROOT_DIR, screenshot_rel_path)
    with Image.open(shot_path) as shot_raw:
        shot_resized = shot_raw.resize((SCREENSHOT_WIDTH, SCREENSHOT_HEIGHT), Image.Resampling.LANCZOS)
        shot_rounded = create_rounded_image(shot_resized, radius=14, border_color=(255, 255, 255, 40), border_width=1)
        canvas.paste(shot_rounded, (inner_x, curr_y), shot_rounded)
        
    curr_y += SCREENSHOT_HEIGHT + 24
    
    # Callout boxes row (3 boxes side by side)
    num_callouts = len(callouts)
    gap = 20
    box_w = (SCREENSHOT_WIDTH - (gap * (num_callouts - 1))) // num_callouts
    box_h = 46
    
    for i, (tag_label, tag_desc) in enumerate(callouts):
        bx = inner_x + i * (box_w + gap)
        draw.rounded_rectangle([bx, curr_y, bx + box_w, curr_y + box_h], radius=10, fill=CARD_INNER_BG, outline=CARD_BORDER_SUBTLE, width=1)
        
        # Mini pill tag inside box
        ptw, pth = draw_pill(draw, bx + 12, curr_y + 10, tag_label, f_callout_tag, badge_bg, badge_fg, padding=(8, 4), border_color=badge_border)
        
        # Text next to tag
        draw.text((bx + 18 + ptw, curr_y + 15), tag_desc, font=f_callout_desc, fill=TEXT_BODY)
        
    return card_y + card_h

def build_showcase():
    print("Preparing vector assets...")
    logo_path, apple_path, win_path = prepare_raster_assets()
    
    TOTAL_HEIGHT = 8600
    print(f"Creating canvas {WIDTH}x{TOTAL_HEIGHT}...")
    canvas = Image.new("RGBA", (WIDTH, TOTAL_HEIGHT), BG_TOP)
    draw = ImageDraw.Draw(canvas)
    
    # 1. Background vertical gradient
    print("Drawing background gradient and glows...")
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
    HERO_HEIGHT = 920
    hero_split = create_split_hero_backdrop(WIDTH, HERO_HEIGHT)
    canvas.paste(hero_split, (0, 0), hero_split)
    
    # Re-obtain draw handle on canvas
    draw = ImageDraw.Draw(canvas)
    
    f_hero_title = get_font("sf_bold", 62)
    f_hero_sub = get_font("sf_medium", 28)
    f_hero_p = get_font("sf_regular", 20)
    f_badge = get_font("sf_semibold", 14)
    
    y = 75
    # Centered Logo
    with Image.open(logo_path) as logo_img:
        lw, lh = logo_img.size
        canvas.paste(logo_img, ((WIDTH - lw) // 2, y), logo_img)
    y += 150
    
    # Title
    draw_centered_text(draw, y, "OMARCHY UNDERCOVER", f_hero_title, TEXT_WHITE)
    y += 76
    
    # Subtitle
    draw_centered_text(draw, y, "Desktop Camouflage & Transformation Suite for Omarchy Hyprland", f_hero_sub, (224, 231, 255))
    y += 56
    
    # Hero Badges Row (including the requested Verified Omarchy Plugin badge!)
    hero_badges = [
        ("✓ Verified Omarchy Plugin", (6, 78, 59), (110, 231, 183), (16, 185, 129)),
        ("v5.7.4 Release", (30, 58, 138), (147, 197, 253), (59, 130, 246)),
        ("Hyprland Wayland", (19, 78, 74), (94, 234, 212), (20, 184, 166)),
        ("Quickshell 4.0+ & Waybar", (88, 28, 135), (216, 180, 254), (168, 85, 247)),
        ("Zero Config Conflicts", (67, 56, 202), (199, 210, 254), (99, 102, 241)),
        ("Safe State Rollback", (20, 83, 45), (134, 239, 172), (34, 197, 94))
    ]
    total_badge_w = 0
    badge_widths = []
    for text, bg, fg, border in hero_badges:
        bbox = f_badge.getbbox(text)
        w = (bbox[2] - bbox[0]) + 32
        badge_widths.append(w)
        total_badge_w += w
    total_badge_w += 14 * (len(hero_badges) - 1)
    
    bx = (WIDTH - total_badge_w) // 2
    for i, (text, bg, fg, border) in enumerate(hero_badges):
        draw_pill(draw, bx, y, text, f_badge, bg, fg, padding=(16, 7), border_color=border)
        bx += badge_widths[i] + 14
    y += 64
    
    # Description lines
    draw_centered_text(draw, y, "Instantly switch your Omarchy Hyprland desktop into a native Apple macOS Sequoia or Windows 11 Fluent environment.", f_hero_p, (241, 245, 249))
    y += 32
    draw_centered_text(draw, y, "Engineered for privacy, presentation, and seamless workflow disguise with authentic typography, physics, and controls.", f_hero_p, (203, 213, 225))
    y += 100
    
    # Section separator
    draw.line([(MARGIN_X, y), (WIDTH - MARGIN_X, y)], fill=(35, 45, 68), width=1)
    y += 50
    
    # 3. Apple macOS Sequoia Section
    print("Rendering Apple macOS Sequoia section...")
    f_sec_title = get_font("sf_bold", 38)
    f_sec_desc = get_font("sf_regular", 19)
    f_chip = get_font("sf_semibold", 14)
    
    sec_x = MARGIN_X
    with Image.open(apple_path) as a_img:
        canvas.paste(a_img, (sec_x, y + 2), a_img)
    draw.text((sec_x + 58, y), "Apple macOS Sequoia Mode", font=f_sec_title, fill=TEXT_TITLE)
    y += 50
    draw.text((sec_x, y), "Authentic Cupertino desktop experience featuring frosted menu bar, dynamic spring-physics dock, Spotlight search, and Control Center.", font=f_sec_desc, fill=TEXT_MUTED)
    y += 42
    
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
        w, _ = draw_pill(draw, cx, y, text, f_chip, bg, fg, padding=(14, 6), border_color=border)
        cx += w + 10
    y += 56
    
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
    y += 50
    
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
    y += 80
    
    draw.line([(MARGIN_X, y), (WIDTH - MARGIN_X, y)], fill=(35, 45, 68), width=1)
    y += 50
    
    # 4. Windows 11 Fluent Section
    print("Rendering Windows 11 Fluent section...")
    f_win_title = get_font("segoe_bold", 38)
    f_win_desc = get_font("segoe_regular", 19)
    f_win_chip = get_font("segoe_bold", 14)
    
    with Image.open(win_path) as w_img:
        canvas.paste(w_img, (sec_x, y + 2), w_img)
    draw.text((sec_x + 58, y), "Windows 11 Fluent Mode", font=f_win_title, fill=TEXT_TITLE)
    y += 50
    draw.text((sec_x, y), "Authentic Redmond desktop experience featuring centered taskbar, live weather widget, Start menu, Quick Settings, and snap layouts.", font=f_win_desc, fill=TEXT_MUTED)
    y += 42
    
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
        w, _ = draw_pill(draw, cx, y, text, f_win_chip, bg, fg, padding=(14, 6), border_color=border)
        cx += w + 10
    y += 56
    
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
    y += 50
    
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
    y += 50
    
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
    y += 80
    
    draw.line([(MARGIN_X, y), (WIDTH - MARGIN_X, y)], fill=(35, 45, 68), width=1)
    y += 50
    
    # 5. Architecture & Controls Grid (2x2)
    print("Rendering Architecture & Controls section...")
    draw.text((sec_x, y), "Engineered for Performance, Privacy & Safety", font=f_sec_title, fill=TEXT_TITLE)
    y += 50
    draw.text((sec_x, y), "Designed natively for Omarchy Hyprland with zero configuration conflicts and instant keyboard toggling.", font=f_sec_desc, fill=TEXT_MUTED)
    y += 46
    
    grid_cards = [
        (
            "SUPER + ALT + U",
            (88, 28, 135), (216, 180, 254), (168, 85, 247),
            "Instant Camouflage Switcher",
            "Toggle between disguised mode and standard Omarchy instantly. Multi-state status bar tray widget provides left-click control flyout and right-click fast cycling."
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
        (
            "PRECISION PHYSICS",
            (120, 53, 15), (254, 243, 199), (217, 119, 6),
            "Platform-Authentic Details",
            "Spring-physics magnification for macOS dock, cubic-bezier curves for Windows flyouts, dedicated window rules, and authentic SF Pro and Segoe UI typography."
        ),
    ]
    
    gw = (CARD_WIDTH - 30) // 2  # 825px
    gh = 180
    
    f_card_badge = get_font("sf_semibold", 12)
    f_card_title = get_font("sf_bold", 22)
    f_card_body = get_font("sf_regular", 16)
    
    for idx, (badge, bbg, bfg, bbord, title, body) in enumerate(grid_cards):
        row = idx // 2
        col = idx % 2
        gx = MARGIN_X + col * (gw + 30)
        gy = y + row * (gh + 24)
        
        draw.rounded_rectangle([gx, gy, gx + gw, gy + gh], radius=18, fill=CARD_BG, outline=CARD_BORDER, width=1)
        
        bw, bh = draw_pill(draw, gx + 24, gy + 20, badge, f_card_badge, bbg, bfg, padding=(12, 4), border_color=bbord)
        
        draw.text((gx + 24 + bw + 14, gy + 19), title, font=f_card_title, fill=TEXT_TITLE)
        
        words = body.split()
        lines = []
        cur_line = []
        for word in words:
            test_line = " ".join(cur_line + [word])
            bbox = f_card_body.getbbox(test_line)
            if bbox[2] - bbox[0] > (gw - 48):
                lines.append(" ".join(cur_line))
                cur_line = [word]
            else:
                cur_line.append(word)
        if cur_line:
            lines.append(" ".join(cur_line))
            
        by = gy + 64
        for line in lines:
            draw.text((gx + 24, by), line, font=f_card_body, fill=TEXT_MUTED)
            by += 26
            
    y += (gh * 2) + 24 + 70
    
    # 6. Quick Install & Footer Section
    print("Rendering Quick Install & Footer section...")
    foot_h = 240
    foot_rect = [MARGIN_X, y, MARGIN_X + CARD_WIDTH, y + foot_h]
    draw.rounded_rectangle(foot_rect, radius=24, fill=(15, 20, 31), outline=(45, 58, 86), width=1)
    
    ix = MARGIN_X + 40
    iy = y + 28
    
    f_foot_badge = get_font("sf_semibold", 13)
    draw_pill(draw, ix, iy, "QUICK INSTALLATION VIA OMARCHY CLI", f_foot_badge, (30, 58, 138), (191, 219, 254), padding=(14, 5), border_color=(59, 130, 246))
    iy += 42
    
    f_mono = get_font("mono", 16)
    code_rect = [ix, iy, ix + 1050, iy + 110]
    draw.rounded_rectangle(code_rect, radius=12, fill=(8, 11, 17), outline=(30, 41, 59), width=1)
    
    draw.text((ix + 20, iy + 22), "$ omarchy plugin add https://github.com/MISTERNEGATIVE21/omarchy-undercover.git --enable --yes", font=f_mono, fill=(147, 197, 253))
    draw.text((ix + 20, iy + 62), "$ omarchy plugin enable omarchy-undercover --section right", font=f_mono, fill=(147, 197, 253))
    
    rx = MARGIN_X + 1140
    ry = y + 40
    with Image.open(logo_path) as l_img:
        l_small = l_img.resize((70, 70), Image.Resampling.LANCZOS)
        canvas.paste(l_small, (rx, ry), l_small)
        
    f_foot_title = get_font("sf_bold", 22)
    f_foot_sub = get_font("sf_regular", 15)
    draw.text((rx + 90, ry + 8), "Omarchy Undercover v5.7.4", font=f_foot_title, fill=TEXT_TITLE)
    draw.text((rx + 90, ry + 40), "Verified Omarchy Plugin • GPL-3.0 • misternegative21", font=f_foot_sub, fill=TEXT_MUTED)
    
    actual_bottom = y + foot_h + 80
    print(f"Total rendered height: {actual_bottom}px. Cropping excess if needed...")
    final_image = canvas.crop((0, 0, WIDTH, actual_bottom))
    
    print(f"Saving final preview to {OUTPUT_PATH}...")
    final_image.save(OUTPUT_PATH, "PNG", optimize=True)
    print(f"Successfully generated {OUTPUT_PATH}!")
    
    stat = os.stat(OUTPUT_PATH)
    print(f"Output size: {stat.st_size / 1024 / 1024:.2f} MB")

if __name__ == "__main__":
    build_showcase()
