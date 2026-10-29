"""CSS variables page, read from kit/kit.css: the tokens of :root, the area of the desk and the variables only read with a
fallback (var(--x, default)). A variable found in the CSS without a description stops the build."""
import re

# ===== Descriptions =====

VARIABLES = {
    "k-font": ("Font of the interface.", "Police de l'interface."),
    "k-mono": ("Monospace font (terminal, code).", "Police à chasse fixe (terminal, code)."),
    "k-size": ("Base font size.", "Taille de texte de base."),
    "k-bg": ("Background of the windows.", "Fond des fenêtres."),
    "k-bar": ("Background of the title bars.", "Fond des barres de titre."),
    "k-line": ("Borders and separators.", "Bordures et séparateurs."),
    "k-text": ("Text color.", "Couleur du texte."),
    "k-muted": ("Secondary text.", "Texte secondaire."),
    "k-accent": ("Accent color (changed by the settings).", "Couleur d'accent (changée par les réglages)."),
    "k-accent-text": ("Text on the accent color.", "Texte sur la couleur d'accent."),
    "k-hover": ("Background of a hovered item.", "Fond d'un élément survolé."),
    "k-sel": ("Background of a selected item.", "Fond d'un élément sélectionné."),
    "k-input": ("Background of the inputs.", "Fond des champs."),
    "k-page": ("Background of the browser pages.", "Fond des pages du navigateur."),
    "k-term": ("Background of the terminal.", "Fond du terminal."),
    "k-radius": ("Radius of the windows.", "Arrondi des fenêtres."),
    "k-radius-small": ("Radius of the buttons and inputs.", "Arrondi des boutons et champs."),
    "k-shadow": ("Shadow of the windows.", "Ombre des fenêtres."),
    "k-blur": ("Backdrop filter of the windows.", "Filtre d'arrière-plan des fenêtres."),
    "k-overlay": ("Background behind the launcher.", "Fond derrière le lanceur."),
    "k-ease": ("Curve of the motion (Hyprland-like overshoot).", "Courbe des animations (dépassement façon Hyprland)."),
    "k-open": ("Animation of an opening window: `k-popin`, `k-slide`, `k-fade`.", "Animation d'ouverture : `k-popin`, `k-slide`, `k-fade`."),
    "k-open-time": ("Duration of the opening animation.", "Durée de l'animation d'ouverture."),
    "k-gap-in": ("Gap between tiled windows.", "Espace entre fenêtres en mosaïque."),
    "k-gap-out": ("Gap around tiled windows.", "Espace autour des fenêtres en mosaïque."),
    "k-glow-1": ("First color of the animated border (`body.k-glow`).", "Première couleur de la bordure animée (`body.k-glow`)."),
    "k-glow-2": ("Second color of the animated border.", "Seconde couleur de la bordure animée."),
    "k-lock-bg": ("Background of the lock screen.", "Fond du verrouillage."),
    "k-lock-blur": ("Backdrop filter of the lock screen.", "Filtre d'arrière-plan du verrouillage."),
    "k-viz": ("Color of the music visualizer bars.", "Couleur des barres du visualiseur."),
    "k-t-user": ("Terminal: user in the prompt.", "Terminal : utilisateur dans l'invite."),
    "k-t-path": ("Terminal: path in the prompt.", "Terminal : chemin dans l'invite."),
    "k-t-dir": ("Terminal: folders.", "Terminal : dossiers."),
    "k-t-code": ("Terminal: code files.", "Terminal : fichiers de code."),
    "k-t-image": ("Terminal: images.", "Terminal : images."),
    "k-t-audio": ("Terminal: audio files.", "Terminal : fichiers audio."),
    "k-t-archive": ("Terminal: archives.", "Terminal : archives."),
    "k-t-err": ("Terminal: errors.", "Terminal : erreurs."),
    "area-top": ("Space kept free at the top of the desk (top bar).", "Espace libre en haut du bureau (barre du haut)."),
    "area-right": ("Space kept free on the right.", "Espace libre à droite."),
    "area-bottom": ("Space kept free at the bottom (dock, status bar).", "Espace libre en bas (dock, barre d'état)."),
    "area-left": ("Space kept free on the left (side dock).", "Espace libre à gauche (dock latéral)."),
    "scenebar-left": ("Position of the scene bar.", "Position de la barre des situations."),
    "scenebar-top": ("Position of the scene bar (top).", "Position de la barre des situations (haut)."),
    "scenebar-bottom": ("Position of the scene bar (bottom).", "Position de la barre des situations (bas)."),
    "toasts-top": ("Position of the notifications.", "Position des notifications."),
}

# ===== Parsing =====


def fallbacks(css: str) -> dict:
    """var(--name, default) -> {name: default}, the default may hold parentheses"""
    found = {}

    for match in re.finditer(r"var\(--([\w-]+),\s*", css):
        depth, end = 1, match.end()
        while depth:
            depth += {"(": 1, ")": -1}.get(css[end], 0)
            end += 1
        found.setdefault(match.group(1), css[match.end():end - 1].strip())
    return found


def variables(ctx) -> list:
    css = (ctx.site / ".." / ".." / "poc" / "kit" / "kit.css").read_text(encoding="utf-8")
    root = css[css.index(":root {"):]
    root = root[:root.index("\n}")]
    found = re.findall(r"--([\w-]+):\s*([^;]+);", root)
    found += re.findall(r"--(area-[\w-]+):\s*([^;]+);", css)
    found += [item for item in fallbacks(css).items() if item[0] not in dict(found)]
    missing = [name for name, _ in found if name not in VARIABLES]

    if missing:
        raise SystemExit("gen/css_variables.py: undocumented variables in kit/kit.css: %s" % ", ".join(missing))
    return found

# ===== Page =====


def pages(ctx) -> list:
    found = variables(ctx)
    page = {"slug": "css-variables", "section": "reference", "order": 20, "kind": ""}

    for lang in ctx.langs:
        fr = lang == "fr"
        rows = "\n".join("| `--%s` | `%s` | %s |" % (name, value.replace("|", "\\|"), VARIABLES[name][fr]) for name, value in found)
        page[lang] = {
            "title": "Variables CSS" if fr else "CSS variables",
            "summary": ("Les variables --k-* qu'une page de style redéfinit pour habiller le kit, lues dans kit/kit.css."
                        if fr else "The --k-* variables a style page overrides to skin the kit, read from kit/kit.css."),
            "keywords": "css variables tokens thème couleurs --k" if fr else "css variables tokens theme colors --k",
            "md": ("## %s {#skin}\n\n%s\n\n```css \"%s\"\n:root {\n    --k-accent: #39c5bb;\n    --k-bg: rgba(9, 36, 37, 0.92);\n    --k-radius: 8px;\n}\n```\n\n"
                   "## %s {#all}\n\n| %s | %s | %s |\n|---|---|---|\n%s\n") % (
                "Habiller le kit" if fr else "Skinning the kit",
                "Une page de style redéfinit ces variables dans son `:root` ; tout le reste du kit les suit." if fr
                else "A style page overrides these variables in its `:root`; the rest of the kit follows them.",
                "miku.html",
                "Toutes les variables" if fr else "Every variable", "Variable" if fr else "Variable", "Défaut" if fr else "Default",
                "Rôle" if fr else "Role", rows),
        }
    return [page]
