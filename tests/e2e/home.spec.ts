import { test, expect } from '@playwright/test'
import { mockGetPolicies } from '../helpers/policy-mock'

test.describe('Page d’accueil', () => {
  test.beforeEach(async ({ page }) => {
    await mockGetPolicies(page)
  })

  test('affiche le titre de gestion d’accès', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByText('Gestion de votre accès')).toBeVisible()
  })
})
