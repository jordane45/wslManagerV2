// Patterns de commandes dangereuses bloqués dans wsl_exec
const BLOCKED_PATTERNS: RegExp[] = [
  /rm\s+-rf\s+\/[^a-z]/i,             // rm -rf / ou rm -rf /*
  /rm\s+--no-preserve-root/i,          // rm --no-preserve-root
  /mkfs/i,                              // formatage filesystem
  /dd\s+if=.*of=\/dev\//i,             // écriture raw device
  />\s*\/dev\/(sda|hda|vda|nvme)/i,    // redirection vers périphérique bloc
  /:(){ :|:& };:/,                      // fork bomb
  /shutdown|poweroff|reboot|halt/i,    // arrêt système
  /wsl\.exe.*--unregister/i,           // pas de suppression d'instance depuis exec
  /\bpasswd\s+root\b/i,               // changement mdp root sans contexte
];

/**
 * Valide une commande avant de l'exécuter dans une instance WSL.
 * Lève une erreur si la commande correspond à un pattern bloqué.
 */
export function validateCommand(command: string): void {
  for (const pattern of BLOCKED_PATTERNS) {
    if (pattern.test(command)) {
      throw new Error(
        `Commande refusée pour des raisons de sécurité (pattern: ${pattern.source})`,
      );
    }
  }
}

/**
 * Valide un chemin Linux absolu utilisé pour l'écriture de fichiers.
 * Refuse le path traversal (../).
 */
export function validateLinuxPath(linuxPath: string): void {
  if (!linuxPath.startsWith('/')) {
    throw new Error('Le chemin doit être absolu (commencer par /)');
  }
  if (linuxPath.includes('..')) {
    throw new Error('Path traversal refusé: ".." interdit dans le chemin');
  }
  if (linuxPath.includes('\0')) {
    throw new Error('Caractère nul interdit dans le chemin');
  }
}

/**
 * Valide un nom d'instance WSL.
 */
export function validateInstanceName(name: string): void {
  if (!/^[a-zA-Z0-9_-]{1,64}$/.test(name)) {
    throw new Error(
      `Nom d'instance invalide: "${name}". Utilisez uniquement lettres, chiffres, tirets et underscores (1-64 caractères).`,
    );
  }
}

/**
 * Valide un nom d'utilisateur Linux.
 */
export function validateLinuxUsername(username: string): void {
  if (!/^[a-z_][a-z0-9_-]{0,31}$/.test(username)) {
    throw new Error(
      `Nom d'utilisateur Linux invalide: "${username}". Minuscules, chiffres, tirets, underscores.`,
    );
  }
}
