# sesame-gestion-mdp
Gestion des mot de passe sesame

Les commandes **yarn** (install, test, build, etc.) se font dans **Docker** : `make build` puis `make exec`, puis par exemple `yarn install` et `yarn playwright:install` dans le shell du conteneur. Sur la CI, **`make ci-github`** enchaîne tout sans yarn sur le runner.

## build release
Construire une release : 

https://github.com/Libertech-FR/sesame-gestion-mdp/actions/workflows/release.yml
