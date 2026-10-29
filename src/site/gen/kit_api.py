"""Kit API page, read from kit/kit.js: the options of Kit.init (every config.<key> the kit reads), the public functions
(the object returned by the kit) and the events (every emit). A name found in the code without a description stops the build."""
import re

# ===== Descriptions =====

OPTIONS = {
    "name": ("Name of the style (settings, neofetch).", "Nom du style (réglages, neofetch)."),
    "user": ("User name (prompt, lock screen, home folder).", "Nom d'utilisateur (invite, verrouillage, dossier personnel)."),
    "host": ("Host name (prompt, neofetch, settings).", "Nom de machine (invite, neofetch, réglages)."),
    "layout": ("`float` (draggable windows) or `tile` (tiling).", "`float` (fenêtres libres) ou `tile` (mosaïque)."),
    "desktop": ("Ids of the windows opened by the desktop scene.", "Ids des fenêtres ouvertes par la situation bureau."),
    "scenes": ("Windows of the other scenes: `{music: [\"music\", \"lyrics\"]}`.", "Fenêtres des autres situations : `{music: [\"music\", \"lyrics\"]}`."),
    "accents": ("Accent colors offered by the settings.", "Couleurs d'accent proposées par les réglages."),
    "wallpapers": ("`[{label, cls}]`: body classes offered as wallpapers.", "`[{label, cls}]` : classes du body proposées comme fonds."),
    "lock": ("Lock screen: `html` (whole content), `decor`, `avatar`, `placeholder`, `hint`, `welcome`.", "Verrouillage : `html` (tout le contenu), `decor`, `avatar`, `placeholder`, `hint`, `welcome`."),
    "browser": ("Browser pages: `engine`, `hero`, `tiles`, `news`, `video`, `wiki`.", "Pages du navigateur : `engine`, `hero`, `tiles`, `news`, `video`, `wiki`."),
    "files": ("Extra files: `{\"~/path\": {kind, content / src, fallback, size}}`.", "Fichiers en plus : `{\"~/chemin\": {kind, content / src, fallback, size}}`."),
    "context": ("Extra items of the right-click menu: `[{label, run}]`.", "Entrées en plus du menu clic droit : `[{label, run}]`."),
    "toggles": ("Extra switches of the settings: `[{label, key, on, cls, run}]`.", "Interrupteurs en plus des réglages : `[{label, key, on, cls, run}]`."),
    "icons": ("Icons by file kind or app (`dir`, `audio`, `terminal`...).", "Icônes par type de fichier ou appli (`dir`, `audio`, `terminal`...)."),
    "positions": ("Initial position of an app window: `{music: {left, top}}`.", "Position initiale d'une fenêtre d'appli : `{music: {left, top}}`."),
    "tracks": ("Tracks of the synth (see the synth page).", "Morceaux du synthé (voir la page du synthé)."),
    "terminal": ("`prompt`, `title`, `motd`, `startup`, `logo`, `palette`, `commands`.", "`prompt`, `title`, `motd`, `startup`, `logo`, `palette`, `commands`."),
    "chrome": ("Labels of the window buttons: `{min, max, close}`.", "Libellés des boutons de fenêtre : `{min, max, close}`."),
    "task_label": ("`(win, index, title) => html`: label of a task in the task list.", "`(win, index, title) => html` : libellé d'une tâche de la liste."),
}
FUNCTIONS = {
    "init": ("`Kit.init(options)`: builds the desktop and opens the start scene.", "`Kit.init(options)` : construit le bureau et ouvre la situation de départ."),
    "on": ("`Kit.on(event, callback)`: listens to an event.", "`Kit.on(event, callback)` : écoute un événement."),
    "emit": ("`Kit.emit(event, data)`: sends an event.", "`Kit.emit(event, data)` : envoie un événement."),
    "open": ("`Kit.open(id)`: opens (or creates) a window and focuses it.", "`Kit.open(id)` : ouvre (ou crée) une fenêtre et lui donne le focus."),
    "close": ("`Kit.close(id)`: closes a window.", "`Kit.close(id)` : ferme une fenêtre."),
    "toggle": ("`Kit.toggle(id)`: dock behavior (open, focus or minimize).", "`Kit.toggle(id)` : comportement du dock (ouvrir, focus ou réduire)."),
    "spawn": ("`Kit.spawn(\"terminal\")`: a new instance of an app.", "`Kit.spawn(\"terminal\")` : une nouvelle instance d'une appli."),
    "maximize": ("`Kit.maximize(id)`: toggles maximized (zoom in tiling).", "`Kit.maximize(id)` : bascule l'agrandissement (zoom en mosaïque)."),
    "active": ("`Kit.active()`: id of the focused window.", "`Kit.active()` : id de la fenêtre active."),
    "set_layout": ("`Kit.set_layout(\"float\" | \"tile\")`: changes the layout live.", "`Kit.set_layout(\"float\" | \"tile\")` : change la disposition en direct."),
    "scene": ("`Kit.scene(name)`: switches the scene.", "`Kit.scene(name)` : change de situation."),
    "notify": ("`Kit.notify(title, body, icon)`: a notification.", "`Kit.notify(title, body, icon)` : une notification."),
    "view": ("`Kit.view(path)`: opens a file in the viewer.", "`Kit.view(path)` : ouvre un fichier dans la visionneuse."),
    "play": ("`Kit.play(index)`: plays a track.", "`Kit.play(index)` : joue un morceau."),
    "pause": ("`Kit.pause()`: stops the music.", "`Kit.pause()` : arrête la musique."),
    "next": ("`Kit.next(delta)`: next / previous track.", "`Kit.next(delta)` : morceau suivant / précédent."),
    "note": ("`Kit.note(midi, length, wave, gain)`: plays one note now.", "`Kit.note(midi, length, wave, gain)` : joue une note tout de suite."),
    "level": ("`Kit.level()`: loudness of the music, 0 to 1.", "`Kit.level()` : volume perçu de la musique, de 0 à 1."),
    "track": ("`Kit.track()`: the current track.", "`Kit.track()` : le morceau courant."),
    "element": ("`Kit.element(html)`: builds an element from HTML.", "`Kit.element(html)` : construit un élément depuis du HTML."),
    "esc": ("`Kit.esc(text)`: escapes text for HTML.", "`Kit.esc(text)` : échappe un texte pour le HTML."),
    "audio": ("State of the synth (`playing`, `index`, `step`...).", "État du synthé (`playing`, `index`, `step`...)."),
    "state": ("`{scene, dnd}`: current scene, do not disturb.", "`{scene, dnd}` : situation courante, ne pas déranger."),
    "windows": ("`Map` of every window by id.", "`Map` de toutes les fenêtres par id."),
    "set_wallpaper": ("`Kit.set_wallpaper(index)`: applies a wallpaper.", "`Kit.set_wallpaper(index)` : applique un fond."),
    "fs.add": ("`Kit.fs.add(path, node)`: adds a file or a folder.", "`Kit.fs.add(path, node)` : ajoute un fichier ou un dossier."),
    "fs.get": ("`Kit.fs.get(path)`: a node of the file system.", "`Kit.fs.get(path)` : un nœud du système de fichiers."),
    "fs.list": ("`Kit.fs.list(path)`: the entries of a folder.", "`Kit.fs.list(path)` : les entrées d'un dossier."),
    "fs.resolve": ("`Kit.fs.resolve(cwd, path)`: absolute path (`~`, `..`).", "`Kit.fs.resolve(cwd, path)` : chemin absolu (`~`, `..`)."),
    "fs.home": ("`Kit.fs.home()`: the home folder.", "`Kit.fs.home()` : le dossier personnel."),
}
EVENTS = {
    "step": ("Every 16th note of the music: `{step, index, length, note, hit, track}`.", "À chaque double croche : `{step, index, length, note, hit, track}`."),
    "beat": ("Every kick of the drums.", "À chaque grosse caisse."),
    "music": ("Play / pause / track change: `{playing, index, track}`.", "Lecture / pause / changement : `{playing, index, track}`."),
    "scene": ("The scene changed: its name.", "La situation a changé : son nom."),
    "window": ("A window changed state: `{id, state}`.", "Une fenêtre a changé d'état : `{id, state}`."),
    "lock": ("The lock screen is shown (`true`) or left (`false`).", "Le verrouillage s'affiche (`true`) ou se ferme (`false`)."),
    "fs": ("The file system changed (terminal `mkdir`, `touch`, `rm`).", "Le système de fichiers a changé (`mkdir`, `touch`, `rm`)."),
    "accent": ("The accent color changed: the color.", "La couleur d'accent a changé : la couleur."),
    "wallpaper": ("The wallpaper changed: its index.", "Le fond a changé : son index."),
    "layout": ("The layout changed: `float` or `tile`.", "La disposition a changé : `float` ou `tile`."),
}

