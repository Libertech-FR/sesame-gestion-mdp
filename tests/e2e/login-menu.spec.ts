import { test, expect } from '@playwright/test'
import { mockGetPolicies } from '../helpers/policy-mock'

test.describe('Menu mot de passe', () => {
  test.beforeEach(async ({ page }) => {
    await mockGetPolicies(page)
  })

  test('affiche le menu puis le formulaire « changer mot de passe »', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByRole('button', { name: 'Changer mon mot de passe' })).toBeVisible()
    await page.getByRole('button', { name: 'Changer mon mot de passe' }).click()
    await expect(page.getByLabel(/Mot de passe/i).first()).toBeVisible()
    await expect(page.getByRole('button', { name: 'Validez' })).toBeVisible()
  })

  test('affiche le flux « mot de passe oublié »', async ({ page }) => {
    await page.goto('/')
    await page.getByRole('button', { name: "J'ai oublié mon mot de passe" }).click()
    await expect(page.getByRole('button', { name: 'Par mail' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Validez' })).toBeVisible()
  })
})
