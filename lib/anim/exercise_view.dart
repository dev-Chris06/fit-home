// Le widget qui joue l'animation d'un exercice en boucle.
// Un Ticker (≈ 60 images/s) fait avancer le temps t ; le ScenePainter redessine la scène à chaque image.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'exercise_anims.dart';
import 'stage.dart';

/// La partie de la scène 1920 × 1080 que l'on montre : un carré autour de la silhouette.
const Rect worldView = Rect.fromLTWH(860, 60, 960, 960);

class ScenePainter extends CustomPainter {
  final String exerciseId;
  final double t;
  ScenePainter(this.exerciseId, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Ink.ground);
    final spec = exerciseAnims[exerciseId];
    if (spec == null) return;
    final scene = Scene();
    final tt = spec.loop == null ? t : t % spec.loop!;
    spec.fn(scene, tt);
    final scale = (size.width / worldView.width) < (size.height / worldView.height) ? size.width / worldView.width : size.height / worldView.height;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - worldView.width * scale) / 2, (size.height - worldView.height * scale) / 2);
    canvas.scale(scale);
    canvas.translate(-worldView.left, -worldView.top);
    for (final sh in scene.shapes) {
      sh.paint(canvas);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ScenePainter old) => old.t != t || old.exerciseId != exerciseId;
}

class ExerciseView extends StatefulWidget {
  final String exerciseId;
  final bool playing;
  final BorderRadius radius;
  const ExerciseView(this.exerciseId, {super.key, this.playing = true, this.radius = const BorderRadius.all(Radius.circular(16))});

  @override
  State<ExerciseView> createState() => _ExerciseViewState();
}

class _ExerciseViewState extends State<ExerciseView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _offset = Duration.zero; // temps accumulé avant la dernière pause
  Duration _elapsed = Duration.zero;
  double _t = 1.2; // une pose lisible quand l'animation est en pause

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      _elapsed = d;
      setState(() => _t = (_offset + d).inMicroseconds / 1e6);
    });
    if (widget.playing) _ticker.start();
  }

  @override
  void didUpdateWidget(ExerciseView old) {
    super.didUpdateWidget(old);
    if (old.exerciseId != widget.exerciseId) {
      _offset = Duration.zero;
      if (_ticker.isActive) {
        _ticker.stop();
        _ticker.start();
      }
    }
    if (widget.playing && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.playing && _ticker.isActive) {
      _offset += _elapsed;
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.radius,
      child: RepaintBoundary(
        child: CustomPaint(painter: ScenePainter(widget.exerciseId, _t), child: const SizedBox.expand()),
      ),
    );
  }
}
