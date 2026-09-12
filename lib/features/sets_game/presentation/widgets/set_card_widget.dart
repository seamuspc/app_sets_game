import 'package:flutter/material.dart';

import '../../domain/set_card.dart';
import 'set_symbol_painter.dart';

/// A single card on the board: draws [card.count] copies of its symbol,
/// and shows a colored border when [isSelected], when guess feedback
/// ([isCorrectGuess]/[isIncorrectGuess]) applies to it, or when it's part
/// of an opponent's just-claimed set ([isOpponentHighlight]).
class SetCardWidget extends StatelessWidget {
  const SetCardWidget({
    super.key,
    required this.card,
    required this.isSelected,
    required this.isCorrectGuess,
    required this.isIncorrectGuess,
    required this.onTap,
    this.isOpponentHighlight = false,
  });

  final SetCard card;
  final bool isSelected;
  final bool isCorrectGuess;
  final bool isIncorrectGuess;
  final bool isOpponentHighlight;
  final VoidCallback onTap;

  Color get _symbolColor => switch (card.color) {
        CardColor.red => Colors.red.shade600,
        CardColor.green => Colors.green.shade700,
        CardColor.purple => Colors.purple.shade600,
      };

  Color get _borderColor {
    if (isOpponentHighlight) return Colors.deepPurple;
    if (isIncorrectGuess) return Colors.red.shade700;
    if (isCorrectGuess) return Colors.green.shade700;
    if (isSelected) return Colors.blueAccent.shade700;
    return Colors.grey.shade300;
  }

  Color get _backgroundColor {
    if (isOpponentHighlight) return Colors.deepPurple.shade50;
    if (isSelected) return Colors.blue.shade50;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _borderColor,
            width: isSelected || isOpponentHighlight ? 4 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.35),
                blurRadius: 8,
              )
            else
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              card.count,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 2,
                      child: CustomPaint(
                        painter: SetSymbolPainter(
                          shape: card.shape,
                          color: _symbolColor,
                          shading: card.shading,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
