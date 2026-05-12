import { test, expect } from '@playwright/test'
import { mockGetPolicies } from '../helpers/policy-mock'

test.describe('Initialisation compte', () => {
  test.beforeEach(async ({ page }) => {
    await mockGetPolicies(page)
  })

  test('affiche l’écran d’initialisation avec un jeton', async ({ page }) => {
    await page.goto('/initaccount/token-e2e-test')
    await expect(page.getByText('Initialisation de votre compte')).toBeVisible()
    await expect(page.getByRole('button', { name: 'Validez' })).toBeVisible()
  })
})
