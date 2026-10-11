import 'package:flutter/material.dart';

/// A password box with an eye button to show or hide what was typed.
/// Used on Sign In and Sign Up.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.helperText,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onFieldSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isHidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _isHidden,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _isHidden ? 'Show password' : 'Hide password',
          icon: Icon(
            _isHidden
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _isHidden = !_isHidden),
        ),
      ),
      textInputAction: widget.textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}
