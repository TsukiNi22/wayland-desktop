+++
title = "FAQ"
summary = "Les questions habituelles : vidéos, son, hors ligne, ses propres photos, vœux enregistrés, ajouter un style."
keywords = "faq questions vidéo youtube son hors ligne photos vœux style"
+++

Des réponses courtes aux questions que posent les POC.

## Les vidéos d'Ado TV ne se lancent pas {#videos}

La page est ouverte en `file://`, et YouTube y refuse son lecteur intégré. Lancez `./serve.sh jpop.html` ou utilisez la
[démo en ligne](page:getting-started#demo) ; en `file://` chaque vidéo s'ouvre sur YouTube à la place.

## Il n'y a pas de son {#sound}

Les navigateurs bloquent le son jusqu'à un clic sur la page : appuyez une fois sur lecture. Vérifiez le volume dans les réglages.

## Ça marche hors ligne ? {#offline}

Oui, sauf ce qui vient d'Internet : les photos du style photographe (picsum.photos), les vidéos et miniatures YouTube d'Ado
TV. three.js et la rose 3D sont dans le dépôt.

## Je peux mettre mes propres photos ? {#photos}

Oui : dans `photographer.html`, la liste `PHOTOS` construit les adresses picsum.photos ; faites pointer `url` vers vos fichiers,
ou ajoutez-les à `files` dans `Kit.init` pour les voir dans Fichiers.

## Où sont gardés les vœux ? {#wishes}

Dans le `localStorage` du navigateur (`poc-ado-wishes`), sur cet ordinateur seulement ; effacer les données du site les supprime.

## Comment ajouter un style ? {#new-style}

Copiez une page, changez ses variables `--k-*`, son décor et ses fenêtres, puis appelez `Kit.init` : voir
[comment un style est construit](page:kit-architecture#style-page).
