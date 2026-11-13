// Toutes les données du programme : exercices, séances, paliers.
// Rien n'est téléchargé : tout est écrit ici, l'app fonctionne donc sans internet.

/// Un exercice. [id] sert aussi de clé pour retrouver son animation (voir anim/exercise_anims.dart).
class Exercise {
  final String id;
  final String name;
  final String zone; // muscle principal, affiché en orange comme dans les animations
  final String tip; // le conseil clé
  const Exercise(this.id, this.name, this.zone, this.tip);
}

const Map<String, Exercise> exercises = {
  // Échauffement
  'moulinets': Exercise('moulinets', 'Moulinets des bras', 'Épaules', 'Bras tendus, de grands cercles vers l’avant puis vers l’arrière.'),
  'genoux': Exercise('genoux', 'Montées de genoux', 'Cardio', 'Sur place, monte les genoux à hauteur de hanches, les bras suivent.'),
  'squatlibre': Exercise('squatlibre', 'Squats sans charge', 'Cuisses', 'Bras tendus devant toi pour l’équilibre, descends à ton rythme.'),
  // Séance A
  'squat': Exercise('squat', 'Squat goblet', 'Cuisses', 'Dos droit, talons au sol, descends comme pour t’asseoir.'),
  'pompes': Exercise('pompes', 'Pompes sur les genoux', 'Pectoraux', 'Mains sous les épaules, coudes vers l’arrière, corps droit.'),
  'rowing': Exercise('rowing', 'Rowing haltère un bras', 'Dos', 'Dos plat, tire l’haltère vers la hanche, coude près du corps.'),
  'militaire': Exercise('militaire', 'Développé militaire', 'Épaules', 'Haltères à hauteur d’oreilles, pousse au-dessus de la tête sans cambrer.'),
  'curl': Exercise('curl', 'Curl biceps', 'Biceps', 'Coudes collés au corps, monte sans balancer le buste.'),
  'planche': Exercise('planche', 'Planche', 'Abdos', 'Corps aligné de la tête aux talons, hanches ni hautes ni basses.'),
  'mollets': Exercise('mollets', 'Montées sur pointes', 'Mollets', 'Monte haut sur la pointe des pieds, redescends lentement.'),
  // Séance B
  'fentes': Exercise('fentes', 'Fentes avant', 'Cuisses', 'Buste droit, le genou avant reste au-dessus de la cheville.'),
  'couche': Exercise('couche', 'Développé couché au sol', 'Pectoraux', 'Dos au sol, pousse vers le plafond sans verrouiller les coudes.'),
  'rowing2': Exercise('rowing2', 'Rowing penché', 'Dos', 'Dos plat et gainé, tire les coudes vers l’arrière.'),
  'laterales': Exercise('laterales', 'Élévations latérales', 'Épaules', 'Coudes légèrement fléchis, monte jusqu’aux épaules, pas plus haut.'),
  'dips': Exercise('dips', 'Dips sur chaise', 'Triceps', 'Coudes vers l’arrière, descends jusqu’à 90°, le dos près de la chaise.'),
  'crunchs': Exercise('crunchs', 'Crunchs', 'Abdos', 'Mains aux tempes, ne tire pas sur la nuque, souffle en montant.'),
  'marche': Exercise('marche', 'Mollets sur une marche', 'Mollets', 'Talons dans le vide, descends bas puis monte haut sur la pointe.'),
  // Séance C
  'jump': Exercise('jump', 'Jump squats', 'Cuisses', 'Descends en squat, saute, puis amortis la réception genoux souples.'),
  'ecarte': Exercise('ecarte', 'Écarté couché au sol', 'Pectoraux', 'Vu de dessus : ouvre les bras en arc, puis referme.'),
  'oiseau': Exercise('oiseau', 'Oiseau', 'Haut du dos', 'Buste penché, dos plat, ouvre les bras comme des ailes.'),
  'frontales': Exercise('frontales', 'Élévations frontales', 'Épaules', 'Bras tendus devant toi jusqu’aux épaules, sans prendre d’élan.'),
  'triceps': Exercise('triceps', 'Extension triceps', 'Triceps', 'Coudes pointés vers le plafond, seuls les avant-bras bougent.'),
  'climbers': Exercise('climbers', 'Mountain climbers', 'Abdos', 'Mains sous les épaules, ramène les genoux vers la poitrine, vite.'),
  'releves': Exercise('releves', 'Relevés de jambes', 'Abdos', 'Bas du dos plaqué au sol, redescends sans toucher le tapis.'),
  // Posture et souplesse
  'superman': Exercise('superman', 'Superman', 'Bas du dos', 'Sur le ventre, décolle bras et jambes, regard vers le sol.'),
  'chat': Exercise('chat', 'Chat-vache', 'Dos', 'Arrondis le dos en expirant, creuse-le en inspirant.'),
  'pecs': Exercise('pecs', 'Étirement des pectoraux', 'Pectoraux', 'Avant-bras contre le cadre d’une porte, avance doucement la poitrine.'),
  'psoas': Exercise('psoas', 'Fente basse', 'Hanches', 'Genou arrière au sol, avance le bassin, buste droit.'),
  'ischios': Exercise('ischios', 'Étirement des ischios', 'Ischios', 'Jambes tendues, penche-toi depuis les hanches, dos long.'),
  // Variantes
  'marteau': Exercise('marteau', 'Curl marteau', 'Biceps', 'Pouces vers le haut, coudes collés, en alternance avec le curl biceps.'),
  'chaise': Exercise('chaise', 'Chaise contre le mur', 'Cuisses', 'Dos plaqué au mur, cuisses parallèles au sol, genoux à 90°.'),
  'classiques': Exercise('classiques', 'Pompes classiques', 'Pectoraux', 'Corps gainé des talons à la tête, coudes vers l’arrière.'),
};

