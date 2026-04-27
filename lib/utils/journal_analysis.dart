/// Rule-based keyword analysis for journal entries.
/// Returns sentiment (positive/neutral/negative) and semantic tags.
class JournalAnalysis {
  // ─────────────── English keyword lists ───────────────

  static const List<String> _positiveEn = [
    'happy',
    'happiness',
    'joy',
    'joyful',
    'grateful',
    'gratitude',
    'thankful',
    'blessed',
    'wonderful',
    'amazing',
    'great',
    'fantastic',
    'excellent',
    'peaceful',
    'calm',
    'relaxed',
    'content',
    'satisfied',
    'hopeful',
    'excited',
    'love',
    'loved',
    'beautiful',
    'smile',
    'laughed',
    'enjoy',
    'enjoyed',
    'pleasure',
    'delight',
    'delighted',
    'positive',
    'energetic',
    'motivated',
    'proud',
    'optimistic',
    'cheerful',
    'glad',
    'relief',
    'relieved',
    'better',
    'improved',
    'good',
    'safe',
    'warm',
    'secure',
    'confident',
    'strong',
    'healing',
    'healed',
    'recovery',
    'support',
    'supported',
    'connected',
    'bonded',
    'bonding',
    'precious',
    'miracle',
  ];

  static const List<String> _negativeEn = [
    'sad',
    'sadness',
    'unhappy',
    'depressed',
    'depression',
    'anxious',
    'anxiety',
    'worried',
    'worry',
    'scared',
    'fearful',
    'fear',
    'stressed',
    'stress',
    'overwhelmed',
    'tired',
    'exhausted',
    'fatigue',
    'sleepless',
    'insomnia',
    'lonely',
    'alone',
    'hopeless',
    'helpless',
    'worthless',
    'crying',
    'cried',
    'tears',
    'painful',
    'pain',
    'hurt',
    'hurting',
    'difficult',
    'hard',
    'struggling',
    'struggle',
    'problem',
    'issue',
    'trouble',
    'bad',
    'terrible',
    'horrible',
    'awful',
    'numb',
    'empty',
    'broken',
    'lost',
    'miserable',
    'angry',
    'frustrated',
    'irritated',
    'nausea',
    'sick',
    'unwell',
    'bleeding',
    'scared',
  ];

  // ─────────────── Sinhala keyword lists ───────────────

  static const List<String> _positiveSi = [
    'සතුටු',
    'සතුට',
    'ප්‍රීති',
    'ප්‍රීතිය',
    'ශාන්ත',
    'සාමය',
    'ආදරය',
    'ස්තූතිය',
    'ශක්ති',
    'සාර්ථකයි',
    'ප්‍රශංසා',
    'ප්‍රශංසනීය',
    'ඉතා හොඳ',
    'හොඳ',
    'ලස්සන',
    'සතුටෙන්',
    'ආශා',
    'ශාන්ත',
    'ප්‍රකෘති',
  ];

  static const List<String> _negativeSi = [
    'දුක',
    'දුකෙන්',
    'ශෝකය',
    'කනස්සල්ල',
    'බිය',
    'භය',
    'ආතතිය',
    'අසතුට',
    'ගැටලු',
    'ගැටළු',
    'අසාර්ථකයි',
    'වෙහෙස',
    'කඳුළු',
    'ඇඬෙනවා',
    'ඇඬුවා',
    'ඉවසිය නොහැකි',
    'කෝපය',
    'රෝගී',
    'ජාඩ',
    'නින්ද නැති',
    'ක්ලාන්ත',
    'අනාථ',
  ];

  // ─────────────── Semantic tag keyword maps ───────────────

  static const Map<String, List<String>> _semanticTagsEn = {
    'pregnancy': [
      'pregnant',
      'pregnancy',
      'trimester',
      'bump',
      'contractions',
      'labor',
      'labour',
      'prenatal',
      'kick',
      'kicks',
      'womb',
      'ultrasound',
      'midwife',
      'obstetrician',
      'nausea',
      'morning sickness',
      'heartburn',
      'swollen',
      'gestational',
      'weeks pregnant',
      'due date',
      'antenatal',
      'postnatal',
    ],
    'baby': [
      'baby',
      'newborn',
      'infant',
      'breastfeed',
      'breastfeeding',
      'latch',
      'diaper',
      'nappy',
      'crib',
      'cradle',
      'formula',
      'feed',
      'feeding',
      'cry',
      'crying',
      'teething',
      'sleep train',
      'milestone',
      'developmental',
    ],
    'family': [
      'family',
      'husband',
      'partner',
      'spouse',
      'mother',
      'father',
      'parent',
      'mom',
      'dad',
      'sibling',
      'sister',
      'brother',
      'in-law',
      'relatives',
      'grandmother',
      'grandfather',
      'grandma',
      'grandpa',
      'support system',
    ],
    'sleep': [
      'sleep',
      'sleeping',
      'insomnia',
      'restless',
      'dream',
      'dreams',
      'nightmare',
      'fatigue',
      'rest',
      'awake',
      'tired',
      'exhausted',
      'sleepless',
      'nap',
      'naptime',
      'bedtime',
    ],
    'health': [
      'health',
      'doctor',
      'hospital',
      'medicine',
      'medication',
      'pain',
      'sick',
      'checkup',
      'appointment',
      'blood pressure',
      'exercise',
      'yoga',
      'walk',
      'diet',
      'nutrition',
      'vitamin',
      'supplement',
      'weight',
      'symptoms',
      'complication',
    ],
    'emotions': [
      'feel',
      'feeling',
      'feelings',
      'emotion',
      'emotions',
      'mood',
      'tears',
      'cry',
      'smile',
      'laugh',
      'overwhelmed',
      'stressed',
      'anxious',
      'calm',
      'peaceful',
      'angry',
      'confused',
    ],
    'work': [
      'work',
      'job',
      'office',
      'career',
      'boss',
      'colleague',
      'deadline',
      'meeting',
      'maternity leave',
      'leave',
      'return to work',
    ],
  };

