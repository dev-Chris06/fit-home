// Toutes les données du programme : exercices, séances, paliers.
// Rien n'est téléchargé : tout est écrit ici, l'app fonctionne donc sans internet.

/// Les familles d'exercices : servent aux filtres de la bibliothèque et au bouton « Remplacer ».
class Groups {
  static const legs = 'Jambes et fessiers';
  static const upper = 'Haut du corps';
  static const core = 'Abdos et gainage';
  static const cardio = 'Cardio';
  static const mobility = 'Mobilité';
  static const all = [legs, upper, core, cardio, mobility];
}

/// Un exercice. [id] sert aussi de clé pour retrouver son animation (voir anim/exercise_anims.dart).
class Exercise {
  final String id;
  final String name;
  final String zone; // muscle principal, affiché en orange comme dans les animations
  final String tip; // le conseil clé
  final String group; // famille (voir Groups)
  final int level; // palier conseillé : 1 facile, 2 intermédiaire, 3 avancé
  final String reps; // répétitions conseillées quand l'exercice remplace un autre dans une séance
  final int? seconds; // pour les maintiens (gainage, étirements) : durée d'une série
  const Exercise(this.id, this.name, this.zone, this.tip,
      {required this.group, this.level = 1, this.reps = '10 à 15 répétitions', this.seconds});
}

