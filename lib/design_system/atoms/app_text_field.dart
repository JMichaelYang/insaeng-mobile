import 'package:material_ui/material_ui.dart';

class AppTextField extends StatefulWidget {
  const new({this.value, this.label, this.hint, this.secure = false, this.onChanged, this.onSubmitted, super.key});

  final String? value;
  final String? label;
  final String? hint;
  final bool secure;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.value;
    if (value != null && value != _controller.text) {
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
      obscureText: widget.secure,
      autocorrect: !widget.secure,
      enableSuggestions: !widget.secure,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
