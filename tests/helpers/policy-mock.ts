import type { Page } from '@playwright/test'

/** Réponse minimale pour `/management/passwd/getpolicies` (sans API réelle). */
export const MOCK_POLICY_PAYLOAD = {
  data: {
    bannedTime: 3600,
    checkPwned: false,
    goodComplexity: 60,
    hasLowerCase: 1,
    hasNumbers: 1,
    hasSpecialChars: 1,
    hasUpperCase: 1,
    len: 8,
    maxRetry: 10,
    minComplexity: 5,
    resetBySms: false,
    redirectUrl: '',
  },
}

export async function mockGetPolicies(page: Page) {
  await page.route('**/management/passwd/getpolicies', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(MOCK_POLICY_PAYLOAD),
    })
  })
}
