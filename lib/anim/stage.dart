// Le moteur des animations : une « scène » de 1920 × 1080 unités (comme les vidéos d'origine)
// où l'on pose une silhouette par angles (0° = vers la droite, 90° = vers le bas, -90° = vers le haut).
//
// Chaque exercice (voir exercise_anims.dart) est une fonction (Scene s, double t) qui ajoute des formes
// à la scène pour l'instant t (en secondes). Le ScenePainter dessine ensuite ces formes.
// Tout est calculé à partir de t : l'animation est « pure », la même image pour le même t.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

// ---------------------------------------------------------------------------------------------
// Couleurs (les mêmes mélanges que les animations web)
// ---------------------------------------------------------------------------------------------
class Ink {
  static const ground = Color(0xFF0F2236);
  static const main = Color(0xFF3DDC97);
  static const second = Color(0xFFF2F5F7);
  static const accent = Color(0xFFFF7A59);
  static Color mix(Color a, double pa, Color b) => Color.lerp(b, a, pa)!; // « a à pa % dans b »
  static final floor = mix(ground, .86, second);
  static final line = mix(main, .40, ground);
  static final mat = mix(accent, .45, ground);
  static final matLit = mix(accent, .70, ground);
  static final far = mix(main, .45, ground);
  static final shade = mix(ground, .60, const Color(0xFF000000));
  static final wood = mix(second, .22, ground);
  static final pad = mix(second, .38, ground);
  static final handle = mix(second, .70, ground);
  static final dots = second.withValues(alpha: 0.10);
}

// ---------------------------------------------------------------------------------------------
// Temps et interpolation
// ---------------------------------------------------------------------------------------------
double clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);
double lerp(double a, double b, double p) => a + (b - a) * p;
double seg(double t, double a, double b) => clamp01((t - a) / (b - a));
double eo(double x) => 1 - math.pow(1 - clamp01(x), 3).toDouble();
double eio(double x) {
  x = clamp01(x);
  return x < .5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2;
}

/// Un aller-retour doux de 0 à 1 puis 0, sur [period] secondes, qui démarre à [t0].
double cycle(double t, double period, [double t0 = 0]) {
  final x = math.max(0.0, t - t0);
  return 0.5 - 0.5 * math.cos(2 * math.pi * x / period);
}

/// Un maintien : l'aller se fait en 1,2 s, puis on reste en place en respirant.
double hold(double t) {
  final a = clamp01((t - 0.3) / 1.2);
  return (a * a * (3 - 2 * a)) * (1 + 0.04 * math.sin(2 * math.pi * math.max(0.0, t - 1.5) / 2.4));
}

// ---------------------------------------------------------------------------------------------
// Géométrie
// ---------------------------------------------------------------------------------------------
const double rad = math.pi / 180;
Offset at(Offset p, double a, double l) => Offset(p.dx + math.cos(a * rad) * l, p.dy + math.sin(a * rad) * l);
Offset mid(Offset a, Offset b, double k) => Offset(a.dx + (b.dx - a.dx) * k, a.dy + (b.dy - a.dy) * k);
double ang(Offset a, Offset b) => math.atan2(b.dy - a.dy, b.dx - a.dx) / rad;

/// Longueurs des segments du corps.
class L {
  static const torso = 175.0, up = 112.0, fore = 100.0, thigh = 152.0, shin = 146.0, foot = 46.0, neck = 64.0;
}

class Ik {
  final double up, fore;
  const Ik(this.up, this.fore);
}

/// Membre à deux segments dont le bout reste posé en [h].
/// [mode] : 'up', 'down', 'fwd' ou 'back' choisit de quel côté plie le coude (ou le genou).
Ik ik(Offset s, Offset h, double l1, double l2, String mode) {
  final dx = h.dx - s.dx, dy = h.dy - s.dy;
  final d = math.min(math.sqrt(dx * dx + dy * dy), l1 + l2 - 0.01);
  final base = math.atan2(dy, dx);
  final a = math.acos(((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)).clamp(-1.0, 1.0));
  Offset pt(double aa) => Offset(s.dx + l1 * math.cos(aa), s.dy + l1 * math.sin(aa));
  final e1 = pt(base - a), e2 = pt(base + a);
  final Offset e;
  switch (mode) {
    case 'up':
      e = e1.dy < e2.dy ? e1 : e2;
    case 'down':
      e = e1.dy > e2.dy ? e1 : e2;
    case 'fwd':
      e = e1.dx > e2.dx ? e1 : e2;
    default:
      e = e1.dx < e2.dx ? e1 : e2;
  }
  return Ik(math.atan2(e.dy - s.dy, e.dx - s.dx) / rad, math.atan2(h.dy - e.dy, h.dx - e.dx) / rad);
}

