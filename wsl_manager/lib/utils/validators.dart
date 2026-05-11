final _instanceNameRegex = RegExp(r'^[a-zA-Z0-9_-]{2,64}$');
final _linuxUsernameRegex = RegExp(r'^[a-z][a-z0-9_-]{0,31}$');
final _urlRegex = RegExp(r'^https?://.+\.(tar|tar\.gz|tgz)$');

String? validateInstanceName(String? value, {List<String> existing = const []}) {
  if (value == null || value.trim().isEmpty) return 'Le nom est requis';
  if (!_instanceNameRegex.hasMatch(value)) {
    return 'Alphanumérique, tirets et underscores uniquement (2–64 caractères)';
  }
  if (existing.map((e) => e.toLowerCase()).contains(value.toLowerCase())) {
    return 'Ce nom est déjà utilisé';
  }
  return null;
}

String? validateLinuxUsername(String? value) {
  if (value == null || value.trim().isEmpty) return 'Le nom d\'utilisateur est requis';
  if (value == 'root') return 'Ne peut pas être "root"';
  if (!_linuxUsernameRegex.hasMatch(value)) {
    return 'Minuscules, chiffres et tirets uniquement (1–32 caractères)';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Le mot de passe est requis';
  if (value.length < 8) return 'Minimum 8 caractères';
  return null;
}

String? validatePasswordConfirm(String? value, String password) {
  if (value != password) return 'Les mots de passe ne correspondent pas';
  return null;
}

String? validateDistroUrl(String? value) {
  if (value == null || value.trim().isEmpty) return 'L\'URL est requise';
  if (!_urlRegex.hasMatch(value)) {
    return 'URL http/https vers un fichier .tar ou .tar.gz';
  }
  return null;
}
