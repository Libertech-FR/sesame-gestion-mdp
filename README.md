# sesame-gestion-mdp

UI Nuxt/Quasar de **gestion / changement / réinitialisation de mot de passe** pour Sesame.

Ce dépôt ne contient **pas d’API**: l’application appelle l’API Sesame via un **proxy Nuxt** sur le chemin `/management/passwd/*` (cf. `nuxt.config.ts`).

## Prérequis

- **Docker** (recommandé) + `make`
- Un réseau Docker nommé **`dev`** (créé une seule fois)
- Accès à une API Sesame (ex. orchestrator) exposant les endpoints `/management/passwd/*`

## Configuration

Copier `.env.exemple` vers `.env` puis ajuster.

- **API_URL**: URL de l’API cible (ex: `http://monserverSesame:4000`)
- **API_KEY**: jeton Bearer injecté par le proxy sur les requêtes `/management/passwd/*`
- **ACTION**: écran par défaut (`menu`, `change`, `reset`) — utilisé par `appConfig.action`
- **USER_LABEL**: libellé affiché (ex. “Utilisateur” / “Email”)
- **COLOR_***: thème Quasar

HTTPS en dev (optionnel) :

- **SESAME_HTTPS_ENABLED**: `true|false`
- **SESAME_HTTPS_PATH_KEY** / **SESAME_HTTPS_PATH_CERT**: chemins des certificats (voir `make generate-ssl-cert`)

## Démarrage rapide (Docker)

Tout est prévu pour **ne pas installer Node/Yarn sur le poste**.

- **Créer le réseau dev** (une fois):

```bash
make network-dev
```

- **Build de l’image app**:

```bash
make build
```

- **Installer les dépendances** (dans le conteneur):

```bash
make exec
# puis, dans le shell:
yarn install
```

- **Lancer en dev**:

```bash
make dev
```

Par défaut, Nuxt écoute sur `3000` dans le conteneur et est exposé sur l’hôte via `APP_WEB_PORT` (par défaut `3002`, cf. `Makefile`).

## Tests (Docker)

Les tests end-to-end utilisent Playwright avec **Chromium** dans l’image `Dockerfile.test`.

- **Unit + e2e**:

```bash
make test
```

- **CI locale (lint + unit + e2e + build)**:

```bash
make verify
```

## Scripts Yarn (référence)

Les scripts sont définis dans `package.json` (souvent exécutés via `make exec`).

- `yarn dev`: Nuxt dev
- `yarn test`: lint (préparation Nuxt) + unit (Vitest) + e2e (Playwright)
- `yarn ci`: `yarn test` puis `yarn build`
- `yarn start:prod`: démarrage “prod” via `start.mjs` (rebuild si le hash `.env` change)

## Proxy API (chemin `/management/passwd`)

Le proxy est configuré dans `nuxt.config.ts`:

- Les requêtes vers **`/management/passwd/*`** sont proxifiées vers `API_URL`
- Le header **`Authorization: Bearer $API_KEY`** est ajouté automatiquement
- TLS côté cible est accepté même si non vérifié (`secure: false`)

Endpoints typiquement utilisés par l’UI :

- `GET /management/passwd/getpolicies`
- `POST /management/passwd/change`
- `POST /management/passwd/initreset`
- `POST /management/passwd/resetbycode`
- `POST /management/passwd/reset`