// ---------------------------------------------------------------------------------------------
// La pose d'une silhouette vue de profil
// ---------------------------------------------------------------------------------------------
class Pose {
  final Offset hip;
  final double torso, neck;
  final double? midA; // angle du haut du dos, pour un dos qui s'arrondit (chat-vache)
  final double thigh, shin, foot, up, fore;
  final double? fthigh, fshin, ffoot, fup, ffore; // membres du côté éloigné (par défaut = côté proche)
  const Pose({
    required this.hip,
    required this.torso,
    this.neck = 0,
    this.midA,
    required this.thigh,
    required this.shin,
    required this.foot,
    required this.up,
    required this.fore,
    this.fthigh,
    this.fshin,
    this.ffoot,
    this.fup,
    this.ffore,
  });
}

class Body {
  final Offset hip, sh, hd;
  final Offset? midPt;
  List<Offset> arm, farArm;
  final List<Offset> leg, farLeg;
  Body(this.hip, this.sh, this.hd, this.midPt, this.arm, this.farArm, this.leg, this.farLeg);
  Offset get elbow => arm[1];
  Offset get hand => arm[2];
  Offset get farHand => farArm[2];
  Offset get knee => leg[1];
  Offset get ankle => leg[2];
}

Body computeBody(Pose p) {
  final hip = p.hip;
  Offset? m;
  Offset sh;
  if (p.midA == null) {
    sh = at(hip, p.torso, L.torso);
  } else {
    m = at(hip, p.torso, L.torso / 2);
    sh = at(m, p.midA!, L.torso / 2);
  }
  final ta = p.midA ?? p.torso;
  final hd = at(sh, ta + p.neck, L.neck);
  List<Offset> limb(Offset base, double a1, double l1, double a2, double l2, [double? a3, double? l3]) {
    final j = at(base, a1, l1), e = at(j, a2, l2);
    return [base, j, e, if (a3 != null) at(e, a3, l3!)];
  }

  final arm = limb(sh, p.up, L.up, p.fore, L.fore);
  final farArm = limb(sh, p.fup ?? p.up, L.up, p.ffore ?? p.fore, L.fore);
  final leg = limb(hip, p.thigh, L.thigh, p.shin, L.shin, p.foot, L.foot);
  final farLeg = limb(hip, p.fthigh ?? p.thigh, L.thigh, p.fshin ?? p.shin, L.shin, p.ffoot ?? p.foot, L.foot);
  return Body(hip, sh, hd, m, arm, farArm, leg, farLeg);
}

// ---------------------------------------------------------------------------------------------
// Les formes de la scène
// ---------------------------------------------------------------------------------------------
abstract class Shape {
  void paint(Canvas c);
}

/// Un trait épais à bouts ronds (membre, buste…). [tag] et [halfWidth] servent aux tests (« rien sous le sol »).
class StrokeShape extends Shape {
  final List<Offset> pts;
  final Offset? ctrl; // point de contrôle : la ligne devient une courbe (dos arrondi)
  final Color color;
  final double width;
  final String tag;
  final List<double>? dash;
  final double opacity;
  StrokeShape(this.pts, this.color, this.width, {this.ctrl, this.tag = '', this.dash, this.opacity = 1});
  double get halfWidth => width / 2;
  @override
  void paint(Canvas c) {
    if (pts.length < 2 || opacity <= 0) return;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    if (ctrl != null && pts.length == 2) {
      path.quadraticBezierTo(ctrl!.dx, ctrl!.dy, pts[1].dx, pts[1].dy);
    } else {
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
    }
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.drawPath(dash == null ? path : _dashed(path, dash!), paint);
  }
}

Path _dashed(Path src, List<double> dash) {
  final out = Path();
  for (final m in src.computeMetrics()) {
    var d = 0.0;
    var i = 0;
    while (d < m.length) {
      final len = dash[i % dash.length];
      if (i.isEven) out.addPath(m.extractPath(d, math.min(d + len, m.length)), Offset.zero);
      d += len;
      i++;
    }
  }
  return out;
}

/// Une forme pleine, éventuellement déplacée/tournée (haltère au bout de la main, etc.).
class FillShape extends Shape {
  final Path path;
  final Color color;
  final double opacity;
  FillShape(this.path, this.color, {this.opacity = 1});
  @override
  void paint(Canvas c) {
    if (opacity <= 0) return;
    c.drawPath(path, Paint()..color = color.withValues(alpha: color.a * opacity));
  }
}

/// Un cercle plein. [tag] = 'head' pour les tests.
class CircleShape extends Shape {
  final Offset center;
  final double r;
  final Color color;
  final String tag;
  CircleShape(this.center, this.r, this.color, {this.tag = ''});
  @override
  void paint(Canvas c) => c.drawCircle(center, r, Paint()..color = color);
}

