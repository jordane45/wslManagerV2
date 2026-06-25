import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/instance_metadata.dart';
import '../../providers/instances_provider.dart';
import '../../services/instance_metadata_service.dart';
import '../../services/wsl_service.dart';
import '../../services/download_service.dart';
import '../../widgets/custom_title_bar.dart';
import '../../widgets/progress_dialog.dart';
import 'steps/step_source.dart';
import 'steps/step_name.dart';
import 'steps/step_user.dart';
import 'steps/step_password.dart';
import 'steps/step_path.dart';
import 'steps/step_tools.dart';
import 'steps/step_summary.dart';

class WizardState {
  final SourceType sourceType;
  final String? officialDistroName;
  final String? officialDistroUrl;
  final String? localTarPath;
  final String? remoteUrl;
  final String? templateId;
  final String instanceName;
  final String description;
  final String username;
  final String password;
  final String installPath;
  final bool useWebDownload;
  final bool installDocker;
  final bool installPodman;
  final String dockerVersion;
  final String podmanVersion;

  const WizardState({
    this.sourceType = SourceType.online,
    this.officialDistroName,
    this.officialDistroUrl,
    this.localTarPath,
    this.remoteUrl,
    this.templateId,
    this.instanceName = '',
    this.description = '',
    this.username = '',
    this.password = '',
    this.installPath = '',
    this.useWebDownload = true,
    this.installDocker = false,
    this.installPodman = false,
    this.dockerVersion = '',
    this.podmanVersion = '',
  });

  WizardState copyWith({
    SourceType? sourceType,
    String? officialDistroName,
    String? officialDistroUrl,
    String? localTarPath,
    String? remoteUrl,
    String? templateId,
    String? instanceName,
    String? description,
    String? username,
    String? password,
    String? installPath,
    bool? useWebDownload,
    bool? installDocker,
    bool? installPodman,
    String? dockerVersion,
    String? podmanVersion,
  }) {
    return WizardState(
      sourceType: sourceType ?? this.sourceType,
      officialDistroName: officialDistroName ?? this.officialDistroName,
      officialDistroUrl: officialDistroUrl ?? this.officialDistroUrl,
      localTarPath: localTarPath ?? this.localTarPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      templateId: templateId ?? this.templateId,
      instanceName: instanceName ?? this.instanceName,
      description: description ?? this.description,
      username: username ?? this.username,
      password: password ?? this.password,
      installPath: installPath ?? this.installPath,
      useWebDownload: useWebDownload ?? this.useWebDownload,
      installDocker: installDocker ?? this.installDocker,
      installPodman: installPodman ?? this.installPodman,
      dockerVersion: dockerVersion ?? this.dockerVersion,
      podmanVersion: podmanVersion ?? this.podmanVersion,
    );
  }
}

enum SourceType { online, localFile, url, template }

class CreateWizardScreen extends ConsumerStatefulWidget {
  const CreateWizardScreen({super.key});

  @override
  ConsumerState<CreateWizardScreen> createState() => _CreateWizardScreenState();
}

class _CreateWizardScreenState extends ConsumerState<CreateWizardScreen> {
  int _step = 0;
  WizardState _state = const WizardState();

  static const _titles = [
    'Source',
    'Nom',
    'Utilisateur',
    'Mot de passe',
    'Emplacement',
    'Outils',
    'Récapitulatif',
  ];

