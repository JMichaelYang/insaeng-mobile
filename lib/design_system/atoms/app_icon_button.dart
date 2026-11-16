import 'package:material_ui/material_ui.dart';

class AppIconButton extends StatelessWidget {
  const new({required this.icon, required this.onPressed, this.tooltip, super.key});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed);
}