/// Le halo orange qui montre le muscle travaillé.
class ZoneShape extends Shape {
  final Offset center;
  final double rx, ry, rot, opacity;
  ZoneShape(this.center, this.rx, this.ry, this.rot, this.opacity);
  @override
  void paint(Canvas c) {
    if (opacity <= 0) return;
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(rot * rad);
    c.scale(rx / 50, ry / 50);
    final shader = Gradient.radial(Offset.zero, 50, [
      Ink.accent.withValues(alpha: .9 * opacity),
      Ink.accent.withValues(alpha: .45 * opacity),
      Ink.accent.withValues(alpha: 0),
    ], [0, .5, 1]);
    c.drawCircle(Offset.zero, 50, Paint()..shader = shader);
    c.restore();
  }
}

/// Une matrice de déplacement + rotation pour Path.transform.
Float64List _tr(Offset o, double rotDeg, [double scale = 1]) {
  final c = math.cos(rotDeg * rad) * scale, s = math.sin(rotDeg * rad) * scale;
  return Float64List.fromList([c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, o.dx, o.dy, 0, 1]);
}

/// Un accessoire tenu en main, dessiné autour de (0,0) puis placé à la main.
typedef Prop = void Function(Scene s, Offset at, double rot, bool far);

class Scene {
  final List<Shape> shapes = [];

  void add(Shape s) => shapes.add(s);

  /// Rectangle arrondi, avec déplacement/rotation facultatifs.
  void rect(double x, double y, double w, double h, Color c, {double r = 0, Offset origin = Offset.zero, double rot = 0, double scale = 1, double opacity = 1}) {
    var p = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)));
    if (origin != Offset.zero || rot != 0 || scale != 1) p = p.transform(_tr(origin, rot, scale));
    add(FillShape(p, c, opacity: opacity));
  }

  void circle(Offset c, double r, Color col, {String tag = ''}) => add(CircleShape(c, r, col, tag: tag));

  void ellipse(Offset c, double rx, double ry, Color col) =>
      add(FillShape(Path()..addOval(Rect.fromCenter(center: c, width: rx * 2, height: ry * 2)), col));

  void stroke(List<Offset> pts, Color c, double w, {Offset? ctrl, String tag = '', List<double>? dash, double opacity = 1}) =>
      add(StrokeShape(pts, c, w, ctrl: ctrl, tag: tag, dash: dash, opacity: opacity));

  void polygon(List<Offset> pts, Color c, {double strokeW = 0}) {
    final p = Path()..addPolygon(pts, true);
    add(FillShape(p, c));
    if (strokeW > 0) add(StrokeShape([...pts, pts.first], c, strokeW));
  }

  /// La salle : fond pointillé, sol, tapis.
  void room({bool floor = true}) {
    add(_DotsShape());
    if (!floor) return;
    rect(0, 880, 1920, 200, Ink.floor);
    rect(0, 878, 1920, 4, Ink.line);
    rect(860, 868, 940, 20, Ink.mat, r: 10);
    rect(860, 868, 940, 6, Ink.matLit, r: 3);
  }

  /// Le halo du muscle : apparaît vers 0,6 s puis pulse doucement.
  void zone(Offset c, double t, double rx, double ry, [double rot = 0]) {
    final a = clamp01((t - 0.6) / 0.5), fade = 1 - math.pow(1 - a, 3).toDouble();
    final op = fade * (0.78 + 0.22 * math.sin(2 * math.pi * math.max(0.0, t - 0.6) / 1.6));
    add(ZoneShape(c, rx, ry, rot, op));
  }

  /// La flèche orange qui montre le sens du mouvement. [rise] : la flèche monte quand le mouvement monte.
  void arrow(Offset pos, double t, double period, {bool rise = true}) {
    final v = math.sin(2 * math.pi * math.max(0.0, t - 0.2) / period);
    final pointsDown = (v >= 0) != rise;
    final op = v.abs() * eo(seg(t, 0.3, 0.7));
    final pts = pointsDown
        ? [Offset(pos.dx, pos.dy - 50), Offset(pos.dx, pos.dy + 40)]
        : [Offset(pos.dx, pos.dy + 50), Offset(pos.dx, pos.dy - 40)];
    final tip = pts[1], dir = pointsDown ? -1.0 : 1.0;
    stroke(pts, Ink.accent, 10, opacity: op);
    stroke([Offset(tip.dx - 24, tip.dy + 24 * dir), tip, Offset(tip.dx + 24, tip.dy + 24 * dir)], Ink.accent, 10, opacity: op);
  }

  /// Dessine la silhouette (ombre, membres éloignés, buste, membres proches, tête, accessoires).
  void figure(Body b, {Prop? prop, Prop? farProp, double propRot = 0, double farPropRot = 0, double shadowRx = 160, double floorY = 878}) {
    ellipse(Offset(b.hip.dx, floorY), shadowRx, 14, Ink.shade);
    stroke(b.farLeg, Ink.far, 36, tag: 'farleg');
    stroke(b.farArm, Ink.far, 30, tag: 'fararm');
    if (farProp != null) farProp(this, b.farHand, farPropRot, true);
    stroke([b.hip, b.sh], Ink.main, 54, ctrl: b.midPt, tag: 'torso');
    stroke(b.leg, Ink.main, 38, tag: 'leg');
    circle(b.hd, 38, Ink.main, tag: 'head');
    stroke(b.arm, Ink.main, 32, tag: 'arm');
    if (prop != null) prop(this, b.hand, propRot, false);
  }
}

