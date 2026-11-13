// Les 32 animations d'exercices, portées depuis les animations web de la séance A, B, C, posture,
// échauffement et variantes. Chaque fonction ajoute à la scène ce qui est visible à l'instant t.
//
// Repères : la scène fait 1920 × 1080, le sol est à y = 878, le tapis va de x = 860 à 1800.
// Les angles suivent la convention de stage.dart : 0° = droite, 90° = bas, -90° = haut.
import 'dart:math' as math;
import 'dart:ui';

import 'stage.dart';

typedef AnimFn = void Function(Scene s, double t);

class AnimSpec {
  final AnimFn fn;
  final double? loop; // les maintiens (étirements, chaise) rejouent leur mise en place toutes les [loop] secondes
  const AnimSpec(this.fn, {this.loop});
}

double _ang(Offset a, Offset b) => ang(a, b);

// ---------------------------------------------------------------------------------------------
// Échauffement
// ---------------------------------------------------------------------------------------------
void _moulinets(Scene s, double t) {
  s.room();
  final a = 90 - 360 * math.max(0.0, t - .2) / 1.6;
  final b = computeBody(Pose(hip: const Offset(1330, 560), torso: -90, neck: 4, thigh: 90, shin: 90, foot: 0, fthigh: 92, fshin: 90, ffoot: 0, up: a, fore: a, fup: a - 14, ffore: a - 14));
  // le cercle que décrit la main
  final orbit = <Offset>[for (var i = 0; i <= 72; i++) at(b.sh, i * 5.0, 212)];
  s.stroke(orbit, Ink.accent, 5, dash: [4, 20], opacity: .55 * clamp01((t - .4) / .5));
  s.figure(b);
  s.zone(b.sh, t, 44, 44);
}

void _genoux(Scene s, double t) {
  s.room();
  final sv = math.sin(2 * math.pi * math.max(0.0, t - .2) / .9);
  final k1 = math.max(0.0, sv), k2 = math.max(0.0, -sv);
  final hip = Offset(1330, 560 - 10 * sv.abs());
  final sw = 38 * sv;
  final b = computeBody(Pose(
      hip: hip, torso: -88, neck: 4,
      thigh: lerp(90, 2, k1), shin: lerp(90, 96, k1), foot: lerp(0, 30, k1),
      fthigh: lerp(90, 2, k2), fshin: lerp(90, 96, k2), ffoot: lerp(0, 30, k2),
      up: 90 + sw, fore: sw, fup: 90 - sw, ffore: -sw));
  s.figure(b);
  s.zone(mid(b.hip, b.knee, .5), t, 80, 36, _ang(b.hip, b.knee));
}

void _squatLibre(Scene s, double t) {
  s.room();
  final p = cycle(t, 1.9, .2);
  final thigh = lerp(90, 14, p), shin = lerp(90, 112, p), torso = lerp(-87, -60, p);
  const ankle = Offset(1330, 858);
  final hip = at(at(ankle, shin + 180, L.shin), thigh + 180, L.thigh);
  final arm = lerp(92, -4, eio(p));
  final b = computeBody(Pose(hip: hip, torso: torso, neck: 6, thigh: thigh, shin: shin, foot: 0, up: arm, fore: arm, fup: arm + 4, ffore: arm + 4));
  s.figure(b);
  s.zone(mid(b.hip, b.knee, .5), t, 92, 40, _ang(b.hip, b.knee));
  s.arrow(const Offset(1600, 600), t, 1.9, rise: false);
}

// ---------------------------------------------------------------------------------------------
// Séance A
// ---------------------------------------------------------------------------------------------
void _squat(Scene s, double t) {
  s.room();
  final p = cycle(t, 1.9, .2);
  final thigh = lerp(90, 14, p), shin = lerp(90, 112, p), torso = lerp(-87, -60, p);
  const ankle = Offset(1330, 858);
  final hip = at(at(ankle, shin + 180, L.shin), thigh + 180, L.thigh);
  final b = computeBody(Pose(hip: hip, torso: torso, neck: 6, thigh: thigh, shin: shin, foot: 0,
      up: 100 + (torso + 87) * .6, fore: -48 + (torso + 87) * .9, fthigh: thigh, fshin: shin));
  s.figure(b, prop: goblet);
  s.zone(mid(b.hip, b.knee, .5), t, 92, 40, _ang(b.hip, b.knee));
  s.arrow(const Offset(1560, 600), t, 1.9, rise: false);
}

