import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { WslExecutor } from './wsl-executor.js';
import { writeFileToWSL, readFileFromWSL, writeFilesBatch } from './file-copier.js';
import {
  validateCommand,
  validateLinuxPath,
  validateInstanceName,
  validateLinuxUsername,
} from './validators.js';

const wsl = new WslExecutor();

const server = new McpServer({
  name: 'wsl-manager',
  version: '1.0.0',
});

// ─────────────────────────────────────────────────────────────────────────────
// Tool 1 : lister les instances
// ─────────────────────────────────────────────────────────────────────────────
server.tool(
  'wsl_list_instances',
  'Liste toutes les instances WSL avec leur état (running/stopped), version WSL, et instance par défaut.',
  {},
  async () => {
    const instances = wsl.listInstances();
    if (instances.length === 0) {
      return { content: [{ type: 'text', text: 'Aucune instance WSL trouvée.' }] };
    }
    const lines = instances.map(
      (i) =>
        `${i.isDefault ? '* ' : '  '}${i.name.padEnd(32)} ${i.state.padEnd(10)} WSL${i.version}`,
    );
    return {
      content: [{ type: 'text', text: ['NAME                             STATE      VERSION', ...lines].join('\n') }],
    };
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Tool 2 : créer une instance
// ─────────────────────────────────────────────────────────────────────────────
server.tool(
  'wsl_create_instance',
  'Crée une nouvelle instance WSL en installant une distro depuis le web (--web-download) et en configurant un utilisateur Linux.',
  {
    instance_name: z
      .string()
      .regex(/^[a-zA-Z0-9_-]{1,64}$/, 'Lettres, chiffres, tirets, underscores (1-64 car.)')
      .describe('Nom de l\'instance WSL à créer'),
    distro: z
      .enum(['Ubuntu', 'Ubuntu-26.04', 'Ubuntu-24.04', 'Ubuntu-22.04', 'Ubuntu-20.04', 'Debian', 'kali-linux', 'openSUSE-Tumbleweed', 'Alpine'])
      .describe('Distribution Linux à installer'),
    username: z
      .string()
      .regex(/^[a-z_][a-z0-9_-]{0,31}$/, 'Minuscules, chiffres, tirets, underscores')
      .describe('Nom d\'utilisateur Linux à créer dans l\'instance'),
    password: z.string().min(8).describe('Mot de passe de l\'utilisateur (min 8 caractères)'),
    install_dir: z
      .string()
      .optional()
      .describe('Chemin Windows d\'installation optionnel (ex: C:\\WSL\\mon_instance). Laissez vide pour le défaut.'),
  },
  async ({ instance_name, distro, username, password, install_dir }) => {
    validateInstanceName(instance_name);
    validateLinuxUsername(username);

    const logs: string[] = [];

    // Étape 1 : installer la distro
    logs.push(`[1/4] Installation de ${distro} (--web-download)...`);
    await wsl.installDistro(distro);
    logs.push(`      ✓ Distro "${distro}" installée.`);

    // L'instance porte le nom de la distro par défaut.
    // Si un nom personnalisé est demandé, on fait export → import → unregister.
    let effectiveName: string = distro;

    if (instance_name.toLowerCase() !== distro.toLowerCase()) {
      logs.push(`[2/4] Renommage "${distro}" → "${instance_name}"...`);
      const tmpTar = path.join(os.tmpdir(), `wsl_rename_${distro}.tar`);
      const dir = install_dir ?? `C:\\WSL\\${instance_name}`;
      fs.mkdirSync(dir, { recursive: true });
      await wsl.exportInstance(distro, tmpTar);
      await wsl.importInstance(instance_name, dir, tmpTar);
      wsl.deleteInstance(distro);
      try { fs.rmSync(tmpTar); } catch { /* ignore */ }
      effectiveName = instance_name;
      logs.push(`      ✓ Renommé en "${instance_name}".`);
    } else {
      logs.push(`[2/4] Nom identique à la distro — pas de renommage.`);
    }

    // Étape 3 : configurer l'utilisateur
    logs.push(`[3/4] Configuration de l'utilisateur "${username}"...`);
    await wsl.setupUser(effectiveName, username, password);
    logs.push(`      ✓ Utilisateur "${username}" créé avec sudo.`);

    // Étape 4 : vérification
    logs.push(`[4/4] Vérification...`);
    const instances = wsl.listInstances();
    const created = instances.find((i) => i.name === effectiveName);
    if (created) {
      logs.push(`      ✓ Instance "${effectiveName}" présente (${created.state}, WSL${created.version}).`);
    } else {
      logs.push(`      ⚠ Instance introuvable dans la liste — vérifiez manuellement.`);
    }

    return { content: [{ type: 'text', text: logs.join('\n') }] };
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Tool 3 : démarrer une instance
// ─────────────────────────────────────────────────────────────────────────────
server.tool(
  'wsl_start_instance',
  'Démarre une instance WSL arrêtée.',
  {
    instance_name: z.string().describe('Nom de l\'instance WSL'),
  },
  async ({ instance_name }) => {
    validateInstanceName(instance_name);
    wsl.startInstance(instance_name);
    return { content: [{ type: 'text', text: `Instance "${instance_name}" démarrée.` }] };
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Tool 4 : arrêter une instance
// ─────────────────────────────────────────────────────────────────────────────
server.tool(
  'wsl_stop_instance',
  'Arrête une instance WSL en cours d\'exécution.',
  {
    instance_name: z.string().describe('Nom de l\'instance WSL'),
  },
  async ({ instance_name }) => {
    validateInstanceName(instance_name);
    wsl.stopInstance(instance_name);
    return { content: [{ type: 'text', text: `Instance "${instance_name}" arrêtée.` }] };
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Tool 5 : supprimer une instance
// ─────────────────────────────────────────────────────────────────────────────
server.tool(
  'wsl_delete_instance',
  'Supprime définitivement une instance WSL et toutes ses données (opération irréversible).',
  {
    instance_name: z.string().describe('Nom de l\'instance WSL à supprimer'),
    confirm: z
      .boolean()
      .describe('Doit être true pour confirmer la suppression irréversible'),
  },
  async ({ instance_name, confirm }) => {
    validateInstanceName(instance_name);
    if (!confirm) {
      return {
        content: [{
          type: 'text',
          text: 'Suppression annulée. Passez confirm: true pour confirmer.',
        }],
        isError: true,
      };
    }
    wsl.deleteInstance(instance_name);
    return { content: [{ type: 'text', text: `Instance "${instance_name}" supprimée définitivement.` }] };
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Tool 6 : écrire un fichier
// ─────────────────────────────────────────────────────────────────────────────
server.tool(
  'wsl_write_file',
  'Écrit un fichier dans le système de fichiers d\'une instance WSL. Idéal pour Dockerfile, docker-compose.yml, .env, scripts shell. Fonctionne même si l\'instance est arrêtée.',
  {
    instance_name: z.string().describe('Nom de l\'instance WSL'),
    path: z
      .string()
      .describe('Chemin absolu Linux du fichier (ex: /home/user/app/Dockerfile)'),
    content: z.string().max(10 * 1024 * 1024).describe('Contenu du fichier en UTF-8'),
    create_parents: z
      .boolean()
      .optional()
      .default(true)
      .describe('Créer les répertoires parents si inexistants (défaut: true)'),
  },
  async ({ instance_name, path: filePath, content, create_parents }) => {
    validateInstanceName(instance_name);
    validateLinuxPath(filePath);
    writeFileToWSL(instance_name, filePath, content, create_parents ?? true);
    const kb = (Buffer.byteLength(content, 'utf8') / 1024).toFixed(1);
    return {
      content: [{ type: 'text', text: `Fichier écrit : ${filePath} (${kb} KB) dans "${instance_name}".` }],
    };
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Tool 7 : écrire plusieurs fichiers d'un coup
// ─────────────────────────────────────────────────────────────────────────────
server.tool(
  'wsl_write_files_batch',
  'Écrit plusieurs fichiers en une seule opération. Optimal pour déployer un projet Docker complet (Dockerfile + docker-compose.yml + .env + sources).',
  {
    instance_name: z.string().describe('Nom de l\'instance WSL'),
    files: z
      .array(
        z.object({
          path: z.string().describe('Chemin absolu Linux ou relatif (si base_dir fourni)'),
          content: z.string().describe('Contenu du fichier'),
        }),
      )
      .max(50)
      .describe('Liste de fichiers à écrire (max 50)'),
    base_dir: z
      .string()
      .optional()
      .default('')
      .describe('Répertoire de base Linux préfixé devant les chemins relatifs (ex: /home/dev/app)'),
  },
  async ({ instance_name, files, base_dir }) => {
    validateInstanceName(instance_name);
    for (const f of files) {
      const resolved = f.path.startsWith('/') ? f.path : `${base_dir}/${f.path}`;
      validateLinuxPath(resolved.replace(/\/+/g, '/'));
    }
    writeFilesBatch(instance_name, files, base_dir ?? '');
    return {
      content: [{
        type: 'text',
        text: `${files.length} fichier(s) écrit(s) dans "${instance_name}":\n` +
          files.map((f) => `  ✓ ${f.path}`).join('\n'),
      }],
    };
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Tool 8 : lire un fichier
// ─────────────────────────────────────────────────────────────────────────────
server.tool(
  'wsl_read_file',
  'Lit le contenu d\'un fichier depuis une instance WSL.',
  {
    instance_name: z.string().describe('Nom de l\'instance WSL'),
    path: z.string().describe('Chemin absolu Linux du fichier'),
    max_bytes: z
      .number()
      .optional()
      .default(102400)
      .describe('Limite de lecture en octets (défaut: 100 KB)'),
  },
  async ({ instance_name, path: filePath, max_bytes }) => {
    validateInstanceName(instance_name);
    validateLinuxPath(filePath);
    const content = readFileFromWSL(instance_name, filePath, max_bytes ?? 102_400);
    return { content: [{ type: 'text', text: content }] };
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Tool 9 : exécuter une commande
// ─────────────────────────────────────────────────────────────────────────────
server.tool(
  'wsl_exec',
  'Exécute une commande bash dans une instance WSL. Supporte docker, apt, pip, npm, etc. Certaines commandes destructrices sont bloquées par sécurité.',
  {
    instance_name: z.string().describe('Nom de l\'instance WSL'),
    command: z.string().min(1).max(4000).describe('Commande bash à exécuter'),
    working_dir: z
      .string()
      .optional()
      .describe('Répertoire de travail Linux (ex: /home/dev/app)'),
    user: z
      .string()
      .optional()
      .default('root')
      .describe('Utilisateur Linux sous lequel exécuter la commande (défaut: root)'),
    timeout_seconds: z
      .number()
      .min(1)
      .max(600)
      .optional()
      .default(120)
      .describe('Timeout en secondes (défaut: 120, max: 600)'),
  },
  async ({ instance_name, command, working_dir, user, timeout_seconds }) => {
    validateInstanceName(instance_name);
    validateCommand(command);

    const result = await wsl.exec(instance_name, command, {
      workingDir: working_dir,
      user: user ?? 'root',
      timeoutMs: (timeout_seconds ?? 120) * 1000,
    });

    const output = [
      `Exit code: ${result.timedOut ? 'TIMEOUT' : result.exitCode}`,
      result.stdout ? `stdout:\n${result.stdout}` : '',
      result.stderr ? `stderr:\n${result.stderr}` : '',
    ]
      .filter(Boolean)
      .join('\n\n');

    return {
      content: [{ type: 'text', text: output }],
      isError: result.exitCode !== 0,
    };
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Tool 10 : lister les ports en écoute
// ─────────────────────────────────────────────────────────────────────────────
server.tool(
  'wsl_list_ports',
  'Liste les ports TCP/UDP en écoute dans une instance WSL (via ss ou netstat).',
  {
    instance_name: z.string().describe('Nom de l\'instance WSL'),
  },
  async ({ instance_name }) => {
    validateInstanceName(instance_name);
    const output = await wsl.listPorts(instance_name);
    return {
      content: [{ type: 'text', text: output.trim() || 'Aucun port en écoute.' }],
    };
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Démarrage du serveur
// ─────────────────────────────────────────────────────────────────────────────
const transport = new StdioServerTransport();
await server.connect(transport);
console.error('[wsl-manager MCP] Serveur démarré (stdio)');
