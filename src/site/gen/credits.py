"""Credits page, read from assets/CREDITS.md: the table of the assets (file, source, author, license) as it is in the repository."""
import re


def rows(ctx) -> list:
    text = (ctx.site / ".." / ".." / "poc" / "assets" / "CREDITS.md").read_text(encoding="utf-8")
    lines = [line for line in text.splitlines() if line.startswith("| `")]

    return [[cell.strip() for cell in line.strip("|").split(" | ")] for line in lines]


def pages(ctx) -> list:
    found = rows(ctx)
    page = {"slug": "credits", "section": "resources", "order": 20, "kind": ""}

    for lang in ctx.langs:
        fr = lang == "fr"
        table = "\n".join("| %s |" % " | ".join(re.sub(r"`\.\./", "`", cell) for cell in row) for row in found)
        page[lang] = {
            "title": "Crédits et licences" if fr else "Credits and licenses",
            "summary": ("Les images, le modèle 3D et les bibliothèques utilisés par les POC, avec leur licence, lus dans assets/CREDITS.md."
                        if fr else "The images, the 3D model and the libraries used by the POCs, with their license, read from assets/CREDITS.md."),
            "keywords": "crédits licences images cc by photos miku rose three.js" if fr else "credits licenses images cc by photos miku rose three.js",
            "md": ("## %s {#code}\n\n%s\n\n## %s {#assets}\n\n| %s | %s | %s | %s |\n|---|---|---|---|\n%s\n\n"
                   "## %s {#online}\n\n%s\n") % (
                "Le code" if fr else "The code",
                "Le code (le kit, les pages, ce site) est sous licence MIT. Elle ne couvre pas les ressources ci-dessous."
                if fr else "The code (the kit, the pages, this site) is under the MIT license. It does not cover the assets below.",
                "Les ressources" if fr else "The assets",
                "Fichier" if fr else "File", "Source" if fr else "Source", "Auteur" if fr else "Author", "Licence" if fr else "License", table,
                "Ce qui vient d'Internet" if fr else "What comes from the internet",
                "La page Ado liste les vidéos officielles de la chaîne YouTube d'Ado et les lit avec le lecteur intégré de YouTube : rien n'est "
                "copié dans le dépôt. Les photos du style photographe viennent de picsum.photos (licence Unsplash). Toute la musique est jouée en "
                "direct par le synthé du kit (mélodies originales)."
                if fr else "The Ado page lists the official videos of Ado's YouTube channel and plays them with the YouTube embedded player: "
                "nothing is copied into the repository. The photos of the photographer style come from picsum.photos (Unsplash license). All the "
                "music is played live by the synth of the kit (original melodies)."),
        }
    return [page]
