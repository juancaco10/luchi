import '../models/level_config.dart';

/// Pregunta del quiz de "Exploración Nocturna", etiquetada por [topic] para
/// que cada nivel pueda sortear solo de los temas que le tocan (ver
/// `GameCatalog.quizLevels`). Vive separada del catálogo de niveles porque
/// es contenido, no configuración de dificultad.
class QuizQuestion {
  const QuizQuestion({
    required this.topic,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final QuizTopic topic;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

/// Copia con las opciones barajadas, para que la respuesta correcta no esté
/// siempre en el mismo sitio entre partidas.
class ShuffledQuizQuestion {
  ShuffledQuizQuestion({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory ShuffledQuizQuestion.from(QuizQuestion q) {
    final correctText = q.options[q.correctIndex];
    final shuffled = List<String>.from(q.options)..shuffle();
    return ShuffledQuizQuestion(
      text: q.text,
      options: shuffled,
      correctIndex: shuffled.indexOf(correctText),
      explanation: q.explanation,
    );
  }

  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

/// Banco de preguntas, agrupado por tema. Cada tema tiene varias preguntas
/// para que jugar el mismo nivel dos veces no sea siempre idéntico.
abstract final class QuizQuestionBank {
  static List<QuizQuestion> forTopics(List<QuizTopic> topics) =>
      all.where((q) => topics.contains(q.topic)).toList();

  static const all = <QuizQuestion>[
    // ── ¿Qué son? ─────────────────────────────────────────────
    QuizQuestion(
      topic: QuizTopic.queSon,
      text: '¿Qué son las luciérnagas?',
      options: [
        'Escarabajos que brillan en la noche',
        'Aves pequeñas',
        'Peces de río',
        'Arañas voladoras',
      ],
      correctIndex: 0,
      explanation:
          '🪲 Son escarabajos (coleópteros) que producen su propia luz con la bioluminiscencia.',
    ),
    QuizQuestion(
      topic: QuizTopic.queSon,
      text: 'Las luciérnagas son insectos del mismo grupo que las mariquitas.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 0,
      explanation: '🪲 ¡Así es! Ambas son coleópteros (escarabajos).',
    ),
    QuizQuestion(
      topic: QuizTopic.queSon,
      text: '¿En qué momento del día están más activas las luciérnagas?',
      options: [
        'Al mediodía con mucho sol',
        'En la noche y al anochecer',
        'A las 6 de la mañana',
        'Solo cuando llueve',
      ],
      correctIndex: 1,
      explanation: '🪲 Ellas aman la penumbra y la tranquilidad de la noche.',
    ),
    QuizQuestion(
      topic: QuizTopic.queSon,
      text: '¿Cuántas patas tiene una luciérnaga adulta, como todo insecto?',
      options: ['4', '6', '8', '10'],
      correctIndex: 1,
      explanation: '🪲 Seis patas: es lo que la hace un insecto y no otra cosa.',
    ),
    QuizQuestion(
      topic: QuizTopic.queSon,
      text: 'Todas las luciérnagas vuelan, incluso las hembras adultas.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 1,
      explanation:
          '🪲 En varias especies la hembra adulta no tiene alas y brilla desde el suelo.',
    ),
    QuizQuestion(
      topic: QuizTopic.queSon,
      text: '¿Cuánto puede vivir una luciérnaga adulta, en general?',
      options: [
        'Solo unas semanas',
        'Varios años',
        'Un solo día',
        'Toda una década',
      ],
      correctIndex: 0,
      explanation:
          '🪲 La mayor parte de su vida la pasan como larva; de adultas viven poco.',
    ),
    QuizQuestion(
      topic: QuizTopic.queSon,
      text: 'Existen miles de especies distintas de luciérnaga en el mundo.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 0,
      explanation: '🪲 Hay más de 2.000 especies conocidas, cada una con su propio destello.',
    ),

    // ── Su luz (bioluminiscencia) ────────────────────────────
    QuizQuestion(
      topic: QuizTopic.bioluminiscencia,
      text: '¿Por qué brillan las luciérnagas?',
      options: [
        'Para calentarse en el frío',
        'Para comunicarse y encontrar pareja',
        'Porque comen plantas brillantes',
        'Para asustar a los carros',
      ],
      correctIndex: 1,
      explanation: '🪲 Usan destellos como un código de señas para encontrarse.',
    ),
    QuizQuestion(
      topic: QuizTopic.bioluminiscencia,
      text: 'La luz de la luciérnaga es una "luz fría" que casi no produce calor.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 0,
      explanation: '🪲 Casi toda la energía se convierte en luz y muy poca en calor.',
    ),
    QuizQuestion(
      topic: QuizTopic.bioluminiscencia,
      text: '¿Cómo se llama la reacción con la que producen su luz?',
      options: ['Bioluminiscencia', 'Fotosíntesis', 'Electricidad pura', 'Combustión'],
      correctIndex: 0,
      explanation: '🪲 ¡Bioluminiscencia! Mezclan luciferina y oxígeno en su cuerpo.',
    ),
    QuizQuestion(
      topic: QuizTopic.bioluminiscencia,
      text: 'Cada especie de luciérnaga puede tener su propio patrón de destellos.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 0,
      explanation: '🪲 El ritmo y color del parpadeo es como una firma para reconocerse.',
    ),
    QuizQuestion(
      topic: QuizTopic.bioluminiscencia,
      text: '¿En qué parte del cuerpo producen la luz la mayoría de las luciérnagas?',
      options: [
        'En los ojos',
        'En el abdomen',
        'En las antenas',
        'En las alas',
      ],
      correctIndex: 1,
      explanation: '🪲 Tienen un órgano especial en la parte final del abdomen.',
    ),
    QuizQuestion(
      topic: QuizTopic.bioluminiscencia,
      text: 'Algunas larvas de luciérnaga también brillan, no solo los adultos.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 0,
      explanation:
          '🪲 Muchas larvas brillan tenuemente; por eso a veces se les llama "gusanos de luz".',
    ),

    // ── Cómo crecen (ciclo de vida) ───────────────────────────
    QuizQuestion(
      topic: QuizTopic.cicloVida,
      text: '¿Cómo se alimentan y reproducen las luciérnagas?',
      options: [
        'Las larvas comen caracoles y se comunican con destellos para reproducirse',
        'No comen ni se reproducen',
        'Solo beben agua y no se reproducen',
        'Se alimentan de azúcar y ponen huevos en el aire',
      ],
      correctIndex: 0,
      explanation:
          '🪲 Las larvas cazan caracoles y babosas, y los adultos usan su luz para encontrarse.',
    ),
    QuizQuestion(
      topic: QuizTopic.cicloVida,
      text: '¿Dónde viven las larvas de luciérnaga antes de aprender a volar?',
      options: [
        'En las nubes',
        'En la tierra húmeda y bajo hojas secas',
        'En el agua de mar',
        'En los techos de las casas',
      ],
      correctIndex: 1,
      explanation: '🪲 Viven en la tierra húmeda; por eso cuidar el suelo es tan importante.',
    ),
    QuizQuestion(
      topic: QuizTopic.cicloVida,
      text: '¿De qué se alimentan las larvas de luciérnaga en la naturaleza?',
      options: [
        'De fruta fresca',
        'De caracoles y babosas pequeñas',
        'De azúcar',
        'De hojas de plástico',
      ],
      correctIndex: 1,
      explanation: '🪲 ¡Son pequeñas cazadoras que ayudan a controlar caracoles en el jardín!',
    ),
    QuizQuestion(
      topic: QuizTopic.cicloVida,
      text: '¿Cuánto tiempo puede durar la etapa de larva de una luciérnaga?',
      options: ['Un par de horas', 'Uno o dos años', 'Toda la vida', 'Cinco minutos'],
      correctIndex: 1,
      explanation: '🪲 La mayor parte de su vida la pasan siendo larva, creciendo despacio.',
    ),
    QuizQuestion(
      topic: QuizTopic.cicloVida,
      text: 'Ordena el ciclo de vida: huevo, larva, pupa y...',
      options: ['renacuajo', 'adulto', 'crisálida de mariposa', 'semilla'],
      correctIndex: 1,
      explanation: '🪲 Huevo → larva → pupa → adulto: la misma metamorfosis que otros escarabajos.',
    ),
    QuizQuestion(
      topic: QuizTopic.cicloVida,
      text: '¿Dónde suele poner sus huevos la luciérnaga hembra?',
      options: [
        'En el aire, mientras vuela',
        'Cerca del suelo, en tierra húmeda o musgo',
        'Dentro del agua',
        'En la arena del desierto',
      ],
      correctIndex: 1,
      explanation: '🪲 Elige lugares húmedos y protegidos para que las larvas tengan comida cerca.',
    ),
    QuizQuestion(
      topic: QuizTopic.cicloVida,
      text: 'La etapa de pupa es cuando la luciérnaga se transforma antes de ser adulta.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 0,
      explanation: '🪲 Dentro de la pupa el cuerpo se reorganiza por completo, como en las mariposas.',
    ),

    // ── Dónde viven ───────────────────────────────────────────
    QuizQuestion(
      topic: QuizTopic.habitat,
      text: '¿Dónde viven las luciérnagas?',
      options: [
        'En lugares húmedos: bosques, charcas y jardines naturales',
        'En desiertos secos y calurosos',
        'Solo dentro de las casas',
        'En los postes de luz',
      ],
      correctIndex: 0,
      explanation:
          '🪲 Necesitan humedad y vegetación para vivir y que sus larvas crezcan.',
    ),
    QuizQuestion(
      topic: QuizTopic.habitat,
      text: '¿Qué tipo de lugar prefieren las luciérnagas para vivir felices?',
      options: [
        'Desiertos secos',
        'Lugares húmedos, bosques y jardines naturales',
        'Estaciones de tren',
        'Estacionamientos de cemento',
      ],
      correctIndex: 1,
      explanation: '🪲 Necesitan humedad y vegetación tupida para sobrevivir.',
    ),
    QuizQuestion(
      topic: QuizTopic.habitat,
      text: '¿Qué plantas ayudan a crear un hábitat ideal para las luciérnagas?',
      options: [
        'Flores de plástico',
        'Plantas nativas y vegetación natural',
        'Cactus de desierto',
        'Piedras pintadas',
      ],
      correctIndex: 1,
      explanation: '🪲 Las plantas nativas ofrecen sombra, humedad y refugio perfecto.',
    ),
    QuizQuestion(
      topic: QuizTopic.habitat,
      text: 'Un jardín con césped muy corto y sin hojarasca es ideal para luciérnagas.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 1,
      explanation:
          '🪲 Falso: prefieren hojarasca, pasto alto y rincones "desordenados" donde esconderse.',
    ),
    QuizQuestion(
      topic: QuizTopic.habitat,
      text: '¿Por qué el agua limpia cerca (charcas, arroyos) ayuda a las luciérnagas?',
      options: [
        'Porque nadan largas distancias',
        'Porque mantiene húmedo el suelo donde viven sus larvas',
        'Porque beben agua salada',
        'No tiene relación',
      ],
      correctIndex: 1,
      explanation: '🪲 La humedad del suelo es esencial para que las larvas sobrevivan.',
    ),
    QuizQuestion(
      topic: QuizTopic.habitat,
      text: 'Las luciérnagas pueden vivir en casi cualquier continente del planeta.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 0,
      explanation: '🪲 Hay especies en América, Asia, África, Europa y Oceanía.',
    ),
    QuizQuestion(
      topic: QuizTopic.habitat,
      text: '¿Qué elemento del jardín les da refugio durante el día?',
      options: [
        'La hojarasca y la vegetación baja',
        'El techo de las casas',
        'Las piedras al sol',
        'El pavimento',
      ],
      correctIndex: 0,
      explanation: '🪲 Durante el día se esconden del calor y de los depredadores entre las hojas.',
    ),

    // ── Peligros ──────────────────────────────────────────────
    QuizQuestion(
      topic: QuizTopic.amenazas,
      text: '¿Por qué están en peligro las luciérnagas?',
      options: [
        'Por la contaminación lumínica, los pesticidas y la pérdida de su hábitat',
        'Porque brillan demasiado',
        'Porque vuelan muy rápido',
        'Porque comen mucha fruta',
      ],
      correctIndex: 0,
      explanation:
          '🪲 Las luces artificiales, los venenos y destruir sus bosques las están haciendo desaparecer.',
    ),
    QuizQuestion(
      topic: QuizTopic.amenazas,
      text: '¿Qué problema grave afecta a las luciérnagas en la ciudad?',
      options: [
        'El ruido de los carros',
        'La contaminación lumínica (luces artificiales)',
        'La falta de televisión',
        'El exceso de agua limpia',
      ],
      correctIndex: 1,
      explanation: '🪲 La luz artificial opaca su propia luz de noche y las desorienta.',
    ),
    QuizQuestion(
      topic: QuizTopic.amenazas,
      text: 'Las luces de los patios y postes de luz confunden a las luciérnagas de noche.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 0,
      explanation: '🪲 Les dificulta encontrar pareja porque no ven bien sus destellos.',
    ),
    QuizQuestion(
      topic: QuizTopic.amenazas,
      text: '¿Qué porcentaje de especies de luciérnagas está en riesgo de desaparecer?',
      options: ['Alrededor del 5%', 'Alrededor del 20% (1 de cada 5)', 'El 100%', 'Casi 0%'],
      correctIndex: 1,
      explanation: '🪲 1 de cada 5 especies necesita nuestra ayuda urgente.',
    ),
    QuizQuestion(
      topic: QuizTopic.amenazas,
      text: 'Los pesticidas y venenos del jardín son seguros para las luciérnagas.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 1,
      explanation: '🪲 ¡Falso! Los venenos dañan a las larvas que viven en la tierra.',
    ),
    QuizQuestion(
      topic: QuizTopic.amenazas,
      text: '¿Qué pasa cuando se destruyen los bosques y jardines naturales?',
      options: [
        'A las luciérnagas no les afecta',
        'Pierden el hogar donde viven sus larvas',
        'Se vuelven más brillantes',
        'Aprenden a vivir en el cemento',
      ],
      correctIndex: 1,
      explanation: '🪲 Sin hábitat natural, no tienen dónde poner huevos ni alimentarse.',
    ),
    QuizQuestion(
      topic: QuizTopic.amenazas,
      text: 'Secar arroyos y humedales no afecta a las luciérnagas porque ellas vuelan.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 1,
      explanation: '🪲 Falso: sin humedad en el suelo, las larvas no pueden sobrevivir.',
    ),

    // ── Cómo ayudar ───────────────────────────────────────────
    QuizQuestion(
      topic: QuizTopic.conservacion,
      text: '¿Cómo podemos protegerlas?',
      options: [
        'Apagando luces, evitando pesticidas y cuidando la tierra húmeda',
        'Guardándolas en frascos para mirarlas',
        'Encendiendo muchas luces de noche',
        'Cortando todo el pasto',
      ],
      correctIndex: 0,
      explanation:
          '🪲 Protegerlas es darles oscuridad, no usar venenos y cuidar sus lugares húmedos.',
    ),
    QuizQuestion(
      topic: QuizTopic.conservacion,
      text: '¿Qué podemos hacer para ayudarlas?',
      options: [
        'Dejar un rincón del jardín con hojarasca y plantas nativas',
        'Recogerlas y venderlas',
        'Secar las charcas y arroyos',
        'Usar más pesticidas',
      ],
      correctIndex: 0,
      explanation:
          '🪲 Un rincón "silvestre" les da refugio y comida sin ningún esfuerzo extra.',
    ),
    QuizQuestion(
      topic: QuizTopic.conservacion,
      text: '¿Qué podemos hacer desde nuestros hogares?',
      options: [
        'Apagar luces exteriores y mantener un jardín natural',
        'Dejar todas las luces encendidas de noche',
        'Poner venenos para insectos',
        'Secar la tierra de las macetas',
      ],
      correctIndex: 0,
      explanation:
          '🪲 Desde casa, apagar luces innecesarias y cuidar el jardín ya es una gran ayuda.',
    ),
    QuizQuestion(
      topic: QuizTopic.conservacion,
      text: '¿Cuál es la mejor acción que puedes hacer en casa esta noche?',
      options: [
        'Dejar todas las luces del patio encendidas',
        'Apagar luces exteriores innecesarias',
        'Encender fuegos artificiales',
        'Usar pesticidas en el pasto',
      ],
      correctIndex: 1,
      explanation: '🪲 Apagar luces innecesarias devuelve la oscuridad natural a la noche.',
    ),
    QuizQuestion(
      topic: QuizTopic.conservacion,
      text: 'Apagar la luz exterior ayuda a que las luciérnagas se encuentren más fácil.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 0,
      explanation: '🪲 ¡Verdadero! Permite que sus destellos resalten en la oscuridad.',
    ),
    QuizQuestion(
      topic: QuizTopic.conservacion,
      text: '¿Cómo puedes ayudar a las luciérnagas al cuidar tu jardín?',
      options: [
        'Cortando el pasto al ras siempre',
        'Dejando un rincón con hojarasca y sin pesticidas',
        'Poniendo más luces de colores',
        'Regando con agua salada',
      ],
      correctIndex: 1,
      explanation: '🪲 Un rincón "silvestre" les da refugio y comida sin ningún esfuerzo extra.',
    ),
    QuizQuestion(
      topic: QuizTopic.conservacion,
      text: 'Contarle a tu familia sobre las luciérnagas también ayuda a protegerlas.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 0,
      explanation: '🪲 Cuantas más personas lo sepan, más luces se apagarán por las noches.',
    ),
    QuizQuestion(
      topic: QuizTopic.conservacion,
      text: 'Registrar un avistamiento de luciérnaga en la app, ¿para qué sirve?',
      options: [
        'Solo para ganar puntos',
        'Ayuda a los guardianes a saber dónde viven y protegerlas mejor',
        'No sirve para nada',
        'Para asustarlas',
      ],
      correctIndex: 1,
      explanation: '🪲 Cada avistamiento es un dato real que ayuda a cuidarlas mejor.',
    ),
    QuizQuestion(
      topic: QuizTopic.conservacion,
      text: 'Usar menos luces LED brillantes de noche en el jardín las beneficia.',
      options: ['Verdadero', 'Falso'],
      correctIndex: 0,
      explanation: '🪲 Menos luz artificial significa más oscuridad natural para ellas.',
    ),
    QuizQuestion(
      topic: QuizTopic.conservacion,
      text: '¿Podemos matar o atrapar a las luciérnagas?',
      options: [
        'No, hay que observarlas y dejarlas libres',
        'Sí, es divertido guardarlas en frascos',
        'Solo se pueden atrapar de día',
        'Solo los adultos pueden atraparlas',
      ],
      correctIndex: 0,
      explanation:
          '🪲 Nunca las matamos ni las encerramos: son seres vivos que debemos proteger.',
    ),
  ];
}
