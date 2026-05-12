# sesame-gestion-mdp
Gestion des mot de passe sesame

Les commandes **yarn** (install, build, etc.) se font dans **Docker** : `make build` puis `make exec`, puis par exemple `yarn install`. Les **e2e** passent par **`make test`** (image `Dockerfile.test`, Chromium système Alpine, sans `apt-get`). Sur GitHub, le workflow **`.github/workflows/lint.yml`** construit l’image app + image de test puis exécute `yarn ci` dans l’image de test.

## build release
Construire une release : 

https://github.com/Libertech-FR/sesame-gestion-mdp/actions/workflows/release.yml