void _pompes(Scene s, double t) {
  s.room();
  final p = cycle(t, 1.9, .2);
  const knee = Offset(1110, 846);
  final body = lerp(-38, -13, p);
  final hip = at(knee, body, L.thigh), sh = at(hip, body, L.torso);
  final arm = ik(sh, const Offset(1398, 850), L.up, L.fore, 'back');
  final far = ik(sh, const Offset(1386, 850), L.up, L.fore, 'back');
  final b = computeBody(Pose(hip: hip, torso: body, neck: 4, thigh: body + 180, shin: 186, foot: 228, fshin: 184, ffoot: 226,
      up: arm.up, fore: arm.fore, fup: far.up, ffore: far.fore));
  s.figure(b);
  s.zone(at(mid(hip, sh, .8), body + 90, 20), t, 62, 32, body);
  s.arrow(const Offset(1560, 560), t, 1.9, rise: false);
}

void _rowing(Scene s, double t) {
  s.room();
  bench(s, 980, 1470, 720);
  final p = cycle(t, 2, .2);
  const hip = Offset(1150, 566);
  final torso = -4 + 2 * p, sh = at(hip, torso, L.torso);
  final farArm = ik(sh, const Offset(1335, 722), L.up, L.fore, 'down');
  final leg = ik(hip, const Offset(1112, 858), L.thigh, L.shin, 'up');
  final b = computeBody(Pose(hip: hip, torso: torso, neck: 8, thigh: leg.up, shin: leg.fore, foot: 0,
      up: lerp(92, 200, p), fore: lerp(90, 96, p), fup: farArm.up, ffore: farArm.fore, fthigh: 90, fshin: 180, ffoot: 150));
  s.figure(b, prop: dumbbell);
  final a = _ang(b.hip, b.sh);
  s.zone(at(mid(b.hip, b.sh, .62), a - 90, 24), t, 100, 36, a);
  s.arrow(const Offset(1470, 600), t, 2, rise: true);
}

void _militaire(Scene s, double t) {
  s.room();
  const cx = 1330.0;
  final p = eio(cycle(t, 2, .2));
  frontBody(s, cx);
  for (final side in [-1.0, 1.0]) {
    final sh = Offset(cx + side * 58, 410);
    final h = Offset(cx + side * lerp(172, 84, p), lerp(300, 204, p));
    final a = ik(sh, h, L.up, L.fore, side > 0 ? 'fwd' : 'back');
    final e = at(sh, a.up, L.up);
    s.stroke([sh, e, h], Ink.main, 30, tag: 'arm');
    dbFront(s, h, 0, false);
  }
  s.zone(const Offset(cx - 64, 410), t, 42, 42);
  s.zone(const Offset(cx + 64, 410), t, 42, 42);
  s.arrow(const Offset(1690, 300), t, 2, rise: true);
}

void _curl(Scene s, double t) {
  s.room();
  final p = eio(cycle(t, 2, .2)), fore = lerp(86, -68, p);
  final b = computeBody(Pose(hip: const Offset(1330, 560), torso: -90, neck: 4, thigh: 90, shin: 90, foot: 0, fthigh: 92, fshin: 90, ffoot: 0,
      up: 93, fore: fore, fup: 96, ffore: fore - 4));
  s.figure(b, prop: dumbbell, farProp: dumbbell);
  final a = _ang(b.sh, b.elbow);
  s.zone(at(mid(b.sh, b.elbow, .55), a - 90, 12), t, 60, 30, a);
  s.arrow(const Offset(1500, 520), t, 2, rise: true);
}

void _planche(Scene s, double t) {
  s.room();
  const a = -10.0, sh = Offset(1500, 734);
  final breath = math.sin(2 * math.pi * t / 1.6);
  final hip = at(sh, a + 180, L.torso), body = a + 180 + breath * .25;
  final b = computeBody(Pose(hip: hip, torso: a - breath * .25, neck: -6, thigh: body, shin: body, foot: 74,
      up: 90, fore: 0, fup: 90, ffore: -2, fthigh: body - .6, fshin: body - .6, ffoot: 76));
  s.stroke(const [Offset(995, 753), Offset(1590, 648)], Ink.accent, 6, dash: [4, 22], opacity: eo(seg(t, .6, 1.2)) * (.75 + .25 * math.sin(t * 3)));
  s.figure(b);
  final g = _ang(b.hip, b.sh);
  s.zone(at(mid(b.hip, b.sh, .42), g + 90, 18), t, 95, 32, g);
}

