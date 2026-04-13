import 'package:flutter/material.dart';

class MatchStatusChangeItem extends StatelessWidget {
  const MatchStatusChangeItem({super.key, required this.label, this.minute});

  final String label;
  final int? minute;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    Color? textColor;

    if (lower.contains('buen ') ||
        lower.contains('buena ') ||
        lower.contains('pase clave') ||
        lower.contains('gana posesión') ||
        lower.contains('gana posicion') ||
        lower.contains('recupera posesión') ||
        lower.contains('recupera posesion') ||
        lower.contains('jugada clave') ||
        lower.contains('buena parada') ||
        lower.contains('increíble parada') ||
        lower.contains('increible parada')) {
      textColor = Colors.green;
    }

    if (lower.contains('mal ') ||
        lower.contains('mala ') ||
        lower.contains('pierde ') ||
        lower.contains('gol concedido') ||
        lower.contains('gol en propia')) {
      textColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: minute != null
                ? Text(
                    "${minute!}'",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MatchSubstitutionItem extends StatelessWidget {
  const MatchSubstitutionItem({
    super.key,
    required this.minute,
    required this.inName,
    required this.outName,
  });

  final int minute;
  final String inName;
  final String outName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "$minute'",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    inName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('→'),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    outName,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MatchCardItem extends StatelessWidget {
  const MatchCardItem({
    super.key,
    required this.minute,
    required this.playerName,
    required this.isRed,
  });

  final int minute;
  final String playerName;
  final bool isRed;

  @override
  Widget build(BuildContext context) {
    final Color color = isRed ? Colors.red : Colors.amber;
    final String label = isRed ? 'Tarjeta roja' : 'Tarjeta amarilla';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "$minute'",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.black26, width: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$label a $playerName',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isRed ? Colors.red[800] : Colors.amber[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MatchGoalItem extends StatelessWidget {
  const MatchGoalItem({
    super.key,
    required this.minute,
    required this.isOurGoal,
    required this.isAgainstGoal,
    this.scorerName,
    this.assistName,
  });

  final int minute;
  final bool isOurGoal;
  final bool isAgainstGoal;
  final String? scorerName;
  final String? assistName;

  @override
  Widget build(BuildContext context) {
    if (isOurGoal && scorerName != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                "$minute'",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_soccer, size: 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            scorerName!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (assistName != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              assistName!,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.directions_run, size: 18),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOurGoal ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('Gol', style: TextStyle(color: Colors.white)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "$minute'",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: isOurGoal
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: chip,
            ),
          ),
        ],
      ),
    );
  }
}
