/// Backend'in `/auth/*` uçlarından döndürdüğü kod → çeviri anahtarı eşlemesi.
/// Backend artık ham Türkçe metin yerine bu sabit kodları döndürüyor
/// (bkz. memorylane backend reposu, GlobalExceptionHandler/AuthController).
const Map<String, String> authErrorKeys = {
  'USER_NOT_FOUND': 'apiError.userNotFound',
  'INVALID_PASSWORD': 'authError.invalidPassword',
  'EMAIL_ALREADY_IN_USE': 'authError.emailAlreadyInUse',
  'USERNAME_ALREADY_IN_USE': 'authError.usernameAlreadyInUse',
  'INVALID_VERIFICATION_CODE': 'authError.invalidVerificationCode',
  'VERIFICATION_CODE_EXPIRED': 'authError.verificationCodeExpired',
  'ACCOUNT_ALREADY_VERIFIED': 'authError.accountAlreadyVerified',
  'INVALID_RESET_CODE': 'authError.invalidResetCode',
  'RESET_CODE_EXPIRED': 'authError.resetCodeExpired',
  'EMAIL_NOT_REGISTERED': 'authError.emailNotRegistered',
};