void _mollets(Scene s, double t) {
  s.room();
  final p = eio(cycle(t, 1.8, .2));
  const toe = Offset(1380, 860);
  final foot = lerp(0, 48, p), ankle = at(toe, foot + 180, L.foot);
  final hip = Offset(ankle.dx - 4, ankle.dy - L.shin - L.thigh);
  final b = computeBody(Pose(hip: hip, torso: -90, neck: 4, thigh: 90, shin: 91.5, foot: foot, fthigh: 92, fshin: 92, ffoot: foot, up: 93, fore: 91, fup: 96, ffore: 93));
  s.figure(b, prop: dumbbell, farProp: dumbbell);
  s.zone(at(mid(b.knee, b.ankle, .4), 180, 14), t, 62, 28, _ang(b.knee, b.ankle));
  s.arrow(const Offset(1500, 760), t, 1.8, rise: true);
}

// ---------------------------------------------------------------------------------------------
// Séance B
// ---------------------------------------------------------------------------------------------
void _fentes(Scene s, double t) {
  s.room();
  final p = eio(cycle(t, 2, .2));
  final hip = Offset(1310, lerp(612, 706, p));
  final front = ik(hip, const Offset(1462, 858), L.thigh, L.shin, 'fwd');
  final back = ik(hip, Offset(1176, lerp(832, 826, p)), L.thigh, L.shin, 'down');
  final b = computeBody(Pose(hip: hip, torso: -88, neck: 4, thigh: front.up, shin: front.fore, foot: 0, fthigh: back.up, fshin: back.fore, ffoot: 140,
      up: 92, fore: 90, fup: 95, ffore: 92));
  s.figure(b, prop: dumbbell, farProp: dumbbell);
  s.zone(mid(b.hip, b.knee, .5), t, 90, 38, _ang(b.hip, b.knee));
  s.arrow(const Offset(1580, 560), t, 2, rise: false);
}

void _couche(Scene s, double t) {
  s.room();
  final p = eio(cycle(t, 2, .2));
  const hip = Offset(1150, 836);
  final leg = ik(hip, const Offset(1012, 852), L.thigh, L.shin, 'up');
  final up = lerp(166, 270, p), fore = lerp(-60, -90, p);
  final b = computeBody(Pose(hip: hip, torso: 0, neck: 0, thigh: leg.up, shin: leg.fore, foot: 180, fthigh: leg.up - 3, fshin: leg.fore + 2, ffoot: 180,
      up: up, fore: fore, fup: up + 4, ffore: fore + 2));
  s.figure(b, prop: dumbbell, farProp: dumbbell);
  s.zone(at(mid(b.hip, b.sh, .8), -90, 22), t, 66, 30);
  s.arrow(const Offset(1500, 600), t, 2, rise: true);
}

void _rowing2(Scene s, double t) {
  s.room();
  final p = eio(cycle(t, 2, .2));
  const hip = Offset(1240, 620);
  final leg = ik(hip, const Offset(1292, 858), L.thigh, L.shin, 'fwd');
  final fleg = ik(hip, const Offset(1278, 858), L.thigh, L.shin, 'fwd');
  final up = lerp(92, 205, p), fore = lerp(90, 97, p);
  final b = computeBody(Pose(hip: hip, torso: -36, neck: 10, thigh: leg.up, shin: leg.fore, foot: 0, fthigh: fleg.up, fshin: fleg.fore, ffoot: 0,
      up: up, fore: fore, fup: up + 3, ffore: fore + 2));
  s.figure(b, prop: dumbbell, farProp: dumbbell);
  final a = _ang(b.hip, b.sh);
  s.zone(at(mid(b.hip, b.sh, .62), a - 90, 24), t, 100, 36, a);
  s.arrow(const Offset(1540, 640), t, 2, rise: true);
}

/// Bras vus de face, symétriques : le bras droit va de [from] à [to] degrés, le gauche en miroir.
void _frontArms(Scene s, double cx, double shY, double p, double from, double to, double bend, Prop prop) {
  for (final side in [-1.0, 1.0]) {
    final sh = Offset(cx + side * 58, shY);
    final a = side > 0 ? lerp(from, to, p) : lerp(180 - from, 180 - to, p);
    final e = at(sh, a, L.up), h = at(e, side > 0 ? a + bend : a - bend, L.fore);
    s.stroke([sh, e, h], Ink.main, 30, tag: 'arm');
    prop(s, h, 0, false);
  }
}

