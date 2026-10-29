"""Terminal commands page, read from the code: the COMMANDS table of kit/kit.js and the terminal.commands of every style page.
A command found in the code without a description stops the build."""
import re

# ===== Descriptions =====

KIT = {
    "help": ("Lists every command.", "Liste toutes les commandes."),
    "ls": ("Lists a folder (`-l` for details).", "Liste un dossier (`-l` pour le détail)."),
    "cd": ("Changes the folder (`~` by default).", "Change de dossier (`~` par défaut)."),
    "pwd": ("Prints the current folder.", "Affiche le dossier courant."),
    "cat": ("Prints a file.", "Affiche un fichier."),
    "tree": ("Tree of a folder (3 levels).", "Arbre d'un dossier (3 niveaux)."),
    "echo": ("Prints its arguments.", "Affiche ses arguments."),
    "clear": ("Clears the screen (also <kbd>Ctrl</kbd>+<kbd>L</kbd>).", "Efface l'écran (aussi <kbd>Ctrl</kbd>+<kbd>L</kbd>)."),
    "whoami": ("Prints the user.", "Affiche l'utilisateur."),
    "hostname": ("Prints the host.", "Affiche la machine."),
    "date": ("Prints the date.", "Affiche la date."),
    "uptime": ("Time since the page was opened.", "Temps depuis l'ouverture de la page."),
    "history": ("Previous commands.", "Commandes précédentes."),
    "neofetch": ("Logo and system information of the style.", "Logo et infos système du style."),
    "open": ("Opens an app (`files`, `browser`, `terminal`, `music`, `settings`) or a file.", "Ouvre une appli (`files`, `browser`, `terminal`, `music`, `settings`) ou un fichier."),
    "play": ("Plays the music (`play 2` = second track).", "Lance la musique (`play 2` = deuxième morceau)."),
    "pause": ("Stops the music.", "Arrête la musique."),
    "next": ("Next track.", "Morceau suivant."),
    "mkdir": ("Creates folders (seen by Files).", "Crée des dossiers (visibles dans Files)."),
    "touch": ("Creates empty files.", "Crée des fichiers vides."),
    "rm": ("Removes files or folders.", "Supprime des fichiers ou dossiers."),
    "notify": ("Sends a notification.", "Envoie une notification."),
    "lock": ("Locks the screen.", "Verrouille l'écran."),
    "scene": ("Switches the scene (`scene browser`).", "Change de situation (`scene browser`)."),
    "sudo": ("Refused, as it should be.", "Refusé, comme il se doit."),
    "exit": ("Closes the terminal.", "Ferme le terminal."),
}
STYLES = {
    "dev.html": {
        "si": ("Steps one instruction of the debugger.", "Avance d'une instruction dans le débogueur."),
        "c": ("Continues to the next breakpoint.", "Continue jusqu'au point d'arrêt suivant."),
        "reset": ("Restarts the program.", "Relance le programme."),
        "regs": ("Prints the registers.", "Affiche les registres."),
        "b": ("Adds a breakpoint (`b 0x401152`).", "Ajoute un point d'arrêt (`b 0x401152`)."),
        "xxd": ("Hex dump of a text file.", "Dump hexadécimal d'un fichier texte."),
        "base": ("A number in dec / hex / oct / bin.", "Un nombre en déc / hex / oct / bin."),
    },
    "jpop.html": {
        "usseewa": ("The うっせぇわ stamp.", "Le tampon うっせぇわ."),
        "wish": ("A wish: a blue rose blooms.", "Un vœu : une rose bleue éclot."),
        "timeline": ("Ado's timeline.", "La frise d'Ado."),
        "bloom": ("Every rose blooms.", "Toutes les roses éclosent."),
        "adomin": ("Who the Adomin are.", "Qui sont les Adomin."),
        "tv": ("Opens Ado TV, plays a title (`tv 唱`).", "Ouvre Ado TV, joue un titre (`tv 唱`)."),
    },
    "tty.html": {
        "git": ("`git status` / `log` / `branch` of a fake repository.", "`git status` / `log` / `branch` d'un faux dépôt."),
        "cmake": ("A build with an animated progress bar.", "Une compilation avec barre de progression animée."),
        "make": ("Same as `cmake`.", "Comme `cmake`."),
        "nvim": ("Opens a file in the viewer.", "Ouvre un fichier dans la visionneuse."),
        "htop": ("Focuses the btop pane.", "Donne le focus au volet btop."),
        "btop": ("Focuses the btop pane.", "Donne le focus au volet btop."),
        "tmux": ("The tmux keys of the page.", "Les touches tmux de la page."),
    },
    "miku.html": {
        "beam": ("MIKU MIKU BEAM (`beam 0.5` = half power).", "MIKU MIKU BEAM (`beam 0.5` = demi-puissance)."),
        "sing": ("She sings the melody of the editor.", "Elle chante la mélodie de l'éditeur."),
        "negi": ("A leek.", "Un poireau."),
        "39": ("Thank you.", "Merci."),
    },
    "photographer.html": {
        "exif": ("Settings of a photo (`exif 3`).", "Réglages d'une photo (`exif 3`)."),
        "slideshow": ("Starts / stops the slideshow.", "Lance / arrête le diaporama."),
        "show": ("Shows a photo on the wall (`show 5`).", "Affiche une photo sur le mur (`show 5`)."),
    },
}
NAMES = {"system.html": "System", "dev.html": "Dev / low level", "jpop.html": "Ado / blue rose", "tty.html": "Terminal / better-tty",
         "miku.html": "Miku", "photographer.html": "Photographer"}

