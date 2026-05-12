# Ports hôte → conteneur (Nuxt écoute sur 3000 ; pas d’API dans ce dépôt)
APP_WEB_PORT = 3002
APP_WEB_PORT_SECURE = 3443

APP_WEB_DEBUG_PORT = 24678

IMG_NAME = ghcr.io/libertech-fr/sesame-gestion-mdp
TEST_IMG_NAME = sesame-gestion-mdp-test-local
BASE_NAME = sesame
APP_NAME = sesame-gestion-mdp
# Volume dédié : évite de monter les node_modules du mac dans le conteneur Linux.
# Réseau Docker « dev » : créer une fois (make network-dev ou docker network create dev).
# Flux : pas de yarn sur le Mac — make exec puis yarn install ; PR : .github/workflows/lint.yml ; push main (chemins filtrés) : docker-image.yml ; tests e2e locaux : make build && make test (image test basée sur $(IMG_NAME)).
NODE_MODULES_VOLUME = sesame-gestion-mdp-node-modules
# Cache Playwright (binaires téléchargés) pour « make exec » ; make test / verify utilisent Chromium système Alpine (pas ce volume).
PLAYWRIGHT_CACHE_VOLUME = sesame-gestion-mdp-playwright-cache

-include .env

# Apple Silicon / ARM64 : images Linux arm64 natives. Sinon linux/amd64. Surcharge possible dans .env (PLATFORM=…).
UNAME_M := $(shell uname -m 2>/dev/null || echo unknown)
ifeq ($(origin PLATFORM),undefined)
PLATFORM := $(if $(filter arm64 aarch64,$(UNAME_M)),linux/arm64,linux/amd64)
endif

GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)
GIT_COMMIT ?= $(shell git rev-parse HEAD 2>/dev/null || echo unknown)
DOCKER_TAG ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo unknown)

CERT_DIR = ./certificates
COMMON_NAME = localhost
DAYS_VALID = 365

SESAME_SENTRY_DSN ?=

$(shell mkdir -p $(CERT_DIR))

.PHONY: network-dev
network-dev: ## Créer le réseau Docker « dev » s’il n’existe pas (à lancer une fois après install machine)
	@docker network inspect dev >/dev/null 2>&1 || docker network create dev

.DEFAULT_GOAL := help
help:
	@printf "\033[33mUsage:\033[0m\n  make [target] [arg=\"val\"...]\n\n\033[33mTargets:\033[0m\n"
	@grep -h -E '^[-a-zA-Z0-9_\.\/]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-18s\033[0m %s\n", $$1, $$2}'

build: ## Image Docker (Alpine multi-stage ; pas de Playwright — voir Dockerfile.test et workflows)
	@docker build --platform $(PLATFORM) -t $(IMG_NAME) --no-cache --progress=plain \
		--build-arg BUILD_VERSION=$(DOCKER_TAG) \
		--build-arg GIT_BRANCH=$(GIT_BRANCH) \
		--build-arg GIT_COMMIT=$(GIT_COMMIT) \
		--build-arg DOCKER_TAG=$(DOCKER_TAG) \
		.

build-test-image: ## Image locale dédiée aux tests (FROM $(IMG_NAME) + Chromium + devDependencies)
	@docker build --platform $(PLATFORM) -f Dockerfile.test \
		--build-arg BASE_IMAGE=$(IMG_NAME) \
		-t $(TEST_IMG_NAME) .

# Mode « simulation » : image déjà buildée, env + certificats montés (sans écraser tout le code par le bind-mount complet)
simulation: ## Lancer en NODE_ENV=production avec montages ciblés (.env, certificats, hash)
	@touch $(CURDIR)/.env.hash
	@docker run --rm -it \
		-e NODE_ENV=production \
		-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
		-e GIT_BRANCH=$(GIT_BRANCH) \
		-e GIT_COMMIT=$(GIT_COMMIT) \
		-e DOCKER_TAG=$(DOCKER_TAG) \
		--add-host host.docker.internal:host-gateway \
		--platform $(PLATFORM) \
		--network dev \
		--name $(APP_NAME) \
		-e SESAME_SENTRY_DSN=$(SESAME_SENTRY_DSN) \
		-p $(APP_WEB_PORT):3000 \
		-p $(APP_WEB_PORT_SECURE):3443 \
		-v $(CURDIR)/.env:/data/.env \
		-v $(CURDIR)/certificates:/data/certificates \
		-v $(CURDIR)/.env.hash:/data/.env.hash \
		$(IMG_NAME) yarn start:prod

prod: ## Production : bind-mount du dépôt sur /data
	@docker run --rm -it \
		-e NODE_ENV=production \
		-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
		-e GIT_BRANCH=$(GIT_BRANCH) \
		-e GIT_COMMIT=$(GIT_COMMIT) \
		-e DOCKER_TAG=$(DOCKER_TAG) \
		--add-host host.docker.internal:host-gateway \
		--platform $(PLATFORM) \
		--network dev \
		--name $(APP_NAME) \
		-e SESAME_SENTRY_DSN=$(SESAME_SENTRY_DSN) \
		-p $(APP_WEB_PORT):3000 \
		-p $(APP_WEB_PORT_SECURE):3443 \
		-v $(CURDIR):/data \
		$(IMG_NAME) yarn start:prod