const Map<String, Exercise> exercises = {
  // Échauffement
  'moulinets': Exercise('moulinets', 'Moulinets des bras', 'Épaules', 'Bras tendus, de grands cercles vers l’avant puis vers l’arrière.', group: Groups.mobility, seconds: 30),
  'genoux': Exercise('genoux', 'Montées de genoux', 'Cardio', 'Sur place, monte les genoux à hauteur de hanches, les bras suivent.', group: Groups.cardio, seconds: 45),
  'squatlibre': Exercise('squatlibre', 'Squats sans charge', 'Cuisses', 'Bras tendus devant toi pour l’équilibre, descends à ton rythme.', group: Groups.legs),
  // Séance A
  'squat': Exercise('squat', 'Squat goblet', 'Cuisses', 'Dos droit, talons au sol, descends comme pour t’asseoir.', group: Groups.legs),
  'pompes': Exercise('pompes', 'Pompes sur les genoux', 'Pectoraux', 'Mains sous les épaules, coudes vers l’arrière, corps droit.', group: Groups.upper, reps: '8 à 12 répétitions'),
  'rowing': Exercise('rowing', 'Rowing haltère un bras', 'Dos', 'Dos plat, tire l’haltère vers la hanche, coude près du corps.', group: Groups.upper, reps: '10 à 12 par bras'),
  'militaire': Exercise('militaire', 'Développé militaire', 'Épaules', 'Haltères à hauteur d’oreilles, pousse au-dessus de la tête sans cambrer.', group: Groups.upper, reps: '10 à 12 répétitions'),
  'curl': Exercise('curl', 'Curl biceps', 'Biceps', 'Coudes collés au corps, monte sans balancer le buste.', group: Groups.upper),
  'planche': Exercise('planche', 'Planche', 'Abdos', 'Corps aligné de la tête aux talons, hanches ni hautes ni basses.', group: Groups.core, reps: '30 s', seconds: 30),
  'mollets': Exercise('mollets', 'Montées sur pointes', 'Mollets', 'Monte haut sur la pointe des pieds, redescends lentement.', group: Groups.legs, reps: '15 à 20 répétitions'),
  // Séance B
  'fentes': Exercise('fentes', 'Fentes avant', 'Cuisses', 'Buste droit, le genou avant reste au-dessus de la cheville.', group: Groups.legs, level: 2, reps: '10 par jambe'),
  'couche': Exercise('couche', 'Développé couché au sol', 'Pectoraux', 'Dos au sol, pousse vers le plafond sans verrouiller les coudes.', group: Groups.upper, reps: '10 à 12 répétitions'),
  'rowing2': Exercise('rowing2', 'Rowing penché', 'Dos', 'Dos plat et gainé, tire les coudes vers l’arrière.', group: Groups.upper, level: 2, reps: '10 à 12 répétitions'),
  'laterales': Exercise('laterales', 'Élévations latérales', 'Épaules', 'Coudes légèrement fléchis, monte jusqu’aux épaules, pas plus haut.', group: Groups.upper, reps: '12 à 15, charge légère'),
  'dips': Exercise('dips', 'Dips sur chaise', 'Triceps', 'Coudes vers l’arrière, descends jusqu’à 90°, le dos près de la chaise.', group: Groups.upper, level: 2, reps: '8 à 12 répétitions'),
  'crunchs': Exercise('crunchs', 'Crunchs', 'Abdos', 'Mains aux tempes, ne tire pas sur la nuque, souffle en montant.', group: Groups.core, reps: '15 à 20 répétitions'),
  'marche': Exercise('marche', 'Mollets sur une marche', 'Mollets', 'Talons dans le vide, descends bas puis monte haut sur la pointe.', group: Groups.legs, reps: '15 à 20 répétitions'),
  // Séance C
  'jump': Exercise('jump', 'Jump squats', 'Cuisses', 'Descends en squat, saute, puis amortis la réception genoux souples.', group: Groups.cardio, level: 2, reps: '40 s', seconds: 40),
  'ecarte': Exercise('ecarte', 'Écarté couché au sol', 'Pectoraux', 'Vu de dessus : ouvre les bras en arc, puis referme.', group: Groups.upper, reps: '10 à 12 répétitions'),
  'oiseau': Exercise('oiseau', 'Oiseau', 'Haut du dos', 'Buste penché, dos plat, ouvre les bras comme des ailes.', group: Groups.upper, reps: '12 à 15 répétitions'),
  'frontales': Exercise('frontales', 'Élévations frontales', 'Épaules', 'Bras tendus devant toi jusqu’aux épaules, sans prendre d’élan.', group: Groups.upper, reps: '10 à 12 répétitions'),
  'triceps': Exercise('triceps', 'Extension triceps', 'Triceps', 'Coudes pointés vers le plafond, seuls les avant-bras bougent.', group: Groups.upper, reps: '10 à 12 répétitions'),
  'climbers': Exercise('climbers', 'Mountain climbers', 'Abdos', 'Mains sous les épaules, ramène les genoux vers la poitrine, vite.', group: Groups.cardio, level: 2, reps: '40 s', seconds: 40),
  'releves': Exercise('releves', 'Relevés de jambes', 'Abdos', 'Bas du dos plaqué au sol, redescends sans toucher le tapis.', group: Groups.core, level: 2, reps: '12 à 15 répétitions'),
  // Posture et souplesse
  'superman': Exercise('superman', 'Superman', 'Bas du dos', 'Sur le ventre, décolle bras et jambes, regard vers le sol.', group: Groups.mobility, reps: '10 répétitions, tiens 2 s'),
  'chat': Exercise('chat', 'Chat-vache', 'Dos', 'Arrondis le dos en expirant, creuse-le en inspirant.', group: Groups.mobility, reps: '10 cycles lents'),
  'pecs': Exercise('pecs', 'Étirement des pectoraux', 'Pectoraux', 'Avant-bras contre le cadre d’une porte, avance doucement la poitrine.', group: Groups.mobility, reps: '30 s', seconds: 30),
  'psoas': Exercise('psoas', 'Fente basse', 'Hanches', 'Genou arrière au sol, avance le bassin, buste droit.', group: Groups.mobility, reps: '30 s par côté', seconds: 30),
  'ischios': Exercise('ischios', 'Étirement des ischios', 'Ischios', 'Jambes tendues, penche-toi depuis les hanches, dos long.', group: Groups.mobility, reps: '30 s', seconds: 30),
  // Variantes
  'marteau': Exercise('marteau', 'Curl marteau', 'Biceps', 'Pouces vers le haut, coudes collés, en alternance avec le curl biceps.', group: Groups.upper),
  'chaise': Exercise('chaise', 'Chaise contre le mur', 'Cuisses', 'Dos plaqué au mur, cuisses parallèles au sol, genoux à 90°.', group: Groups.legs, reps: '30 à 45 s', seconds: 40),
  'classiques': Exercise('classiques', 'Pompes classiques', 'Pectoraux', 'Corps gainé des talons à la tête, coudes vers l’arrière.', group: Groups.upper, level: 3, reps: '8 à 12 répétitions'),
  // ---- Ajouts de la version 1.1 ----
  // Abdos et gainage
  'gainage_lateral': Exercise('gainage_lateral', 'Gainage latéral', 'Obliques', 'Coude sous l’épaule, corps aligné, le bras du dessus vers le ciel.',
      group: Groups.core, level: 2, reps: '30 s par côté', seconds: 30),
  'crunch_velo': Exercise('crunch_velo', 'Crunch vélo', 'Abdos', 'Épaules décollées, pédale lentement : coude vers le genou opposé.',
      group: Groups.core, level: 2, reps: '20 répétitions (10 par côté)'),
  'dead_bug': Exercise('dead_bug', 'Dead bug', 'Abdos', 'Bas du dos collé au sol, tends un bras et la jambe opposée, sans toucher le sol.',
      group: Groups.core, reps: '10 par côté'),
  'releve_bassin': Exercise('releve_bassin', 'Relevé de bassin', 'Bas des abdos', 'Genoux vers la poitrine, décolle doucement les fesses sans élan.',
      group: Groups.core, level: 2, reps: '12 à 15 répétitions'),
  'creux': Exercise('creux', 'Position creuse', 'Abdos', 'Bas du dos plaqué, bras et jambes tendus au-dessus du sol, respire calmement.',
      group: Groups.core, level: 3, reps: '20 s', seconds: 20),
  // Jambes et fessiers
  'pont': Exercise('pont', 'Pont fessier', 'Fessiers', 'Pieds à plat, pousse dans les talons et serre les fessiers en haut.',
      group: Groups.legs, reps: '12 à 15 répétitions'),
  'pont_unijambe': Exercise('pont_unijambe', 'Pont sur une jambe', 'Fessiers', 'Une jambe tendue dans l’axe de la cuisse, le bassin reste bien horizontal.',
      group: Groups.legs, level: 3, reps: '8 à 10 par jambe'),
  'sdt': Exercise('sdt', 'Soulevé de terre jambes tendues', 'Ischios', 'Dos plat, recule les fesses, les haltères glissent le long des jambes.',
      group: Groups.legs, level: 2, reps: '10 à 12 répétitions'),
  'ruade': Exercise('ruade', 'Ruade', 'Fessiers', 'À quatre pattes, pousse le talon vers le plafond, le dos reste plat.',
      group: Groups.legs, reps: '12 à 15 par jambe'),
  'sumo': Exercise('sumo', 'Squat sumo', 'Fessiers', 'Pieds écartés et tournés vers l’extérieur, genoux dans l’axe des pieds.',
      group: Groups.legs, reps: '12 à 15 répétitions'),
  // Haut du corps
  'pompes_declinees': Exercise('pompes_declinees', 'Pompes déclinées', 'Haut des pectoraux', 'Pieds sur une chaise solide, corps gainé, coudes vers l’arrière.',
      group: Groups.upper, level: 3, reps: '6 à 10 répétitions'),
  'arnold': Exercise('arnold', 'Développé Arnold', 'Épaules', 'Paumes vers toi devant le visage, tourne en poussant au-dessus de la tête.',
      group: Groups.upper, level: 2, reps: '10 à 12 répétitions'),
  'rowing_inverse': Exercise('rowing_inverse', 'Rowing inversé sous une table', 'Dos', 'Table solide qui ne bascule pas : corps droit, tire la poitrine vers le bord.',
      group: Groups.upper, level: 2, reps: '8 à 12 répétitions'),
  'kickback': Exercise('kickback', 'Kickback triceps', 'Triceps', 'Buste penché, coude fixe contre le corps, tends l’avant-bras vers l’arrière.',
      group: Groups.upper, reps: '12 à 15 répétitions'),
  'pullover': Exercise('pullover', 'Pullover au sol', 'Dos et pectoraux', 'Bras presque tendus, descends l’haltère derrière la tête sans cambrer.',
      group: Groups.upper, reps: '12 à 15 répétitions'),
  // Cardio et mobilité
  'jumping_jacks': Exercise('jumping_jacks', 'Jumping jacks', 'Cardio', 'Ouvre bras et jambes en sautant, atterris sur la pointe des pieds.',
      group: Groups.cardio, reps: '40 s', seconds: 40),
  'burpees': Exercise('burpees', 'Burpees', 'Cardio', 'Squat, mains au sol, pieds en arrière, retour en squat puis saut bras tendus.',
      group: Groups.cardio, level: 3, reps: '40 s', seconds: 40),
  'talons_fesses': Exercise('talons_fesses', 'Talons-fesses', 'Cardio', 'Sur place, ramène les talons vers les fesses, les bras suivent.',
      group: Groups.cardio, reps: '40 s', seconds: 40),
  'quadriceps': Exercise('quadriceps', 'Étirement des quadriceps', 'Quadriceps', 'Sur une jambe, tiens ta cheville derrière toi, genoux côte à côte.',
      group: Groups.mobility, reps: '30 s par jambe', seconds: 30),
  'enfant': Exercise('enfant', 'Posture de l’enfant', 'Bas du dos', 'Assis sur les talons, buste sur les cuisses, bras tendus devant, respire.',
      group: Groups.mobility, reps: '30 s', seconds: 30),
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
