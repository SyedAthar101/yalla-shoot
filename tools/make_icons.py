"""Generate Yalla Shoot launcher icons in CI (text-only repo push).

The repo snapshot cannot carry binary PNGs, so the GitHub Actions
workflow runs this script before `flutter build apk`. It downloads
the site's own favicon from yallah.media, recolours it white, and
composites it on the site red (#931800) rounded square with
"YALLA SHOOT" text, at all Android mipmap sizes. If the download
fails, it falls back to a plain red icon with a white football.
"""
import os
import urllib.request

BASE = os.path.join(os.path.dirname(__file__), "..", "android", "app",
                    "src", "main", "res")
FAVICON = ("https://yallah.media/wp-content/uploads/2026/11/"
           "cropped-yshoot_img_37862980214-270x270.png")
SIZES = {"mipmap-mdpi": 48, "mipmap-hdpi": 72, "mipmap-xhdpi": 96,
         "mipmap-xxhdpi": 144, "mipmap-xxxhdpi": 192}

def make_icon(size, logo_path=None):
    from PIL import Image, ImageDraw, ImageFont
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = int(size * 0.12)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r,
                        fill=(147, 24, 0, 255))
    if logo_path and os.path.exists(logo_path):
        try:
            logo = Image.open(logo_path).convert("RGBA")
            # Recolour the dark silhouette to white: use alpha as mask.
            white = Image.new("RGBA", logo.size, (255, 255, 255, 255))
            logo.putalpha(logo.split()[-1])
            white.putalpha(logo.split()[-1])
            box = int(size * 0.52)
            white = white.resize((box, box), Image.LANCZOS)
            img.alpha_composite(white, ((size - box) // 2, int(size * 0.08)))
        except Exception as e:
            print("logo composite failed:", e)
    else:
        cx, cy, br = size // 2, int(size * 0.30), int(size * 0.18)
        d.ellipse([cx - br, cy - br, cx + br, cy + br],
                  fill=(255, 255, 255, 255))
        d.ellipse([cx - br // 3, cy - br // 3, cx + br // 3, cy + br // 3],
                  fill=(147, 24, 0, 255))
    try:
        f1 = ImageFont.truetype("DejaVuSans-Bold.ttf", int(size * 0.13))
        f2 = ImageFont.truetype("DejaVuSans-Bold.ttf", int(size * 0.085))
    except Exception:
        f1 = ImageFont.load_default()
        f2 = f1
    for txt, f, y in [("YALLA", f1, int(size * 0.62)),
                      ("SHOOT", f2, int(size * 0.76))]:
        bb = d.textbbox((0, 0), txt, font=f)
        d.text(((size - (bb[2] - bb[0])) // 2, y), txt, font=f,
               fill=(255, 255, 255, 255))
    return img

def main():
    logo_path = "/tmp/yalla-favicon.png"
    try:
        req = urllib.request.Request(FAVICON, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=20) as r, open(logo_path, "wb") as f:
            f.write(r.read())
        print("favicon downloaded")
    except Exception as e:
        print("favicon download failed, using fallback:", e)
        logo_path = None
    for folder, size in SIZES.items():
        outdir = os.path.join(BASE, folder)
        os.makedirs(outdir, exist_ok=True)
        icon = make_icon(size, logo_path)
        icon.save(os.path.join(outdir, "ic_launcher.png"))
        print("wrote", folder, size)
    # Also generate the Flutter AppBar logo asset (512px, same artwork).
    # The repo cannot carry the binary PNG, so CI builds it here before
    # `flutter build apk` (pubspec registers assets/logo.png).
    asset_dir = os.path.join(os.path.dirname(__file__), "..", "assets")
    os.makedirs(asset_dir, exist_ok=True)
    make_icon(512, logo_path).save(os.path.join(asset_dir, "logo.png"))
    print("wrote assets/logo.png 512")

if __name__ == "__main__":
    main()