void _laterales(Scene s, double t) {
  s.room();
  const cx = 1330.0;
  final p = eio(cycle(t, 2, .2));
  frontBody(s, cx);
  _frontArms(s, cx, 410, p, 84, -4, 8, dumbbell);
  s.zone(const Offset(cx - 66, 412), t, 40, 40);
  s.zone(const Offset(cx + 66, 412), t, 40, 40);
  s.arrow(const Offset(1680, 330), t, 2, rise: true);
}

void _dips(Scene s, double t) {
  s.room();
  chair(s, 1000, 1250, 652);
  final p = eio(cycle(t, 2, .2));
  const hand = Offset(1232, 654);
  final sh = Offset(lerp(1246, 1262, p), lerp(444, 548, p)), hip = Offset(sh.dx, sh.dy + L.torso);
  final arm = ik(sh, hand, L.up, L.fore, 'back');
  final leg = ik(hip, const Offset(1424, 852), L.thigh, L.shin, 'up');
  final fleg = ik(hip, const Offset(1410, 852), L.thigh, L.shin, 'up');
  final b = computeBody(Pose(hip: hip, torso: -90, neck: 6, thigh: leg.up, shin: leg.fore, foot: -20, fthigh: fleg.up, fshin: fleg.fore, ffoot: -20,
      up: arm.up, fore: arm.fore));
  s.figure(b);
  final a = _ang(b.sh, b.elbow);
  s.zone(at(mid(b.sh, b.elbow, .5), a + 90, 10), t, 60, 28, a);
  s.arrow(const Offset(1600, 520), t, 2, rise: false);
}

void _crunchs(Scene s, double t) {
  s.room();
  final p = eio(cycle(t, 1.8, .2));
  const hip = Offset(1150, 836);
  final r = lerp(0, -30, p), nk = lerp(0, -10, p);
  final leg = ik(hip, const Offset(1012, 852), L.thigh, L.shin, 'up');
  final fleg = ik(hip, const Offset(1000, 852), L.thigh, L.shin, 'up');
  final b = computeBody(Pose(hip: hip, torso: r, neck: nk, thigh: leg.up, shin: leg.fore, foot: 180, fthigh: fleg.up, fshin: fleg.fore, ffoot: 180,
      up: r, fore: r, fup: r, ffore: r));
  // Mains aux tempes : le coude ressort vers le plafond, la main touche l'arrière de la tête.
  List<Offset> armTo(double dx) {
    final hand = at(b.hd, r + nk + 180, 10 + dx);
    final elbow = at(at(b.hd, r + nk - 90, 58), r + nk + 180, 44 + dx);
    return [b.sh, elbow, hand];
  }

  b.arm = armTo(0);
  b.farArm = armTo(10);
  s.figure(b);
  s.zone(at(mid(hip, b.sh, .5), r - 90, 22), t, 80, 30, r);
  s.arrow(const Offset(1560, 620), t, 1.8, rise: true);
}

void _marche(Scene s, double t) {
  s.room();
  s.rect(1300, 762, 240, 108, Ink.wood, r: 6);
  s.rect(1300, 762, 240, 14, Ink.pad, r: 6);
  final p = eio(cycle(t, 2, .2));
  const toe = Offset(1336, 760);
  final foot = lerp(-28, 46, p), ankle = at(toe, foot + 180, L.foot);
  final hip = Offset(ankle.dx - 4, ankle.dy - L.shin - L.thigh);
  final b = computeBody(Pose(hip: hip, torso: -90, neck: 4, thigh: 90, shin: 91.5, foot: foot, fthigh: 92, fshin: 92, ffoot: foot, up: 93, fore: 91, fup: 96, ffore: 93));
  s.figure(b);
  s.zone(at(mid(b.knee, b.ankle, .4), 180, 14), t, 62, 28, _ang(b.knee, b.ankle));
  s.arrow(const Offset(1620, 600), t, 2, rise: true);
}

