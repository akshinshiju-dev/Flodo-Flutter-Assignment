import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders [text] with all occurrences of [highlight] visually emphasized.
/// Used for search result match highlighting.
class HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle? baseStyle;
  final Color highlightColor;
  final int? maxLines;
  final TextOverflow overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.highlight,
    this.baseStyle,
    this.highlightColor = const Color(0xFF6C63FF),
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = highlight.toLowerCase();

    int start = 0;
    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      // Text before match
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      // Highlighted match
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + highlight.length),
          style: GoogleFonts.inter(
            color: highlightColor,
            fontWeight: FontWeight.w700,
            backgroundColor: highlightColor.withValues(alpha: 0.12),
          ),
        ),
      );
      start = idx + highlight.length;
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(
        style: baseStyle ??
            DefaultTextStyle.of(context).style,
        children: spans,
      ),
    );
  }
}