  bool get _canProceed {
    switch (_step) {
      case 0:
        if (_state.sourceType == SourceType.localFile) return _state.localTarPath?.isNotEmpty ?? false;
        if (_state.sourceType == SourceType.url) return _state.remoteUrl?.isNotEmpty ?? false;
        if (_state.sourceType == SourceType.template) return _state.templateId?.isNotEmpty ?? false;
        return _state.useWebDownload
            ? (_state.officialDistroName?.isNotEmpty ?? false)
            : (_state.officialDistroUrl?.isNotEmpty ?? false);
      case 1:
        return _state.useWebDownload && _state.sourceType == SourceType.online
            ? true
            : _state.instanceName.isNotEmpty;
      case 2:
        return _state.username.isNotEmpty;
      case 3:
        return _state.password.length >= 8;
      case 4:
        return _state.useWebDownload && _state.sourceType == SourceType.online
            ? true
            : _state.installPath.isNotEmpty;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CustomTitleBar(),
        Expanded(
          child: Scaffold(
            appBar: AppBar(
              title: Text('Nouvelle instance — ${_titles[_step]}'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.go('/'),
              ),
            ),
            body: Column(
              children: [
                _StepIndicator(current: _step, total: _titles.length),
                Expanded(child: _buildStep()),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_step > 0)
                      OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Précédent'),
                      ),
                    const Spacer(),
                    if (_step < _titles.length - 1)
                      FilledButton(
                        onPressed: _canProceed
                            ? () => setState(() => _step++)
                            : null,
                        child: const Text('Suivant'),
                      )
                    else
                      FilledButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Créer'),
                        onPressed: () => _create(context),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return StepSource(
          state: _state,
          onChanged: (s) => setState(() => _state = s),
        );
      case 1:
        return StepName(
          state: _state,
          onChanged: (s) => setState(() => _state = s),
        );
      case 2:
        return StepUser(
          state: _state,
          onChanged: (s) => setState(() => _state = s),
        );
      case 3:
        return StepPassword(
          state: _state,
          onChanged: (s) => setState(() => _state = s),
        );
      case 4:
        return StepPath(
          state: _state,
          onChanged: (s) => setState(() => _state = s),
        );
      case 5:
        return StepTools(
          state: _state,
          onChanged: (s) => setState(() => _state = s),
        );
      case 6:
        return StepSummary(state: _state);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _create(BuildContext context) async {
    final s = _state;
    final webDownload = s.sourceType == SourceType.online && s.useWebDownload;
    final effectiveName = webDownload ? s.officialDistroName! : s.instanceName;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Création de l\'instance',
        steps: [
          if (webDownload)
            ProgressStep('Installation via WSL (--web-download)...')
          else ...[
            if (s.sourceType == SourceType.online || s.sourceType == SourceType.url)
              ProgressStep('Téléchargement...'),
            ProgressStep('Import WSL...'),
          ],
          ProgressStep('Configuration utilisateur...'),
          if (s.installDocker) ProgressStep('Installation de Docker...'),
          if (s.installPodman) ProgressStep('Installation de Podman...'),
          ProgressStep('Finalisation'),
        ],
        task: (update, setProgress) async {
          int idx = 0;

          if (webDownload) {
            update(idx, StepStatus.running);
            await WslService.instance.installDistroWebDownload(
              s.officialDistroName!,
              onProgress: (p) => setProgress(idx, p),
            );
            update(idx, StepStatus.done);
            idx++;
          } else {
            String tarPath = s.localTarPath ?? '';

            if (s.sourceType == SourceType.online || s.sourceType == SourceType.url) {
              update(idx, StepStatus.running);
              final url = s.sourceType == SourceType.online
                  ? s.officialDistroUrl!
                  : s.remoteUrl!;
              tarPath = await DownloadService.instance
                  .downloadToTemp(url, (p) => setProgress(idx, p));
              update(idx, StepStatus.done);
              idx++;
            }

            update(idx, StepStatus.running);
            await WslService.instance.importInstance(s.instanceName, s.installPath, tarPath);
            update(idx, StepStatus.done);
            idx++;
          }

          update(idx, StepStatus.running);
          await WslService.instance.setupUser(effectiveName, s.username, s.password);
          update(idx, StepStatus.done);
          idx++;

          if (s.installDocker) {
            update(idx, StepStatus.running);
            await WslService.instance.installDockerInInstance(effectiveName, s.username);
            update(idx, StepStatus.done);
            idx++;
          }

          if (s.installPodman) {
            update(idx, StepStatus.running);
            await WslService.instance.installPodmanInInstance(effectiveName, s.username);
            update(idx, StepStatus.done);
            idx++;
          }

          update(idx, StepStatus.running);
          final meta = InstanceMetadata(
            description: s.description.trim(),
            hasDocker: s.installDocker ? true : null,
            hasPodman: s.installPodman ? true : null,
          );
          if (s.description.trim().isNotEmpty || s.installDocker || s.installPodman) {
            await InstanceMetadataService.instance.save(effectiveName, meta);
            InstanceMetadataService.instance.invalidate();
          }
          await ref.read(instancesProvider.notifier).refresh();
          update(idx, StepStatus.done);
        },
      ),
    );

    if ((result ?? false) && context.mounted) {
      context.go('/instance/$effectiveName');
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(total, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done || active
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: done
                        ? Icon(Icons.check,
                            size: 14,
                            color: Theme.of(context).colorScheme.onPrimary)
                        : Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                  ),
                ),
                if (i < total - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
