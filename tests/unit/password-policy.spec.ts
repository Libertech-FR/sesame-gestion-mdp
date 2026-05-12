import { describe, it, expect } from 'vitest'
import {
  hasMinLength,
  hasUppercase,
  hasLowercase,
  hasDigit,
  hasSpecialChar,
  meetsEntropy,
  passwordPassesLocalPolicy,
} from '../../src/utils/password-policy'

describe('password-policy', () => {
  const strong = 'Aa1!aaaaaaaa'

  it('longueur minimale', () => {
    expect(hasMinLength('abc', 3)).toBe(true)
    expect(hasMinLength('ab', 3)).toBe(false)
    expect(hasMinLength('x', 0)).toBe(true)
  })

  it('majuscule / minuscule / chiffre / spécial', () => {
    expect(hasUppercase('a', 1)).toBe(false)
    expect(hasUppercase('A', 1)).toBe(true)
    expect(hasLowercase('A', 1)).toBe(false)
    expect(hasLowercase('a', 1)).toBe(true)
    expect(hasDigit('a', 1)).toBe(false)
    expect(hasDigit('1', 1)).toBe(true)
    expect(hasSpecialChar('abc', 1)).toBe(false)
    expect(hasSpecialChar('a!', 1)).toBe(true)
  })

  it('entropie', () => {
    expect(meetsEntropy('a', 1)).toBe(true)
    expect(meetsEntropy('', 0)).toBe(true)
  })

  it('mot de passe complet valide', () => {
    expect(
      passwordPassesLocalPolicy(strong, {
        min: 8,
        minUpper: 1,
        minLower: 1,
        minNumber: 1,
        minSpecial: 1,
        minEntropy: 5,
      }),
    ).toBe(true)
  })

  it('mot de passe incomplet rejeté', () => {
    expect(
      passwordPassesLocalPolicy('short', {
        min: 10,
        minUpper: 1,
        minLower: 1,
        minNumber: 1,
        minSpecial: 1,
        minEntropy: 5,
      }),
    ).toBe(false)
  })
})
