import stringEntropy from 'fast-password-entropy'

/** Même jeu de caractères spéciaux que `InputNewPassword.vue` (`checkPolicy`). */
const SPECIAL_RE = /[!@#$%^&*()+=._-]/

export function hasMinLength(password: string, min: number): boolean {
  if (min <= 0) return true
  return password.length >= min
}

export function hasUppercase(password: string, minUpper: number): boolean {
  if (minUpper < 1) return true
  return /[A-Z]/.test(password)
}

export function hasLowercase(password: string, minLower: number): boolean {
  if (minLower < 1) return true
  return /[a-z]/.test(password)
}

export function hasDigit(password: string, minNumber: number): boolean {
  if (minNumber < 1) return true
  return /\d/.test(password)
}

export function hasSpecialChar(password: string, minSpecial: number): boolean {
  if (minSpecial < 1) return true
  return SPECIAL_RE.test(password)
}

export function entropyBits(password: string): number {
  return stringEntropy(password)
}

export function meetsEntropy(password: string, minEntropy: number): boolean {
  if (minEntropy <= 0) return true
  return entropyBits(password) >= minEntropy
}

/** Vérifie la politique locale (sans HIBP). */
export function passwordPassesLocalPolicy(
  password: string,
  opts: {
    min: number
    minUpper: number
    minLower: number
    minNumber: number
    minSpecial: number
    minEntropy: number
  },
): boolean {
  return (
    hasMinLength(password, opts.min)
    && hasUppercase(password, opts.minUpper)
    && hasLowercase(password, opts.minLower)
    && hasDigit(password, opts.minNumber)
    && hasSpecialChar(password, opts.minSpecial)
    && meetsEntropy(password, opts.minEntropy)
  )
}
