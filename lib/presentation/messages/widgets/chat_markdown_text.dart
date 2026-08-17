import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Renders AI copy with **bold** instead of showing markdown stars.
class ChatMarkdownText extends StatelessWidget {
  const ChatMarkdownText({
    super.key,
    required this.data,
    required this.style,
    this.boldStyle,
  });

  final String data;
  final TextStyle style;
  final TextStyle? boldStyle;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      shrinkWrap: true,
      selectable: false,
      styleSheet: MarkdownStyleSheet(
        p: style.copyWith(height: 1.45),
        strong: boldStyle ?? style.copyWith(fontWeight: FontWeight.w800),
        em: style.copyWith(fontStyle: FontStyle.italic),
        listBullet: style,
        a: style.copyWith(decoration: TextDecoration.underline),
        blockquote: style.copyWith(color: style.color?.withValues(alpha: 0.8)),
      ),
    );
  }
}
