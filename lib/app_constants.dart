class AppConstants {
  // Pulls from --dart-define or --dart-define-from-file
  // This is safe to keep in a public repo because it contains no actual token.
  static const String logoDevToken = String.fromEnvironment('LOGO_DEV_TOKEN');
}