// ---------------------------------------------------------------------------------------------
// Séance C
// ---------------------------------------------------------------------------------------------
void _jump(Scene s, double t) {
  s.room();
  final u = t < .2 ? 0.0 : ((t - .2) % 2) / 2;
  var d = 0.0, h = 0.0;
  if (u < .35) {
    d = eio(seg(u, 0, .35));
  } else if (u < .5) {
    d = 1 - eo(seg(u, .35, .5));
  } else if (u < .66) {
    h = math.sin(math.pi * seg(u, .5, .66)) * 120;
  } else if (u < .76) {
    d = .5 * eo(seg(u, .66, .76));
  } else {
    d = .5 * (1 - eio(seg(u, .76, 1)));
  }
  final air = h / 120;
  final thigh = lerp(90, 14, d), shin = lerp(90, 112, d), torso = lerp(-87, -58, d);
  final ankle = Offset(1330, 858 - h);
  final hip = at(at(ankle, shin + 180, L.shin), thigh + 180, L.thigh);
  final up = 95 + 40 * d - 150 * air;
  final b = computeBody(Pose(hip: hip, torso: torso, neck: 6, thigh: thigh, shin: shin, foot: 30 * air, fthigh: thigh, fshin: shin, ffoot: 34 * air,
      up: up, fore: up - 12, fup: up + 6, ffore: up - 6));
  s.figure(b, shadowRx: 160 - 50 * air);
  s.zone(mid(b.hip, b.knee, .5), t, 92, 40, _ang(b.hip, b.knee));
}

void _ecarte(Scene s, double t) {
  s.room(floor: false);
  s.rect(1150, 220, 360, 780, Ink.mat, r: 28);
  s.add(StrokeShape(const [Offset(1186, 236), Offset(1474, 236), Offset(1494, 256), Offset(1494, 964), Offset(1474, 984), Offset(1186, 984), Offset(1166, 964), Offset(1166, 256), Offset(1186, 236)],
      Ink.matLit, 4));
  s.stroke(const [Offset(1300, 610), Offset(1270, 760), Offset(1290, 880)], Ink.main, 40);
  s.stroke(const [Offset(1360, 610), Offset(1390, 760), Offset(1370, 880)], Ink.main, 40);
  s.polygon(const [Offset(1270, 400), Offset(1390, 400), Offset(1374, 612), Offset(1286, 612)], Ink.main, strokeW: 34);
  s.circle(const Offset(1330, 318), 42, Ink.main);
  final p = eio(cycle(t, 2, .2));
  for (final side in [-1.0, 1.0]) {
    final sh = Offset(1330 + side * 66, 420), reach = lerp(34, 205, p);
    final e = Offset(sh.dx + side * reach * .52, sh.dy + lerp(8, 18, p));
    final h = Offset(sh.dx + side * reach, sh.dy + lerp(0, 6, p));
    s.stroke([sh, e, h], Ink.main, 32);
    final sc = lerp(1.3, 1, p);
    s.circle(h, 32 * sc, Ink.accent);
    s.circle(h, 9 * sc, Ink.handle);
  }
  s.zone(const Offset(1330, 460), t, 100, 50);
}

void _oiseau(Scene s, double t) {
  s.room();
  s.ellipse(const Offset(1330, 878), 150, 14, Ink.shade);
  s.stroke(const [Offset(1300, 590), Offset(1282, 730), Offset(1292, 858), Offset(1250, 858)], Ink.main, 38);
  s.stroke(const [Offset(1360, 590), Offset(1378, 730), Offset(1368, 858), Offset(1410, 858)], Ink.main, 38);
  s.polygon(const [Offset(1262, 512), Offset(1398, 512), Offset(1372, 596), Offset(1288, 596)], Ink.far, strokeW: 30);
  final p = eio(cycle(t, 2, .2));
  _frontArms(s, 1330, 520, p, 84, -2, 10, dumbbell);
  s.circle(const Offset(1330, 488), 40, Ink.main, tag: 'head');
  s.zone(const Offset(1330, 548), t, 120, 36);
  s.arrow(const Offset(1690, 400), t, 2, rise: true);
}

void _frontales(Scene s, double t) {
  s.room();
  final p = eio(cycle(t, 2, .2)), a = lerp(92, -2, p);
  final b = computeBody(Pose(hip: const Offset(1300, 560), torso: -90, neck: 4, thigh: 90, shin: 90, foot: 0, fthigh: 92, fshin: 90, ffoot: 0,
      up: a, fore: a + 4, fup: a + 3, ffore: a + 7));
  s.figure(b, prop: dumbbell, farProp: dumbbell);
  s.zone(at(b.sh, 0, 10), t, 44, 40);
  s.arrow(const Offset(1640, 470), t, 2, rise: true);
}

