import { spawnSync, spawn } from 'node:child_process';

export interface WslInstance {
  name: string;
  state: 'running' | 'stopped' | 'installing';
  version: number;
  isDefault: boolean;
}

export interface ExecResult {
  exitCode: number;
  stdout: string;
  stderr: string;
  timedOut: boolean;
}

export interface ExecOptions {
  workingDir?: string;
  user?: string;
  timeoutMs?: number;
}

function decodeWslOutput(buffer: Buffer): string {
  // UTF-16 LE BOM: FF FE — sortie standard de wsl.exe sur Windows 11
  if (buffer.length >= 2 && buffer[0] === 0xff && buffer[1] === 0xfe) {
    return buffer.toString('utf16le').replace(/\0/g, '');
  }
  // Fallback : strip null bytes, decode UTF-8
  const cleaned = Buffer.from(buffer.filter((b) => b !== 0));
  return cleaned.toString('utf8');
}

function parseVerboseList(output: string): WslInstance[] {
  return output
    .split('\n')
    .map((l) => l.replace(/\r/g, ''))
    .filter((l) => l.trim() && !l.trimStart().startsWith('NAME'))
    .map((line) => {
      const isDefault = line.startsWith('*');
      const clean = line.replace('*', ' ').trim();
      const parts = clean.split(/\s{2,}/);
      if (parts.length < 3) return null;
      return {
        name: parts[0].trim(),
        state: parts[1].trim().toLowerCase() as WslInstance['state'],
        version: parseInt(parts[2].trim(), 10),
        isDefault,
      };
    })
    .filter((x): x is WslInstance => x !== null);
}

export class WslExecutor {
  listInstances(): WslInstance[] {
    const result = spawnSync('wsl.exe', ['--list', '--verbose'], {
      encoding: 'buffer',
      windowsHide: true,
    });
    if (result.error) throw result.error;
    const text = decodeWslOutput(result.stdout as Buffer);
    return parseVerboseList(text);
  }

  startInstance(name: string): void {
    const result = spawnSync('wsl.exe', ['-d', name, '--', 'exit'], {
      windowsHide: true,
    });
    if (result.status !== 0) {
      throw new Error(`Impossible de démarrer l'instance "${name}" (code ${result.status})`);
    }
  }

  stopInstance(name: string): void {
    const result = spawnSync('wsl.exe', ['--terminate', name], {
      windowsHide: true,
    });
    if (result.status !== 0) {
      throw new Error(`Impossible d'arrêter l'instance "${name}" (code ${result.status})`);
    }
  }

  deleteInstance(name: string): void {
    // Arrêter d'abord
    try { this.stopInstance(name); } catch { /* ignore */ }
    const result = spawnSync('wsl.exe', ['--unregister', name], {
      windowsHide: true,
    });
    if (result.status !== 0) {
      const err = (result.stderr as Buffer | null)?.toString('utf8') ?? '';
      throw new Error(`Impossible de supprimer l'instance "${name}": ${err}`);
    }
  }

  async installDistro(distroName: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const proc = spawn('wsl.exe', [
        '--install', distroName, '--web-download', '--no-launch',
      ], { windowsHide: true });
      proc.on('close', (code) => {
        if (code === 0) resolve();
        else reject(new Error(`wsl --install "${distroName}" a échoué (code ${code})`));
      });
    });
  }

  async exportInstance(name: string, tarPath: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const proc = spawn('wsl.exe', ['--export', name, tarPath], {
        windowsHide: true,
      });
      proc.on('close', (code) => {
        if (code === 0) resolve();
        else reject(new Error(`wsl --export "${name}" a échoué (code ${code})`));
      });
    });
  }

  async importInstance(name: string, installDir: string, tarPath: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const proc = spawn('wsl.exe', [
        '--import', name, installDir, tarPath, '--version', '2',
      ], { windowsHide: true });
      proc.on('close', (code) => {
        if (code === 0) resolve();
        else reject(new Error(`wsl --import "${name}" a échoué (code ${code})`));
      });
    });
  }

  async setupUser(
    instanceName: string,
    username: string,
    password: string,
  ): Promise<void> {
    const run = (cmd: string) => this.exec(instanceName, cmd, { user: 'root' });

    await run(`useradd -m -s /bin/bash ${username}`);
    await run(`usermod -aG sudo ${username}`);
    await run(`echo "${username}:${password}" | chpasswd`);
    await run(`printf '[user]\\ndefault=${username}\\n' > /etc/wsl.conf`);

    // Terminer l'instance pour appliquer /etc/wsl.conf
    try { this.stopInstance(instanceName); } catch { /* ignore */ }

    // Effacer le mot de passe de la mémoire
    password = '';
  }

  async exec(
    instanceName: string,
    command: string,
    opts: ExecOptions = {},
  ): Promise<ExecResult> {
    const { workingDir, user = 'root', timeoutMs = 120_000 } = opts;
    const fullCmd = workingDir ? `cd ${workingDir} && ${command}` : command;

    return new Promise((resolve) => {
      const args = ['-d', instanceName, '-u', user, '--', 'bash', '-c', fullCmd];
      const proc = spawn('wsl.exe', args, { windowsHide: true });

      const stdoutChunks: Buffer[] = [];
      const stderrChunks: Buffer[] = [];
      let timedOut = false;

      const timer = setTimeout(() => {
        timedOut = true;
        proc.kill();
      }, timeoutMs);

      proc.stdout.on('data', (d: Buffer) => stdoutChunks.push(d));
      proc.stderr.on('data', (d: Buffer) => stderrChunks.push(d));

      proc.on('close', (code) => {
        clearTimeout(timer);
        resolve({
          exitCode: timedOut ? -1 : (code ?? 1),
          stdout: Buffer.concat(stdoutChunks).toString('utf8'),
          stderr: Buffer.concat(stderrChunks).toString('utf8'),
          timedOut,
        });
      });
    });
  }

  async listPorts(instanceName: string): Promise<string> {
    const result = await this.exec(
      instanceName,
      "if command -v ss >/dev/null 2>&1; then ss -H -lntu; " +
      "elif command -v netstat >/dev/null 2>&1; then netstat -lntu; " +
      "else echo 'ss/netstat non disponible'; fi",
      { user: 'root' },
    );
    return result.stdout;
  }
}
