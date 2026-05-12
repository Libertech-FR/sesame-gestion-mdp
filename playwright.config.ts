import { defineConfig, devices } from '@playwright/test'
import { existsSync } from 'node:fs'

const baseURL = process.env.PLAYWRIGHT_BASE_URL ?? 'http://127.0.0.1:3000'
/** URL exacte pour la sonde de démarrage (évite blocage si baseURL sans slash final). */
const webServerUrl = new URL('/', baseURL).href

/** Désactive le webServer intégré (tu lances déjà `yarn dev` à part). */
const skipWebServer = !!process.env.PLAYWRIGHT_SKIP_WEB_SERVER

/** Chromium système (Alpine : paquet `chromium`). Ne pas fusionner `devices['Desktop Chrome']` ici : depuis Playwright ~1.49 cela pousse `chromium_headless_shell` (cache ms-playwright). */
const systemChromium =
  process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH?.trim() ||
  (existsSync('/usr/bin/chromium') ? '/usr/bin/chromium' : '')

/**
 * Le serveur Nuxt doit répondre en HTTP sur baseURL : désactive HTTPS pour l’e2e
 * (sinon Playwright attend du HTTP alors que Nuxt écoute en HTTPS → attente infinie).
 */
const webServerEnv = {
  CI: 'true',
  /** Lu par `nuxt.config` : pas de HMR pendant le serveur lancé par Playwright (évite reload + ECONNRESET). */
  E2E_TEST: '1',
  /** Vue menu avec « Changer mon mot de passe » / « J'ai oublié… » (`LoginMenu.vue`, `action === 'menu'`). */
  ACTION: 'menu',
  BROWSERSLIST_IGNORE_OLD_DATA: '1',
  SESAME_HTTPS_ENABLED: 'false',
  SESAME_HTTPS_PATH_KEY: '',
  SESAME_HTTPS_PATH_CERT: '',
} as const

export default defineConfig({
  testDir: 'tests/e2e',
  /** Un seul worker + pas de parallélisme de fichiers : un seul client sur le `yarn dev` partagé (évite EPIPE / races). */
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: process.env.CI ? 'github' : 'list',
  timeout: 60_000,
  expect: { timeout: 15_000 },
  use: {
    baseURL,
    trace: 'on-first-retry',
    ignoreHTTPSErrors: true,
    launchOptions: {
      args: ['--disable-dev-shm-usage', '--no-sandbox'],
    },
  },
  projects: [
    {
      /** Nom évite toute convention interne liée au projet « chromium ». */
      name: 'e2e',
      use: systemChromium
        ? {
            browserName: 'chromium' as const,
            viewport: { width: 1280, height: 720 },
            launchOptions: {
              executablePath: systemChromium,
              args: ['--disable-dev-shm-usage', '--no-sandbox'],
            },
          }
        : { ...devices['Desktop Chrome'] },
    },
  ],
  ...(skipWebServer
    ? {}
    : {
        webServer: {
          command: 'yarn dev',
          url: webServerUrl,
          reuseExistingServer: !process.env.CI,
          timeout: 300_000,
          /** Réduit les EPIPE côté transport Playwright ↔ sous-processus (plus de pipe stdout/stderr). */
          stdout: 'ignore',
          stderr: 'ignore',
          env: {
            ...Object.fromEntries(
              Object.entries(process.env).filter((e): e is [string, string] => e[1] !== undefined),
            ),
            ...webServerEnv,
          },
        },
      }),
})