  static const Map<String, List<String>> _semanticTagsSi = {
    'pregnancy': ['ගැබ්', 'ගර්භනී', 'දරු ප්‍රසූතිය', 'ප්‍රසූතිය', 'නිරෝගී'],
    'baby': ['දරුවා', 'බිළිඳා', 'දෙමළ', 'කිරි', 'ශ්‍රී'],
    'family': ['පවුල', 'ස්වාමිපුරුෂ', 'අම්මා', 'තාත්තා', 'නෑදෑ'],
    'sleep': ['නිදාගැනීම', 'නිදි', 'දිව', 'ක්ලාන්ත', 'නින්ද'],
    'health': ['සෞඛ්‍ය', 'රෝහල', 'වෛද්‍ය', 'ඖෂධ'],
    'emotions': ['හැඟීම', 'හැඟීම්', 'කෝපය', 'ශෝකය', 'ප්‍රීතිය'],
    'work': ['රැකියා', 'කාර්යාල'],
  };

  // ─────────────── Public API ───────────────

  static ({String sentiment, double score, List<String> tags}) analyze(
    String text,
    String language,
  ) {
    final lower = text.toLowerCase();

    // Sentiment scoring
    int positiveCount = 0;
    int negativeCount = 0;

    if (language == 'si') {
      for (final word in _positiveSi) {
        if (text.contains(word)) positiveCount++;
      }
      for (final word in _negativeSi) {
        if (text.contains(word)) negativeCount++;
      }
    } else {
      for (final word in _positiveEn) {
        if (lower.contains(word)) positiveCount++;
      }
      for (final word in _negativeEn) {
        if (lower.contains(word)) negativeCount++;
      }
    }

    final total = positiveCount + negativeCount;
    final double score = total == 0
        ? 0.0
        : (positiveCount - negativeCount) / total.toDouble();

    String sentiment;
    if (score > 0.1) {
      sentiment = 'positive';
    } else if (score < -0.1) {
      sentiment = 'negative';
    } else {
      sentiment = 'neutral';
    }

    // Semantic tags
    final tags = <String>{};
    final tagMap = language == 'si' ? _semanticTagsSi : _semanticTagsEn;
    for (final entry in tagMap.entries) {
      for (final keyword in entry.value) {
        if (language == 'si'
            ? text.contains(keyword)
            : lower.contains(keyword)) {
          tags.add(entry.key);
          break;
        }
      }
    }

    return (sentiment: sentiment, score: score, tags: tags.toList());
  }

  static String sentimentEmoji(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return '😊';
      case 'negative':
        return '😔';
      default:
        return '😐';
    }
  }

  static String sentimentLabel(String sentiment, String language) {
    if (language == 'si') {
      switch (sentiment) {
        case 'positive':
          return 'ධනාත්මක';
        case 'negative':
          return 'නිෂේධාත්මක';
        default:
          return 'සාමාන්‍ය';
      }
    }
    switch (sentiment) {
      case 'positive':
        return 'Positive';
      case 'negative':
        return 'Negative';
      default:
        return 'Neutral';
    }
  }

  static Map<String, String> sentimentTagLabel(String tag, String language) {
    const enLabels = <String, String>{
      'pregnancy': 'Pregnancy',
      'baby': 'Baby',
      'family': 'Family',
      'sleep': 'Sleep',
      'health': 'Health',
      'emotions': 'Emotions',
      'work': 'Work',
    };
    const siLabels = <String, String>{
      'pregnancy': 'ගැබ් ගැනීම',
      'baby': 'දරුවා',
      'family': 'පවුල',
      'sleep': 'නින්ද',
      'health': 'සෞඛ්‍ය',
      'emotions': 'හැඟීම්',
      'work': 'රැකියා',
    };
    final map = language == 'si' ? siLabels : enLabels;
    return {'label': map[tag] ?? tag};
  }
}
