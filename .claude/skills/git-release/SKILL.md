# /git-release — WSL Manager

Cycle complet de release pour **jordane45/wslManagerV2** :
flutter analyze → commit → tag annoté → push → release GitHub via API → workflow_dispatch.

## Usage

```
/git-release          # patch  (V2.0.3 → V2.0.4)
/git-release minor    # mineur (V2.0.4 → V2.1.0)
/git-release major    # majeur (V2.1.0 → V3.0.0)
/git-release V2.5.0   # version explicite
/git-release --dry-run
```

## Étapes à suivre

### 1 — État du repo et calcul de version

```bash
git status
git log --oneline -8
git tag --sort=-version:refname | head -5
```

- Dernier tag format `V<major>.<minor>.<patch>`
- Incrément : patch par défaut, sauf si `minor`/`major`/version explicite
- Afficher la version calculée avant de continuer

### 2 — Flutter analyze

```powershell
cd wsl_manager; flutter analyze
```

Arrêter si des **erreurs** (pas les warnings). Ne jamais tagger du code cassé.

### 3 — Commit des changements en attente

Fichiers à **exclure systématiquement** du commit :
- `.claude/settings.local.json` (permissions Claude Code locales)

S'il reste des fichiers modifiés pertinents :
1. Les lister
2. Générer un message de commit résumant les changements
3. `git add <fichiers>` (jamais `-A` pour éviter le fichier exclu)
4. `git commit -m "<message>\n\nCo-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"`

### 4 — Mettre à jour pubspec.yaml

Mettre à jour `version:` dans `wsl_manager/pubspec.yaml` pour correspondre à la nouvelle version (sans le `V`, ex: `2.0.4+1`).
Committer ce changement avec le message `chore: bump version to <X.Y.Z>`.

### 5 — Changelog depuis le dernier tag

```bash
git log <dernier_tag>..HEAD --oneline
```

Classer par préfixe de commit :
- `fix:` / `Fix` → **Correctifs**
- `feat:` / `Add` → **Nouveau**
- `refactor:` / `chore:` / reste → **Améliorations**

### 6 — Tag annoté + push

```bash
git tag -a V<X.Y.Z> -m "<changelog>"
git push origin <branche_courante>
git push origin V<X.Y.Z>
```

### 7 — Release GitHub via API (Windows Credential Manager)

Récupérer le token depuis le Credential Manager Windows, puis appeler l'API :

```powershell
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public struct WCRED {
    public uint Flags; public uint Type;
    [MarshalAs(UnmanagedType.LPWStr)] public string TargetName;
    [MarshalAs(UnmanagedType.LPWStr)] public string Comment;
    public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
    public uint CredentialBlobSize; public IntPtr CredentialBlob;
    public uint Persist; public uint AttributeCount; public IntPtr Attributes;
    [MarshalAs(UnmanagedType.LPWStr)] public string TargetAlias;
    [MarshalAs(UnmanagedType.LPWStr)] public string UserName;
}
public class WC {
    [DllImport("advapi32.dll", EntryPoint="CredReadW", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern bool CredRead(string target, int type, int flag, out IntPtr ptr);
    [DllImport("advapi32.dll")] public static extern void CredFree(IntPtr buf);
}
"@ -ErrorAction SilentlyContinue

$ptr = [IntPtr]::Zero
[WC]::CredRead("git:https://github.com", 1, 0, [ref]$ptr) | Out-Null
$cs = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptr, [Type][WCRED])
$token = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($cs.CredentialBlob, $cs.CredentialBlobSize / 2)
[WC]::CredFree($ptr)

$headers = @{
    Authorization          = "Bearer $token"
    Accept                 = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}
```

**Créer la release** (POST `/releases`) avec le changelog comme `body`.
- Éviter les backticks et caractères spéciaux dans le body JSON — utiliser des apostrophes simples ou les échapper.
- `target_commitish` = branche courante (`git branch --show-current`)

### 8 — Déclencher GitHub Actions (workflow_dispatch)

Après création de la release, déclencher le build CI via API :

```powershell
$body = @{ ref = "V<X.Y.Z>" } | ConvertTo-Json
$bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
Invoke-RestMethod `
    -Uri "https://api.github.com/repos/jordane45/wslManagerV2/actions/workflows/build.yml/dispatches" `
    -Method Post -Headers $headers -Body $bytes -ContentType "application/json; charset=utf-8"
```

Le workflow va builder le ZIP portable et l'attacher à la release automatiquement.

### 9 — Rapport final

```
## Release V<X.Y.Z> créée

Tag      : V<X.Y.Z>
Commits  : N commits depuis V<précédent>
Push     : ✅ origin/V<X.Y.Z>
Release  : ✅ https://github.com/jordane45/wslManagerV2/releases/tag/V<X.Y.Z>
Build CI : ✅ workflow_dispatch déclenché → ZIP portable en cours
Suivre   : https://github.com/jordane45/wslManagerV2/actions
```

## Règles importantes

- **Jamais** `--install-location` avec `wsl --install` (argument invalide)
- **Jamais** committer `.claude/settings.local.json`
- **Jamais** tagger si `flutter analyze` retourne des erreurs
- **Jamais** `git push --force` sur un tag existant
- Si le tag existe déjà sur le remote : arrêter et avertir
- Tags annotés (`-a`) uniquement, jamais de tags légers
- Format de tag du projet : `V<major>.<minor>.<patch>` (majuscule V)
- Le `gh` CLI n'est **pas installé** → toujours utiliser l'API REST GitHub via `Invoke-RestMethod`
- `flutter run -d windows` et `flutter build` nécessitent VS Build Tools dans le PATH — ne pas tenter de builder localement, laisser le CI s'en charger