/// Une ligne de séance : quel exercice, combien de séries, et quoi faire à chaque série.
class SessionItem {
  final String exerciseId;
  final int sets;
  final String reps; // texte affiché : « 10 à 15 répétitions », « 30 s »…
  final int? seconds; // effort chronométré (planche, étirements…) ; null = l'utilisateur appuie sur « Terminé »
  const SessionItem(this.exerciseId, {this.sets = 3, required this.reps, this.seconds});
  Exercise get exercise => exercises[exerciseId]!;
}

enum SessionKind { muscu, circuit, posture, warmup, variants }

class SessionDef {
  final String id; // 'A', 'B', 'C', 'P', 'E', 'V'
  final String title;
  final String subtitle;
  final SessionKind kind;
  final List<SessionItem> items;
  const SessionDef(this.id, this.title, this.subtitle, this.kind, this.items);
}

const warmup = SessionDef('E', 'Échauffement', '3 minutes avant chaque séance', SessionKind.warmup, [
  SessionItem('moulinets', sets: 1, reps: '30 s', seconds: 30),
  SessionItem('genoux', sets: 1, reps: '45 s', seconds: 45),
  SessionItem('squatlibre', sets: 1, reps: '10 répétitions'),
]);

const sessionA = SessionDef('A', 'Séance A', 'Musculation · 7 exercices', SessionKind.muscu, [
  SessionItem('squat', reps: '10 à 15 répétitions'),
  SessionItem('pompes', reps: '8 à 12 répétitions'),
  SessionItem('rowing', reps: '10 à 12 par bras'),
  SessionItem('militaire', reps: '10 à 12 répétitions'),
  SessionItem('curl', reps: '10 à 15 répétitions'),
  SessionItem('planche', reps: '30 s', seconds: 30),
  SessionItem('mollets', reps: '15 à 20 répétitions'),
]);

const sessionB = SessionDef('B', 'Séance B', 'Musculation · 7 exercices', SessionKind.muscu, [
  SessionItem('fentes', reps: '10 par jambe'),
  SessionItem('couche', reps: '10 à 12 répétitions'),
  SessionItem('rowing2', reps: '10 à 12 répétitions'),
  SessionItem('laterales', reps: '12 à 15, charge légère'),
  SessionItem('dips', reps: '8 à 12 répétitions'),
  SessionItem('crunchs', reps: '15 à 20 répétitions'),
  SessionItem('marche', reps: '15 à 20 répétitions'),
]);

const sessionC = SessionDef('C', 'Séance C', 'Circuit · 40 s d’effort, 20 s de repos', SessionKind.circuit, [
  SessionItem('jump', sets: 1, reps: '40 s', seconds: 40),
  SessionItem('ecarte', sets: 1, reps: '40 s', seconds: 40),
  SessionItem('oiseau', sets: 1, reps: '40 s', seconds: 40),
  SessionItem('frontales', sets: 1, reps: '40 s', seconds: 40),
  SessionItem('triceps', sets: 1, reps: '40 s', seconds: 40),
  SessionItem('climbers', sets: 1, reps: '40 s', seconds: 40),
  SessionItem('releves', sets: 1, reps: '40 s', seconds: 40),
]);

const sessionP = SessionDef('P', 'Posture et souplesse', 'Mini-séance de 10 minutes', SessionKind.posture, [
  SessionItem('superman', reps: '10 répétitions, tiens 2 s en haut'),
  SessionItem('chat', sets: 1, reps: '10 cycles lents'),
  SessionItem('pecs', sets: 2, reps: '30 s', seconds: 30),
  SessionItem('psoas', sets: 2, reps: '30 s (un côté par série)', seconds: 30),
  SessionItem('ischios', sets: 2, reps: '30 s', seconds: 30),
]);

const variants = SessionDef('V', 'Variantes', 'Alternances et palier 3', SessionKind.variants, [
  SessionItem('marteau', reps: '10 à 15 répétitions'),
  SessionItem('chaise', reps: '30 à 45 s', seconds: 40),
  SessionItem('classiques', reps: '8 à 12 répétitions'),
]);

const List<SessionDef> allSessions = [warmup, sessionA, sessionB, sessionC, sessionP, variants];

SessionDef sessionById(String id) => allSessions.firstWhere((s) => s.id == id, orElse: () => sessionA);

/// La rotation A → B → C → A.
const Map<String, String> nextInRotation = {'A': 'B', 'B': 'C', 'C': 'A'};

/// Les trois paliers de progression.
class Palier {
  final int level;
  final String name;
  final String what;
  final String passIf;
  const Palier(this.level, this.name, this.what, this.passIf);
}

const List<Palier> paliers = [
  Palier(1, 'La technique', 'Charges légères, 2 séries au lieu de 3 si besoin, pompes sur les genoux.',
      '3 séries complètes, mouvement propre jusqu’à la dernière répétition.'),
  Palier(2, 'La charge', 'Quand tu fais facilement le haut de la fourchette, prends une bouteille plus lourde ou ajoute une série.',
      '12 pompes sur les genoux faciles, planche tenue 45 s.'),
  Palier(3, 'L’intensité', 'Pompes classiques, repos réduit à 40 s, 4 tours pour le circuit de la séance C.',
      'Dernier palier : continue d’augmenter doucement les charges.'),
];

/// Repos entre deux séries selon le palier.
int restSeconds(int palier) => palier >= 3 ? 40 : 60;

/// Nombre de tours du circuit C selon le palier.
int circuitRounds(int palier) => palier >= 3 ? 4 : 3;
