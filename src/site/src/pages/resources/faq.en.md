+++
title = "FAQ"
summary = "The usual questions: videos, sound, offline use, own photos, saved wishes, adding a style."
section = "resources"
order = 10
keywords = "faq questions video youtube sound offline photos wishes style"
+++

Short answers to the questions the POCs raise.

## The Ado TV videos do not play {#videos}

The page is opened as `file://`, and YouTube refuses its embedded player there. Run `./serve.sh jpop.html` or use the
[online demo](page:getting-started#demo); on `file://` each video opens on YouTube instead.

## There is no sound {#sound}

Browsers block the sound until a click on the page: press play once. Check the volume in the settings.

## Does it work offline? {#offline}

Yes, except what comes from the internet: the photos of the photographer style (picsum.photos), the YouTube videos and
thumbnails of Ado TV. three.js and the 3D rose are in the repository.

## Can I use my own photos? {#photos}

Yes: in `photographer.html`, the `PHOTOS` list builds the picsum.photos addresses; point `url` to your files, or add them to
`files` in `Kit.init` to see them in Files.

## Where are the wishes kept? {#wishes}

In the `localStorage` of the browser (`poc-ado-wishes`), only on that computer; clearing the site data removes them.

## How do I add a style? {#new-style}

Copy a page, change its `--k-*` variables, its decor and its windows, then call `Kit.init`: see
[how a style is built](page:kit-architecture#style-page).