dev: ## Développement : nuxt dev (premier lancement : make network-dev, make exec → yarn install)
	@docker run --rm -it \
		-e NODE_ENV=development \
		-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
		-e GIT_BRANCH=$(GIT_BRANCH) \
		-e GIT_COMMIT=$(GIT_COMMIT) \
		-e DOCKER_TAG=$(DOCKER_TAG) \
		--add-host host.docker.internal:host-gateway \
		--platform $(PLATFORM) \
		--network dev \
		--name $(APP_NAME) \
		-e SESAME_SENTRY_DSN=$(SESAME_SENTRY_DSN) \
		-p $(APP_WEB_PORT):3000 \
		-p $(APP_WEB_PORT_SECURE):3443 \
		-v $(CURDIR):/data \
		-v $(NODE_MODULES_VOLUME):/data/node_modules \
		$(IMG_NAME) yarn dev

debug: ## Idem dev + inspecteur Node (9229)
	@docker run --rm -it \
		-e NODE_ENV=development \
		-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
		-e GIT_BRANCH=$(GIT_BRANCH) \
		-e GIT_COMMIT=$(GIT_COMMIT) \
		-e DOCKER_TAG=$(DOCKER_TAG) \
		--add-host host.docker.internal:host-gateway \
		--platform $(PLATFORM) \
		--network dev \
		--name $(APP_NAME) \
		-e SESAME_SENTRY_DSN=$(SESAME_SENTRY_DSN) \
		-p $(APP_WEB_PORT):3000 \
		-p $(APP_WEB_PORT_SECURE):3443 \
		-p 9229:9229 \
		-p $(APP_WEB_DEBUG_PORT):24678 \
		-v $(CURDIR):/data \
		-v $(NODE_MODULES_VOLUME):/data/node_modules \
		$(IMG_NAME) sh -lc 'NODE_OPTIONS="--inspect=0.0.0.0:9229" yarn dev'

exec: ## Shell interactif (yarn install, yarn add, …)
	@docker run -it --rm \
		-e NODE_ENV=development \
		-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
		--add-host host.docker.internal:host-gateway \
		--platform $(PLATFORM) \
		--network dev \
		-e SESAME_SENTRY_DSN=$(SESAME_SENTRY_DSN) \
		-v $(CURDIR):/data \
		-v $(NODE_MODULES_VOLUME):/data/node_modules \
		-v $(PLAYWRIGHT_CACHE_VOLUME):/root/.cache/ms-playwright \
		$(IMG_NAME) bash

stop: ## Arrêter le conteneur applicatif
	@docker stop $(APP_NAME) || true

stop-all: ## Arrêter le conteneur applicatif (équivalent ici, pas de stack BDD dans ce dépôt)
	@docker stop $(APP_NAME) || true

run-lint: ## Rejouer le job GitHub Actions « lint-app » avec act (nécessite nektos/act)
	act --container-architecture=linux/amd64 -j lint-app

test: build-test-image ## Vitest + Playwright dans l’image test (prérequis : make build pour taguer $(IMG_NAME) en local)
	@docker run --rm \
		-u 0 \
		-e CI=1 \
		-e NODE_ENV=development \
		-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
		-e SESAME_HTTPS_ENABLED=false \
		-e BROWSERSLIST_IGNORE_OLD_DATA=1 \
		-e PLAYWRIGHT_BASE_URL=http://127.0.0.1:3000 \
		-e PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium \
		--platform $(PLATFORM) \
		--network dev \
		-v $(CURDIR)/playwright.config.ts:/data/playwright.config.ts \
		-v $(CURDIR)/tests:/data/tests \
		-w /data \
		$(TEST_IMG_NAME) sh -lc 'yarn test'

verify: build-test-image ## CI locale : yarn ci dans l’image test (lint + unit + e2e + build)
	@docker run --rm \
		-u 0 \
		-e CI=1 \
		-e NODE_ENV=development \
		-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
		-e SESAME_HTTPS_ENABLED=false \
		-e BROWSERSLIST_IGNORE_OLD_DATA=1 \
		-e PLAYWRIGHT_BASE_URL=http://127.0.0.1:3000 \
		-e PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium \
		--platform $(PLATFORM) \
		--network dev \
		-v $(CURDIR)/playwright.config.ts:/data/playwright.config.ts \
		-v $(CURDIR)/tests:/data/tests \
		-w /data \
		$(TEST_IMG_NAME) sh -lc 'yarn ci'

ncu: ## Vérifier les mises à jour des dépendances
	@npx npm-check-updates

ncu-upgrade: ## Mettre à jour package.json vers les dernières versions
	@npx npm-check-updates -u

generate-ssl-cert: ## Générer les certificats HTTPS auto-signés
	@echo "Génération des certificats HTTPS auto-signés..."
	@openssl req -x509 \
		-newkey rsa:4096 \
		-keyout $(CERT_DIR)/server.key \
		-out $(CERT_DIR)/server.crt \
		-days $(DAYS_VALID) \
		-nodes \
		-subj "/CN=$(COMMON_NAME)"
	@chmod 600 $(CERT_DIR)/server.key
	@chmod 644 $(CERT_DIR)/server.crt
	@echo "Certificats générés avec succès dans $(CERT_DIR)"

clean-ssl-cert: ## Supprimer les certificats HTTPS locaux
	@rm -rf $(CERT_DIR)
	@echo "Certificats supprimés"

show-cert-info: ## Afficher les infos du certificat
	@openssl x509 -in $(CERT_DIR)/server.crt -text -noout

hibp-key-hex: ## Générer une clé 32 octets (64 caractères hex)
	@printf "SESAME_PASSWORD_HISTORY_HIBP_KEY=%s\n" "$$(openssl rand -hex 32)"

hibp-key-b64: ## Générer une clé 32 octets (base64)
	@printf "SESAME_PASSWORD_HISTORY_HIBP_KEY=%s\n" "$$(openssl rand -base64 32)"