# ===== Parsing =====


def read_kit(ctx) -> str:
    return (ctx.site / ".." / ".." / "poc" / "kit" / "kit.js").read_text(encoding="utf-8")


def defaults(code: str) -> dict:
    block = code[code.index("        config = {"):code.index("            ...options,")]
    values = dict(re.findall(r'(\w+): ("[^"]*"|\[\]|\{\}|\w+)', block))
    values["terminal"] = "{commands: {}}"
    values["chrome"] = '{min: "–", max: "□", close: "✕"}'
    return values


def functions(code: str) -> list:
    block = code[code.rindex("    return {"):]
    block = block[:block.index("    };")]
    names = [name for name in re.findall(r"\b(\w+)\b(?=[,\n])", block.split("fs:")[0])]
    names += ["fs.%s" % name for name in re.findall(r"(\w+)(?=: |})", block.split("fs:")[1])]
    return [name for name in names if name != "return"]


def check(found, known: dict, what: str) -> None:
    missing = [name for name in found if name not in known]
    if missing:
        raise SystemExit("gen/kit_api.py: undocumented %s in kit/kit.js: %s" % (what, ", ".join(missing)))


# ===== Page =====


def pages(ctx) -> list:
    code = read_kit(ctx)
    options = sorted(set(re.findall(r"config\.(\w+)", code)) | set(defaults(code)))
    names = functions(code)
    events = sorted(set(re.findall(r'emit\("(\w+)"', code)))
    values = defaults(code)
    page = {"slug": "kit-api", "section": "reference", "order": 10, "kind": ""}

    check(options, OPTIONS, "option")
    check(names, FUNCTIONS, "function")
    check(events, EVENTS, "event")
    for lang in ctx.langs:
        fr = lang == "fr"
        rows_options = "\n".join("| `%s` | %s | %s |" % (name, "`%s`" % values[name] if name in values else "-", OPTIONS[name][fr]) for name in options)
        rows_functions = "\n".join("| `%s` | %s |" % (name, FUNCTIONS[name][fr]) for name in names)
        rows_events = "\n".join("| `%s` | %s |" % (name, EVENTS[name][fr]) for name in events)
        page[lang] = {
            "title": "API du kit" if fr else "Kit API",
            "summary": ("Les options de Kit.init, les fonctions et les événements du kit, lus dans kit/kit.js."
                        if fr else "The options of Kit.init, the functions and the events of the kit, read from kit/kit.js."),
            "keywords": "Kit.init options config api fonctions événements on emit" if fr else "Kit.init options config api functions events on emit",
            "md": ("## %s {#options}\n\n%s\n\n| %s | %s | %s |\n|---|---|---|\n%s\n\n"
                   "## %s {#functions}\n\n| %s | %s |\n|---|---|\n%s\n\n"
                   "## %s {#events}\n\n%s\n\n```js \"%s\"\nKit.on(\"beat\", () => stage.classList.add(\"pulse\"));\n```\n\n| %s | %s |\n|---|---|\n%s\n") % (
                "Options de Kit.init" if fr else "Options of Kit.init",
                "Toutes les clés que le kit lit (`config.<clé>`), avec leur valeur par défaut." if fr else "Every key the kit reads (`config.<key>`), with its default value.",
                "Clé" if fr else "Key", "Défaut" if fr else "Default", "Rôle" if fr else "Role", rows_options,
                "Fonctions" if fr else "Functions", "Nom" if fr else "Name", "Rôle" if fr else "Role", rows_functions,
                "Événements" if fr else "Events",
                "Une page de style réagit au kit avec `Kit.on` :" if fr else "A style page reacts to the kit with `Kit.on`:",
                "Exemple" if fr else "Example",
                "Événement" if fr else "Event", "Données" if fr else "Data", rows_events),
        }
    return [page]


def search_entries(ctx) -> list:
    code = read_kit(ctx)
    entries = []

    for lang in ctx.langs:
        fr = lang == "fr"
        for name in functions(code):
            entries.append({"k": "api", "l": lang, "t": "Kit.%s" % name, "d": FUNCTIONS[name][fr], "u": "kit-api.html#functions", "x": ""})
        for name in sorted(set(re.findall(r'emit\("(\w+)"', code))):
            entries.append({"k": "event", "l": lang, "t": name, "d": EVENTS[name][fr], "u": "kit-api.html#events", "x": ""})
    return entries
