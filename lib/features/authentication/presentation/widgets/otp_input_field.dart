import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/auth_theme.dart';

/// Modern OTP input with auto-focus, paste, and auto-submit support.
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.length,
    required this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.hasError = false,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool hasError;

  @override
  State<OtpInputField> createState() => OtpInputFieldState();
}

class OtpInputFieldState extends State<OtpInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void clear() {
    _controller.clear();
    setState(() {});
  }

  void focus() => _focusNode.requestFocus();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = _controller.text;
    final digits = code.replaceAll(RegExp(r'\D'), '');

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              onChanged: (value) {
                widget.onChanged?.call(value);
                setState(() {});
                if (value.length == widget.length) {
                  widget.onCompleted(value);
                }
              },
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final boxW = ((constraints.maxWidth - gap * (widget.length - 1)) /
                      widget.length)
                  .clamp(40.0, 58.0);
              final boxH = boxW * 1.25;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(widget.length, (index) {
                  final char = index < digits.length ? digits[index] : '';
                  final isFocused = widget.enabled &&
                      index == digits.length.clamp(0, widget.length);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: boxW,
                    height: boxH,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(AuthSpacing.radiusSm),
                      border: Border.all(
                        color: widget.hasError
                            ? AuthColors.errorText
                            : isFocused
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: isFocused ? 2.5 : 1.2,
                      ),
                    ),
                    child: Text(
                      char.isEmpty ? '•' : char,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: char.isEmpty
                            ? theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.35,
                              )
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
