import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 40,
        color: colorScheme.surfaceContainerLowest,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Image.asset(
              'assets/icons/distros/ubuntu.png',
              width: 16,
              height: 16,
              errorBuilder: (_, __, ___) => Icon(
                Icons.terminal,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'WSL Manager',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            _TitleButton(
              icon: Icons.remove,
              onTap: () => windowManager.minimize(),
            ),
            _TitleButton(
              icon: Icons.crop_square,
              onTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            _TitleButton(
              icon: Icons.close,
              isClose: true,
              onTap: () => windowManager.close(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;
  const _TitleButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_TitleButton> createState() => _TitleButtonState();
}

class _TitleButtonState extends State<_TitleButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 40,
          color: _hover
              ? (widget.isClose
                  ? Colors.red
                  : colorScheme.onSurface.withAlpha(20))
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 14,
            color: _hover && widget.isClose
                ? Colors.white
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