void _triceps(Scene s, double t) {
  s.room();
  final p = eio(cycle(t, 2, .2)), fore = lerp(118, 268, p);
  final b = computeBody(Pose(hip: const Offset(1330, 560), torso: -90, neck: 8, thigh: 90, shin: 90, foot: 0, fthigh: 92, fshin: 90, ffoot: 0,
      up: -84, fore: fore, fup: -88, ffore: fore + 3));
  s.figure(b, prop: dumbbell);
  final a = _ang(b.sh, b.elbow);
  s.zone(at(mid(b.sh, b.elbow, .5), a + 90, 12), t, 60, 28, a);
  s.arrow(const Offset(1560, 250), t, 2, rise: true);
}

void _climbers(Scene s, double t) {
  s.room();
  const a = -14.0, sh = Offset(1450, 638);
  final hip = at(sh, a + 180, L.torso);
  final q = eio(cycle(t, 1.1, .1));
  // k = 0 : jambe tendue, pointe du pied au sol. k = 1 : genou ramené sous la poitrine.
  Ik legAt(double k) => ik(hip, Offset(lerp(1017, 1347, k), lerp(820, 816, k) - 34 * math.sin(math.pi * k)), L.thigh, L.shin, 'fwd');
  final n = legAt(q), f = legAt(1 - q);
  final arm = ik(sh, const Offset(1456, 852), L.up, L.fore, 'back'), farArm = ik(sh, const Offset(1444, 852), L.up, L.fore, 'back');
  final b = computeBody(Pose(hip: hip, torso: a, neck: 6, thigh: n.up, shin: n.fore, foot: lerp(60, 20, q), fthigh: f.up, fshin: f.fore, ffoot: lerp(60, 20, 1 - q),
      up: arm.up, fore: arm.fore, fup: farArm.up, ffore: farArm.fore));
  s.figure(b);
  s.zone(at(mid(hip, b.sh, .42), a + 90, 18), t, 90, 30, a);
}

void _releves(Scene s, double t) {
  s.room();
  final p = eio(cycle(t, 2.2, .2)), l = lerp(185, 268, p);
  final b = computeBody(Pose(hip: const Offset(1330, 836), torso: 0, neck: 0, thigh: l, shin: l, foot: l + 90, fthigh: l - 2, fshin: l - 2, ffoot: l + 88,
      up: 172, fore: 178, fup: 170, ffore: 176));
  s.figure(b);
  s.zone(at(mid(b.hip, b.sh, .3), -90, 22), t, 72, 30);
  s.arrow(const Offset(960, 600), t, 2.2, rise: true);
}

// ---------------------------------------------------------------------------------------------
// Posture et souplesse
// ---------------------------------------------------------------------------------------------
void _superman(Scene s, double t) {
  s.room();
  final u = t < .2 ? 0.0 : ((t - .2) % 2) / 2;
  final p = u < .3 ? eio(u / .3) : (u < .6 ? 1.0 : 1 - eio(clamp01((u - .6) / .3)));
  final torso = lerp(0, -9, p), leg = lerp(180, 191, p), arm = lerp(-2, -16, p);
  final b = computeBody(Pose(hip: const Offset(1200, 838), torso: torso, neck: lerp(4, 0, p), thigh: leg, shin: leg + 1, foot: leg + 6, fthigh: leg - 1, fshin: leg, ffoot: leg + 5,
      up: arm, fore: arm - 2, fup: arm + 2, ffore: arm));
  s.figure(b);
  final a = _ang(b.hip, b.sh);
  s.zone(at(mid(b.hip, b.sh, .28), a - 90, 22), t, 80, 30, a);
}