class _DotsShape extends Shape {
  @override
  void paint(Canvas c) {
    final p = Paint()..color = Ink.dots;
    for (double y = 24; y < 880; y += 48) {
      for (double x = 24; x < 1920; x += 48) {
        c.drawCircle(Offset(x, y), 2.5, p);
      }
    }
  }
}

// ---------------------------------------------------------------------------------------------
// Accessoires
// ---------------------------------------------------------------------------------------------

/// Haltère vu de profil : le disque de face.
void dumbbell(Scene s, Offset at, double rot, bool far) {
  s.circle(at, 32, far ? Ink.far : Ink.accent);
  s.add(_RingShape(at, 22, Ink.ground.withValues(alpha: .3), 4));
  s.circle(at, 9, Ink.handle);
}

class _RingShape extends Shape {
  final Offset c;
  final double r, w;
  final Color color;
  _RingShape(this.c, this.r, this.color, this.w);
  @override
  void paint(Canvas canvas) => canvas.drawCircle(c, r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = color);
}

/// Haltère tenu vertical contre la poitrine (squat goblet).
void goblet(Scene s, Offset at, double rot, bool far) {
  s.rect(-9, -52, 18, 104, Ink.handle, r: 6, origin: at);
  s.rect(-34, -66, 68, 28, Ink.accent, r: 9, origin: at);
  s.rect(-34, 38, 68, 28, Ink.accent, r: 9, origin: at);
}

/// Haltère en prise neutre (curl marteau) : poignée perpendiculaire à l'avant-bras.
void hammer(Scene s, Offset at, double rot, bool far) {
  final c = far ? Ink.far : Ink.accent;
  s.rect(-7, -40, 14, 80, Ink.handle, r: 5, origin: at, rot: rot);
  s.rect(-26, -56, 52, 22, c, r: 8, origin: at, rot: rot);
  s.rect(-26, 34, 52, 22, c, r: 8, origin: at, rot: rot);
}

/// Haltère vu de face, paume vers l'avant (développé militaire).
void dbFront(Scene s, Offset at, double rot, bool far) {
  s.rect(-40, -7, 80, 14, Ink.handle, r: 5, origin: at);
  s.rect(-54, -30, 20, 60, Ink.accent, r: 6, origin: at);
  s.rect(34, -30, 20, 60, Ink.accent, r: 6, origin: at);
}

/// La silhouette vue de face (élévations latérales, développé militaire, oiseau).
void frontBody(Scene s, double cx, {Color torso = Ink.main, double shY = 404, double hipY = 560, double headY = 318, bool headLast = false}) {
  s.ellipse(Offset(cx, 878), 150, 14, Ink.shade);
  s.stroke([Offset(cx - 34, hipY), Offset(cx - 40, 858), Offset(cx - 82, 858)], Ink.main, 38);
  s.stroke([Offset(cx + 34, hipY), Offset(cx + 40, 858), Offset(cx + 82, 858)], Ink.main, 38);
  s.polygon([Offset(cx - 52, shY), Offset(cx + 52, shY), Offset(cx + 36, hipY), Offset(cx - 36, hipY)], torso, strokeW: 30);
  if (!headLast) s.circle(Offset(cx, headY), 40, Ink.main, tag: 'head');
}

/// Un banc ou une chaise vu de profil.
void bench(Scene s, double x0, double x1, double top) {
  s.rect(x0 + 30, top + 20, 22, 868 - top - 20, Ink.wood);
  s.rect(x1 - 52, top + 20, 22, 868 - top - 20, Ink.wood);
  s.rect(x0, top, x1 - x0, 34, Ink.wood, r: 10);
  s.rect(x0 + 6, top, x1 - x0 - 12, 12, Ink.pad, r: 6);
}

void chair(Scene s, double x0, double x1, double top) {
  s.rect(x0, top - 210, 26, 868 - top + 210, Ink.wood, r: 8);
  s.rect(x1 - 30, top, 24, 868 - top, Ink.wood);
  s.rect(x0, top, x1 - x0, 30, Ink.wood, r: 8);
  s.rect(x0 + 6, top, x1 - x0 - 12, 10, Ink.pad, r: 5);
}
