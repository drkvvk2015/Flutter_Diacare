/// Reusable Form Components
/// 
/// Pre-built form widgets with validation, styling, and consistent behavior.
/// Reduces code duplication and ensures UI consistency across the app.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/ui_constants.dart';
import '../validators/form_validators.dart';

/// Custom text form field with consistent styling
class AppTextFormField extends StatelessWidget {

  const AppTextFormField({
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.textInputAction,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.autovalidateMode,
    super.key,
  });
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function()? onEditingComplete;
  final void Function(String)? onFieldSubmitted;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Theme.of(context).disabledColor.withValues(alpha: 0.1),
      ),
    );
  }
}

/// Email input field with validation
class EmailFormField extends StatelessWidget {

  const EmailFormField({
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.enabled = true,
    this.autovalidateMode,
    super.key,
  });
  final TextEditingController? controller;
  final String? initialValue;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Email',
      hint: 'Enter your email',
      controller: controller,
      initialValue: initialValue,
      validator: Validators.email,
      onChanged: onChanged,
      onSaved: onSaved,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: const Icon(Icons.email_outlined),
      enabled: enabled,
      autovalidateMode: autovalidateMode,
    );
  }
}

/// Password input field with show/hide toggle
class PasswordFormField extends StatefulWidget {

  const PasswordFormField({
    this.label,
    this.controller,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.enabled = true,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autovalidateMode,
    super.key,
  });
  final String? label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final bool enabled;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final AutovalidateMode? autovalidateMode;

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: widget.label ?? 'Password',
      hint: 'Enter your password',
      controller: widget.controller,
      initialValue: widget.initialValue,
      validator: widget.validator ?? Validators.password,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      obscureText: _obscureText,
      prefixIcon: const Icon(Icons.lock_outlined),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autovalidateMode: widget.autovalidateMode,
    );
  }
}

/// Phone number input field with formatting
class PhoneFormField extends StatelessWidget {

  const PhoneFormField({
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.enabled = true,
    this.autovalidateMode,
    super.key,
  });
  final TextEditingController? controller;
  final String? initialValue;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Phone Number',
      hint: 'Enter your phone number',
      controller: controller,
      initialValue: initialValue,
      validator: Validators.phone,
      onChanged: onChanged,
      onSaved: onSaved,
      keyboardType: TextInputType.phone,
      prefixIcon: const Icon(Icons.phone_outlined),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      enabled: enabled,
      autovalidateMode: autovalidateMode,
    );
  }
}

/// Dropdown form field with consistent styling
class AppDropdownFormField<T> extends StatelessWidget {

  const AppDropdownFormField({
    required this.items, this.label,
    this.hint,
    this.value,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    super.key,
  });
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final void Function(T?)? onSaved;
  final String? Function(T?)? validator;
  final bool enabled;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      onSaved: onSaved,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMd),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Theme.of(context).disabledColor.withValues(alpha: 0.1),
      ),
    );
  }
}

/// Date picker form field
class DateFormField extends StatefulWidget {

  const DateFormField({
    this.label,
    this.hint,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.enabled = true,
    this.controller,
    super.key,
  });
  final String? label;
  final String? hint;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(DateTime)? onChanged;
  final void Function(DateTime?)? onSaved;
  final String? Function(DateTime?)? validator;
  final bool enabled;
  final TextEditingController? controller;

  @override
  State<DateFormField> createState() => _DateFormFieldState();
}

class _DateFormFieldState extends State<DateFormField> {
  late TextEditingController _controller;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _controller.text = _formatDate(_selectedDate!);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _controller.text = _formatDate(picked);
      });
      widget.onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: widget.label ?? 'Date',
      hint: widget.hint ?? 'Select date',
      controller: _controller,
      validator: (value) {
        if (widget.validator != null) {
          return widget.validator!(_selectedDate);
        }
        return null;
      },
      readOnly: true,
      enabled: widget.enabled,
      prefixIcon: const Icon(Icons.calendar_today),
      onSaved: (_) => widget.onSaved?.call(_selectedDate),
      suffixIcon: IconButton(
        icon: const Icon(Icons.arrow_drop_down),
        onPressed: widget.enabled ? _selectDate : null,
      ),
    );
  }
}

/// Checkbox form field with label
class CheckboxFormField extends FormField<bool> {
  CheckboxFormField({
    required String label,
    bool super.initialValue = false,
    void Function(bool?)? onChanged,
    super.onSaved,
    super.validator,
    bool enabled = true,
    super.key,
  }) : super(
          builder: (FormFieldState<bool> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: state.value ?? false,
                      onChanged: enabled
                          ? (value) {
                              state.didChange(value);
                              onChanged?.call(value);
                            }
                          : null,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: enabled
                            ? () {
                                final newValue = !(state.value ?? false);
                                state.didChange(newValue);
                                onChanged?.call(newValue);
                              }
                            : null,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: enabled ? null : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(state.context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}

/// Form section header
class FormSectionHeader extends StatelessWidget {

  const FormSectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: UIConstants.spacingXs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Form submit button
class FormSubmitButton extends StatelessWidget {

  const FormSubmitButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: UIConstants.buttonHeightLg,
      child: ElevatedButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusMd),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon),
                    const SizedBox(width: UIConstants.spacingSm),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