void _chat(Scene s, double t) {
  s.room();
  final p = eio(cycle(t, 2, .2));
  const h = Offset(1180, 694), sEnd = Offset(1355, 640);
  final vx = sEnd.dx - h.dx, vy = sEnd.dy - h.dy, len = math.sqrt(vx * vx + vy * vy);
  final bend = lerp(58, -40, p);
  final m = Offset((h.dx + sEnd.dx) / 2 + (vy / len) * bend, (h.dy + sEnd.dy) / 2 + (-vx / len) * bend);
  final torso = ang(h, m), midA = ang(m, sEnd);
  final sh = at(at(h, torso, L.torso / 2), midA, L.torso / 2);
  final arm = ik(sh, const Offset(1362, 852), L.up, L.fore, 'fwd'), farArm = ik(sh, const Offset(1350, 852), L.up, L.fore, 'fwd');
  final b = computeBody(Pose(hip: h, torso: torso, midA: midA, neck: lerp(70, -38, p), thigh: 90, shin: 180, foot: 182, fthigh: 92, fshin: 181, ffoot: 183,
      up: arm.up, fore: arm.fore, fup: farArm.up, ffore: farArm.fore));
  s.figure(b);
  s.zone(at(mid(b.hip, b.sh, .5), -90, 34), t, 104, 36, _ang(b.hip, b.sh));
}

void _pecs(Scene s, double t) {
  s.room();
  const door = 1200.0;
  s.rect(1120, 70, 260, 34, Ink.wood, r: 6);
  s.rect(1180, 70, 40, 810, Ink.wood);
  s.rect(1212, 104, 8, 776, Ink.pad);
  final p = hold(t);
  final hip = Offset(lerp(door + 8, door + 70, p), 600), torso = lerp(-90, -82, p);
  final front = ik(hip, const Offset(door + 130, 858), L.thigh, L.shin, 'fwd');
  final back = ik(hip, const Offset(door - 50, 858), L.thigh, L.shin, 'fwd');
  final b = computeBody(Pose(hip: hip, torso: torso, neck: 4, thigh: front.up, shin: front.fore, foot: 0, fthigh: back.up, fshin: back.fore, ffoot: 0, up: 90, fore: 90));
  // L'avant-bras reste collé au montant, coude à hauteur d'épaule.
  List<Offset> armAt(double x) => [b.sh, Offset(x, b.sh.dy + 8), Offset(x, b.sh.dy - 92)];
  b.arm = armAt(door + 10);
  b.farArm = armAt(door - 4);
  s.figure(b);
  s.zone(at(mid(hip, b.sh, .8), torso + 90, 18), t, 56, 34, torso);
  final op = .9 * clamp01((t - .3) / .4) * (1 - .6 * clamp01((t - 1.5) / .4));
  final x = 1500 + 40 * math.min(1.0, p);
  s.stroke([Offset(x - 40, 430), Offset(x + 40, 430)], Ink.accent, 10, opacity: op);
  s.stroke([Offset(x + 16, 406), Offset(x + 40, 430), Offset(x + 16, 454)], Ink.accent, 10, opacity: op);
}

void _psoas(Scene s, double t) {
  s.room();
  final p = hold(t);
  final hip = Offset(lerp(1250, 1306, p), lerp(704, 728, p));
  final drop = math.min(.999, (846 - hip.dy) / L.thigh);
  final back = 180 - math.asin(drop) / rad;
  final front = ik(hip, const Offset(1462, 858), L.thigh, L.shin, 'up');
  final up = lerp(95, -86, math.min(1.0, p));
  final b = computeBody(Pose(hip: hip, torso: lerp(-86, -92, p), neck: 2, thigh: front.up, shin: front.fore, foot: 0, fthigh: back, fshin: 180, ffoot: 182,
      up: up, fore: up - 4, fup: up + 3, ffore: up));
  s.figure(b);
  s.zone(at(b.hip, 20, 12), t, 50, 46);
}

void _ischios(Scene s, double t) {
  s.room();
  final p = hold(t);
  const hip = Offset(1150, 834);
  final torso = lerp(-88, -34, math.min(1.04, p)), sh = at(hip, torso, L.torso);
  final arm = ik(sh, Offset(lerp(1310, 1432, p), lerp(720, 812, p)), L.up, L.fore, 'down');
  final b = computeBody(Pose(hip: hip, torso: torso, neck: lerp(4, 18, p), thigh: 0, shin: 0, foot: -80, fthigh: -1, fshin: 0, ffoot: -82,
      up: arm.up, fore: arm.fore, fup: arm.up - 3, ffore: arm.fore - 2));
  s.figure(b);
  s.zone(at(mid(b.hip, b.knee, .5), 90, 12), t, 92, 26);
}

