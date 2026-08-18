import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/auth_country.dart';
import '../theme/auth_theme.dart';

class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    required this.country,
    required this.phoneNumber,
    required this.onCountryTap,
    required this.onPhoneChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.showCountrySelector = true,
  });

  final AuthCountry country;
  final String phoneNumber;
  final VoidCallback onCountryTap;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback? onSubmitted;
  final bool autofocus;
  final bool showCountrySelector;

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.phoneNumber);
  }

  @override
  void didUpdateWidget(covariant PhoneInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.phoneNumber != _controller.text &&
        widget.phoneNumber != oldWidget.phoneNumber) {
      _controller.text = widget.phoneNumber;
      _controller.selection = TextSelection.collapsed(
        offset: widget.phoneNumber.length,
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
    final theme = Theme.of(context);

    return Container(
      height: AuthSpacing.inputHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
        border: Border.all(color: const Color(0xFFE6EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadiusDirectional.horizontal(
              start: const Radius.circular(AuthSpacing.radiusMd),
            ),
            child: InkWell(
              onTap: widget.showCountrySelector ? widget.onCountryTap : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AuthSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.country.dialCode,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.showCountrySelector)
                      Icon(
                        Icons.expand_more,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: theme.colorScheme.outlineVariant,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              onChanged: widget.onPhoneChanged,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.country.maxPhoneLength),
              ],
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: 0.6,
              ),
              decoration: InputDecoration(
                hintText: widget.country.phonePlaceholder,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsetsDirectional.only(
                  start: AuthSpacing.md,
                  end: AuthSpacing.md,
                ),
              ),
              onSubmitted: (_) => widget.onSubmitted?.call(),
            ),
          ),
        ],
      ),
    );
  }
}
