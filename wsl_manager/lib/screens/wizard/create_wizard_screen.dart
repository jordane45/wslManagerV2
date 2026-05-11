import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/instances_provider.dart';
import '../../services/wsl_service.dart';
import '../../services/download_service.dart';
import '../../widgets/custom_title_bar.dart';
import '../../widgets/progress_dialog.dart';
import 'steps/step_source.dart';
import 'steps/step_name.dart';
import 'steps/step_user.dart';
import 'steps/step_password.dart';
import 'steps/step_path.dart';
import 'steps/step_summary.dart';

class WizardState {
  final SourceType sourceType;
  final String? officialDistroName;
  final String? officialDistroUrl;
  final String? localTarPath;
  final String? remoteUrl;
  final String? templateId;
  final String instanceName;
  final String username;
  final String password;
  final String installPath;

  const WizardState({
    this.sourceType = SourceType.online,
    this.officialDistroName,
    this.officialDistroUrl,
    this.localTarPath,
    this.remoteUrl,
    this.templateId,
    this.instanceName = '',
    this.username = '',
    this.password = '',
    this.installPath = '',
  });

  WizardState copyWith({
    SourceType? sourceType,
    String? officialDistroName,
    String? officialDistroUrl,
    String? localTarPath,
    String? remoteUrl,
    String? templateId,
    String? instanceName,
    String? username,
    String? password,
    String? installPath,
  }) {
    return WizardState(
      sourceType: sourceType ?? this.sourceType,
      officialDistroName: officialDistroName ?? this.officialDistroName,
      officialDistroUrl: officialDistroUrl ?? this.officialDistroUrl,
      localTarPath: localTarPath ?? this.localTarPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      templateId: templateId ?? this.templateId,
      instanceName: instanceName ?? this.instanceName,
      username: username ?? this.username,
      password: password ?? this.password,
      installPath: installPath ?? this.installPath,
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
    'Récapitulatif',
  ];

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _state.sourceType == SourceType.localFile
                ? (_state.localTarPath?.isNotEmpty ?? false)
                : _state.sourceType == SourceType.url
                    ? (_state.remoteUrl?.isNotEmpty ?? false)
                    : _state.sourceType == SourceType.template
                        ? (_state.templateId?.isNotEmpty ?? false)
                        : (_state.officialDistroUrl?.isNotEmpty ?? false);
      case 1:
        return _state.instanceName.isNotEmpty;
      case 2:
        return _state.username.isNotEmpty;
      case 3:
        return _state.password.length >= 8;
      case 4:
        return _state.installPath.isNotEmpty;
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
        return StepSummary(state: _state);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _create(BuildContext context) async {
    final s = _state;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Création de l\'instance',
        steps: [
          if (s.sourceType == SourceType.online || s.sourceType == SourceType.url)
            ProgressStep('Téléchargement...'),
          ProgressStep('Import WSL...'),
          ProgressStep('Configuration utilisateur...'),
          ProgressStep('Finalisation'),
        ],
        task: (update) async {
          int idx = 0;
          String tarPath = s.localTarPath ?? '';

          if (s.sourceType == SourceType.online ||
              s.sourceType == SourceType.url) {
            update(idx, StepStatus.running);
            final url = s.sourceType == SourceType.online
                ? s.officialDistroUrl!
                : s.remoteUrl!;
            tarPath = await DownloadService.instance
                .downloadToTemp(url, (_) {});
            update(idx, StepStatus.done);
            idx++;
          }

          update(idx, StepStatus.running);
          await WslService.instance
              .importInstance(s.instanceName, s.installPath, tarPath);
          update(idx, StepStatus.done);
          idx++;

          update(idx, StepStatus.running);
          await WslService.instance
              .setupUser(s.instanceName, s.username, s.password);
          update(idx, StepStatus.done);
          idx++;

          update(idx, StepStatus.running);
          await ref.read(instancesProvider.notifier).refresh();
          update(idx, StepStatus.done);
        },
      ),
    );

    if ((result ?? false) && context.mounted) {
      context.go('/instance/${s.instanceName}');
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