# ===== Parsing =====


def kit_commands(root) -> list:
    code = (root / "kit" / "kit.js").read_text(encoding="utf-8")
    block = code[code.index("    const COMMANDS = {"):]
    return re.findall(r"^        (\w+)(?=[:,])", block[:block.index("\n    };")], flags=re.M)


def style_commands(root, page: str) -> list:
    """keys at the first level of the terminal.commands object of a page"""
    code = (root / page).read_text(encoding="utf-8")
    names, depth = [], 0

    if "                commands: {" not in code:
        return []
    for line in code[code.index("                commands: {") + len("                commands: {"):].split("\n"):
        match = re.match(r"\s*(\w+):", line)
        if depth == 0 and match:
            names.append(match.group(1))
        depth += line.count("{") - line.count("}")
        if depth < 0:
            break
    return names


def check(found, known: dict, where: str) -> None:
    missing = [name for name in found if name not in known]
    if missing:
        raise SystemExit("gen/commands.py: undocumented commands in %s: %s" % (where, ", ".join(missing)))

# ===== Page =====


def pages(ctx) -> list:
    root = ctx.site / ".." / ".." / "poc"
    base = kit_commands(root)
    page = {"slug": "terminal-commands", "section": "reference", "order": 30, "kind": ""}

    check(base, KIT, "kit/kit.js")
    for name in STYLES:
        check(style_commands(root, name), STYLES[name], name)
    for lang in ctx.langs:
        fr = lang == "fr"
        md = "## %s {#kit}\n\n%s\n\n| %s | %s |\n|---|---|\n%s\n" % (
            "Toutes les pages" if fr else "Every page",
            "Ces commandes existent dans le terminal de chaque style." if fr else "These commands exist in the terminal of every style.",
            "Commande" if fr else "Command", "Effet" if fr else "Effect",
            "\n".join("| `%s` | %s |" % (name, KIT[name][fr]) for name in base))
        for name in STYLES:
            found = style_commands(root, name)
            if found:
                md += "\n## %s {#%s}\n\n| %s | %s |\n|---|---|\n%s\n" % (
                    NAMES[name], name.split(".")[0], "Commande" if fr else "Command", "Effet" if fr else "Effect",
                    "\n".join("| `%s` | %s |" % (command, STYLES[name][command][fr]) for command in found))
        page[lang] = {
            "title": "Commandes du terminal" if fr else "Terminal commands",
            "summary": ("Les commandes du terminal du kit et celles de chaque style, lues dans le code."
                        if fr else "The commands of the kit terminal and the ones of every style, read from the code."),
            "keywords": "terminal commandes shell help ls cd" if fr else "terminal commands shell help ls cd",
            "md": md,
        }
    return [page]


def search_entries(ctx) -> list:
    root = ctx.site / ".." / ".." / "poc"
    entries = []

    for lang in ctx.langs:
        fr = lang == "fr"
        for name in kit_commands(root):
            entries.append({"k": "cmd", "l": lang, "t": name, "d": KIT[name][fr], "u": "terminal-commands.html#kit", "x": ""})
        for page, known in STYLES.items():
            for name in style_commands(root, page):
                entries.append({"k": "cmd", "l": lang, "t": name, "d": known[name][fr], "u": "terminal-commands.html#%s" % page.split(".")[0], "x": ""})
    return entries