// ---------------------------------------------------------------------------------------------
// Variantes
// ---------------------------------------------------------------------------------------------
void _marteau(Scene s, double t) {
  s.room();
  final p = eio(cycle(t, 2, .2)), fore = lerp(86, -68, p);
  final b = computeBody(Pose(hip: const Offset(1330, 560), torso: -90, neck: 4, thigh: 90, shin: 90, foot: 0, fthigh: 92, fshin: 90, ffoot: 0,
      up: 93, fore: fore, fup: 96, ffore: fore - 4));
  s.figure(b, prop: hammer, farProp: hammer, propRot: fore, farPropRot: fore - 4);
  final a = _ang(b.sh, b.elbow);
  s.zone(at(mid(b.sh, b.elbow, .55), a - 90, 12), t, 60, 30, a);
  s.arrow(const Offset(1520, 520), t, 2, rise: true);
}

void _chaise(Scene s, double t) {
  s.room();
  s.rect(1100, 96, 56, 784, Ink.wood);
  s.rect(1148, 96, 8, 784, Ink.pad);
  final p = hold(t), m = math.min(1.0, p);
  final hip = Offset(1186, lerp(612, 712, m));
  final leg = ik(hip, const Offset(1340, 858), L.thigh, L.shin, 'fwd');
  final fleg = ik(hip, const Offset(1326, 858), L.thigh, L.shin, 'fwd');
  final b = computeBody(Pose(hip: hip, torso: -90, neck: 4, thigh: leg.up, shin: leg.fore, foot: 0, fthigh: fleg.up, fshin: fleg.fore, ffoot: 0,
      up: lerp(92, 58, m), fore: lerp(90, 12, m), fup: lerp(95, 62, m), ffore: lerp(92, 16, m)));
  s.figure(b);
  s.zone(mid(b.hip, b.knee, .5), t, 84, 36, _ang(b.hip, b.knee));
}

void _classiques(Scene s, double t) {
  s.room();
  final p = cycle(t, 1.9, .2);
  const a0 = Offset(1010, 818);
  final b0 = lerp(-22.5, -8, p);
  final hip = at(a0, b0, L.thigh + L.shin), sh = at(hip, b0, L.torso);
  final arm = ik(sh, const Offset(1450, 850), L.up, L.fore, 'back'), far = ik(sh, const Offset(1438, 850), L.up, L.fore, 'back');
  final b = computeBody(Pose(hip: hip, torso: b0, neck: 4, thigh: b0 + 180, shin: b0 + 180, foot: 74, fthigh: b0 + 180, fshin: b0 + 180, ffoot: 76,
      up: arm.up, fore: arm.fore, fup: far.up, ffore: far.fore));
  s.figure(b);
  s.zone(at(mid(hip, sh, .8), b0 + 90, 20), t, 62, 32, b0);
  s.arrow(const Offset(1600, 560), t, 1.9, rise: false);
}

const Map<String, AnimSpec> exerciseAnims = {
  'moulinets': AnimSpec(_moulinets),
  'genoux': AnimSpec(_genoux),
  'squatlibre': AnimSpec(_squatLibre),
  'squat': AnimSpec(_squat),
  'pompes': AnimSpec(_pompes),
  'rowing': AnimSpec(_rowing),
  'militaire': AnimSpec(_militaire),
  'curl': AnimSpec(_curl),
  'planche': AnimSpec(_planche),
  'mollets': AnimSpec(_mollets),
  'fentes': AnimSpec(_fentes),
  'couche': AnimSpec(_couche),
  'rowing2': AnimSpec(_rowing2),
  'laterales': AnimSpec(_laterales),
  'dips': AnimSpec(_dips),
  'crunchs': AnimSpec(_crunchs),
  'marche': AnimSpec(_marche),
  'jump': AnimSpec(_jump),
  'ecarte': AnimSpec(_ecarte),
  'oiseau': AnimSpec(_oiseau),
  'frontales': AnimSpec(_frontales),
  'triceps': AnimSpec(_triceps),
  'climbers': AnimSpec(_climbers),
  'releves': AnimSpec(_releves),
  'superman': AnimSpec(_superman),
  'chat': AnimSpec(_chat),
  'pecs': AnimSpec(_pecs, loop: 7),
  'psoas': AnimSpec(_psoas, loop: 7),
  'ischios': AnimSpec(_ischios, loop: 7),
  'marteau': AnimSpec(_marteau),
  'chaise': AnimSpec(_chaise, loop: 7),
  'classiques': AnimSpec(_classiques),
};
