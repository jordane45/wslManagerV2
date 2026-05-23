import fs from 'node:fs';
import path from 'node:path';

export interface FileEntry {
  path: string;   // chemin absolu Linux, ex: /home/user/app/Dockerfile
  content: string;
}

/**
 * Convertit un chemin Linux absolu en chemin UNC Windows vers WSL.
 * /home/user/app/Dockerfile → \\wsl.localhost\instance\home\user\app\Dockerfile
 */
function linuxPathToUNC(instanceName: string, linuxPath: string): string {
  const winRelative = linuxPath.replace(/\//g, '\\');
  return `\\\\wsl.localhost\\${instanceName}${winRelative}`;
}

/**
 * Écrit un fichier dans le système de fichiers d'une instance WSL via le chemin UNC.
 * Fonctionne même si l'instance est arrêtée (WSL la démarre automatiquement).
 */
export function writeFileToWSL(
  instanceName: string,
  linuxPath: string,
  content: string,
  createParents = true,
): void {
  const uncPath = linuxPathToUNC(instanceName, linuxPath);
  if (createParents) {
    const uncDir = path.dirname(uncPath);
    fs.mkdirSync(uncDir, { recursive: true });
  }
  fs.writeFileSync(uncPath, content, 'utf8');
}

/**
 * Lit un fichier depuis une instance WSL via chemin UNC.
 */
export function readFileFromWSL(
  instanceName: string,
  linuxPath: string,
  maxBytes = 102_400,
): string {
  const uncPath = linuxPathToUNC(instanceName, linuxPath);
  const stat = fs.statSync(uncPath);
  if (stat.size > maxBytes) {
    const buf = Buffer.alloc(maxBytes);
    const fd = fs.openSync(uncPath, 'r');
    try {
      fs.readSync(fd, buf, 0, maxBytes, 0);
    } finally {
      fs.closeSync(fd);
    }
    return buf.toString('utf8') + `\n\n[... tronqué — ${stat.size} octets au total]`;
  }
  return fs.readFileSync(uncPath, 'utf8');
}

/**
 * Écrit plusieurs fichiers en une seule opération.
 * baseDir optionnel : préfixé devant les chemins relatifs.
 */
export function writeFilesBatch(
  instanceName: string,
  files: FileEntry[],
  baseDir = '',
): void {
  for (const file of files) {
    const linuxPath = file.path.startsWith('/')
      ? file.path
      : `${baseDir}/${file.path}`.replace(/\/+/g, '/');
    writeFileToWSL(instanceName, linuxPath, file.content);
  }
}
