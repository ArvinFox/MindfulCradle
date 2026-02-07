import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

/// Reusable marquee title widget for questionnaire app bars
/// Allows pausing the animation on tap
class QuestionnaireMarqueeTitle extends StatefulWidget {
  final String text;
  final TextStyle style;

  const QuestionnaireMarqueeTitle({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<QuestionnaireMarqueeTitle> createState() =>
      _QuestionnaireMarqueeTitleState();
}

class _QuestionnaireMarqueeTitleState extends State<QuestionnaireMarqueeTitle> {
  bool _pauseMarquee = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _pauseMarquee = !_pauseMarquee),
      child: SizedBox(
        height: 30,
        child: Marquee(
          text: widget.text,
          style: widget.style,
          scrollAxis: Axis.horizontal,
          blankSpace: 60,
          velocity: _pauseMarquee ? 0.001 : 30.0,
          pauseAfterRound: const Duration(seconds: 1),
          startPadding: 10.0,
        ),
      ),
    );
  }
}
