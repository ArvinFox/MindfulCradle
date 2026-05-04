import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class QuestionnaireVerdict {
  final String trendLabel;
  final String trendLabelSi;
  final String emoji;
  final String summary;
  final String summarySi;
  final Map<String, String> subscaleInsights;
  final Map<String, String> subscaleInsightsSi;
  final String
  trendCode; // "improving" | "stable" | "fluctuating" | "declining"
  final DateTime computedAt;

  QuestionnaireVerdict({
    required this.trendLabel,
    required this.trendLabelSi,
    required this.emoji,
    required this.summary,
    required this.summarySi,
    required this.subscaleInsights,
    required this.subscaleInsightsSi,
    required this.trendCode,
    required this.computedAt,
  });

  Map<String, dynamic> toMap() => {
    'trendLabel': trendLabel,
    'trendLabelSi': trendLabelSi,
    'emoji': emoji,
    'summary': summary,
    'summarySi': summarySi,
    'subscaleInsights': subscaleInsights,
    'subscaleInsightsSi': subscaleInsightsSi,
    'trendCode': trendCode,
    'computedAt': FieldValue.serverTimestamp(),
  };

  factory QuestionnaireVerdict.fromMap(Map<String, dynamic> map) =>
      QuestionnaireVerdict(
        trendLabel: map['trendLabel'] as String? ?? '',
        trendLabelSi: map['trendLabelSi'] as String? ?? '',
        emoji: map['emoji'] as String? ?? '',
        summary: map['summary'] as String? ?? '',
        summarySi: map['summarySi'] as String? ?? '',
        subscaleInsights: Map<String, String>.from(
          (map['subscaleInsights'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, v.toString()),
          ),
        ),
        subscaleInsightsSi: Map<String, String>.from(
          (map['subscaleInsightsSi'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, v.toString()),
          ),
        ),
        trendCode: map['trendCode'] as String? ?? 'stable',
        computedAt:
            (map['computedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// DASS-21 Analytical Engine
// ─────────────────────────────────────────────────────────────────────────────

class DASS21VerdictEngine {
  static int _depSeverity(int s) {
    if (s <= 9) return 0;
    if (s <= 13) return 1;
    if (s <= 20) return 2;
    if (s <= 27) return 3;
    return 4;
  }

  static int _anxSeverity(int s) {
    if (s <= 7) return 0;
    if (s <= 9) return 1;
    if (s <= 14) return 2;
    if (s <= 19) return 3;
    return 4;
  }

  static int _strSeverity(int s) {
    if (s <= 14) return 0;
    if (s <= 18) return 1;
    if (s <= 25) return 2;
    if (s <= 33) return 3;
    return 4;
  }

  static String _severityName(int level) {
    const names = ['Normal', 'Mild', 'Moderate', 'Severe', 'Extremely Severe'];
    return names[level.clamp(0, 4)];
  }

  static String _severityNameSi(int level) {
    const names = ['සාමාන්‍ය', 'මෘදු', 'මධ්‍යස්ථ', 'දරුණු', 'අතිශය දරුණු'];
    return names[level.clamp(0, 4)];
  }

  static String _subscaleTrend(int sev1, int sev2, int sev3) {
    final d12 = sev2 - sev1;
    final d23 = sev3 - sev2;
    if (d12 <= 0 && d23 <= 0 && (d12 + d23) < 0) return 'consistently improved';
    if (d12 >= 0 && d23 >= 0 && (d12 + d23) > 0) return 'consistently worsened';
    if (d12 > 0 && d23 < 0) return 'peaked mid-way then improved';
    if (d12 < 0 && d23 > 0) return 'improved then plateaued';
    return 'remained stable';
  }

  static String _subscaleTrendSi(int sev1, int sev2, int sev3) {
    final d12 = sev2 - sev1;
    final d23 = sev3 - sev2;
    if (d12 <= 0 && d23 <= 0 && (d12 + d23) < 0) return 'අඛණ්ඩව වර්ධනය විය';
    if (d12 >= 0 && d23 >= 0 && (d12 + d23) > 0) return 'අඛණ්ඩව පිරිහී ගියේය';
    if (d12 > 0 && d23 < 0)
      return 'මැද භාගයේදී උච්චතම අවස්ථාවට පැමිණ ඉන්පසු වර්ධනය විය';
    if (d12 < 0 && d23 > 0) return 'වර්ධනය වී ඉන්පසු ස්ථාවර විය';
    return 'ස්ථාවරව පැවතුණි';
  }

  static QuestionnaireVerdict compute(Map<int, Map<String, dynamic>> attempts) {
    final a1 = attempts[1]!['scores'] as Map<String, dynamic>;
    final a2 = attempts[2]!['scores'] as Map<String, dynamic>;
    final a3 = attempts[3]!['scores'] as Map<String, dynamic>;

    final dep = [
      (a1['depression'] as num).toInt(),
      (a2['depression'] as num).toInt(),
      (a3['depression'] as num).toInt(),
    ];
    final anx = [
      (a1['anxiety'] as num).toInt(),
      (a2['anxiety'] as num).toInt(),
      (a3['anxiety'] as num).toInt(),
    ];
    final str = [
      (a1['stress'] as num).toInt(),
      (a2['stress'] as num).toInt(),
      (a3['stress'] as num).toInt(),
    ];

    final depLvl = dep.map(_depSeverity).toList();
    final anxLvl = anx.map(_anxSeverity).toList();
    final strLvl = str.map(_strSeverity).toList();

    final comp1 = depLvl[0] + anxLvl[0] + strLvl[0];
    final comp3 = depLvl[2] + anxLvl[2] + strLvl[2];
    final overallDelta = comp3 - comp1;

    final depTrend = _subscaleTrend(depLvl[0], depLvl[1], depLvl[2]);
    final anxTrend = _subscaleTrend(anxLvl[0], anxLvl[1], anxLvl[2]);
    final strTrend = _subscaleTrend(strLvl[0], strLvl[1], strLvl[2]);

    final depTrendSi = _subscaleTrendSi(depLvl[0], depLvl[1], depLvl[2]);
    final anxTrendSi = _subscaleTrendSi(anxLvl[0], anxLvl[1], anxLvl[2]);
    final strTrendSi = _subscaleTrendSi(strLvl[0], strLvl[1], strLvl[2]);

    final improvingCount = [
      depTrend,
      anxTrend,
      strTrend,
    ].where((t) => t.contains('improved') || t.contains('stable')).length;

    final String trendCode;
    final String trendLabel;
    final String trendLabelSi;
    final String emoji;
    final String summary;
    final String summarySi;

    if (overallDelta <= -4) {
      trendCode = 'improving';
      trendLabel = 'Strong Improvement';
      trendLabelSi = 'විශිෂ්ට ප්‍රගතියක්';
      emoji = '🌟';
      summary =
          'Excellent progress! Your depression, anxiety, and stress scores have '
          'dropped significantly across all three assessments. Your consistent '
          'effort is making a real, measurable difference in your mental health.';
      summarySi =
          'ඉතා හොඳ ප්‍රගතියක්! ඔබේ මානසික අවපීඩනය, කාංසාව සහ ආතති මට්ටම් '
          'සියලුම ඇගයීම් හරහා සැලකිය යුතු ලෙස අඩු වී ඇත. ඔබේ අඛණ්ඩ උත්සාහය '
          'ඔබේ මානසික සෞඛ්‍යයේ සැබෑ සහ මැනිය හැකි වෙනසක් ඇති කරමින් පවතී.';
    } else if (overallDelta < 0) {
      trendCode = 'improving';
      trendLabel = 'Gradual Improvement';
      trendLabelSi = 'ක්‍රමානුකූල ප්‍රගතියක්';
      emoji = '🌱';
      summary =
          "You're on a positive path. There is a steady reduction in your "
          'emotional distress scores from the first to the last assessment. '
          'The trend is encouraging — keep nurturing the habits that are '
          'helping you.';
      summarySi =
          'ඔබ සිටින්නේ ධනාත්මක මාර්ගයකයි. පළමු ඇගයීමේ සිට අවසාන ඇගයීම '
          'දක්වා ඔබේ චිත්තවේගී ආතති මට්ටම්වල ක්‍රමානුකූල අඩුවීමක් දක්නට ලැබේ. '
          'මෙය ඉතා යහපත් ප්‍රවණතාවකි — ඔබට උපකාරී වන මෙම පුරුදු තවදුරටත් වර්ධනය කරගන්න.';
    } else if (overallDelta == 0) {
      if (comp3 <= 3) {
        trendCode = 'stable';
        trendLabel = 'Stable & Healthy';
        trendLabelSi = 'ස්ථාවර සහ සෞඛ්‍ය සම්පන්නයි';
        emoji = '💚';
        summary =
            'Your emotional wellbeing has remained stable at a healthy level '
            'across all three assessments. This suggests you have solid coping '
            'strategies in place. Well done!';
        summarySi =
            'ඔබේ චිත්තවේගී සෞඛ්‍යය සියලුම ඇගයීම් හරහා සෞඛ්‍ය සම්පන්න මට්ටමක '
            'ස්ථාවරව පවතී. මෙයින් පෙන්නුම් කරන්නේ ඔබ සතුව ශක්තිමත් මුහුණදීමේ '
            'හැකියාවන් ඇති බවයි. ඉතා හොඳයි!';
      } else {
        trendCode = 'stable';
        trendLabel = 'Stable — Needs Support';
        trendLabelSi = 'ස්ථාවරයි — සහාය අවශ්‍යයි';
        emoji = '💙';
        summary =
            'Your scores have stayed consistent but suggest some ongoing '
            'stress, anxiety, or low mood. Stability is a foundation — '
            'consider speaking with a professional or using MindfulBot for '
            'additional support.';
        summarySi =
            'ඔබේ ලකුණු ස්ථාවරව පවතින නමුත්, යම් ප්‍රමාණයක ආතතියක්, කාංසාවක් '
            'හෝ මානසික පසුබෑමක් අඛණ්ඩව පවතින බවක් පෙන්නුම් කරයි. ස්ථාවරත්වය '
            'හොඳ පදනමක් වුවත් — අමතර සහාය සඳහා වෘත්තිකයෙකු හමුවීම හෝ MindfulBot භාවිතා කිරීම සලකා බලන්න.';
      }
    } else if (overallDelta <= 2 && improvingCount >= 2) {
      trendCode = 'fluctuating';
      trendLabel = 'Mixed Progress';
      trendLabelSi = 'මිශ්‍ර ප්‍රගතියක්';
      emoji = '🔄';
      summary =
          'Your journey shows a mixed pattern — some areas have improved while '
          'others have risen slightly. This is common and suggests you are '
          'still finding balance. Focus on the subscales showing the most growth.';
      summarySi =
          'ඔබේ ප්‍රතිඵල මිශ්‍ර රටාවක් පෙන්නුම් කරයි — සමහර අංශ වර්ධනය වී ඇති අතර '
          'අනෙක් අංශවල සුළු ඉහළ යාමක් දක්නට ලැබේ. මෙය සාමාන්‍ය තත්ත්වයක් වන අතර, '
          'ඔබ තවමත් සමතුලිතතාවය සොයා යමින් සිටින බව මෙයින් අදහස් වේ. වැඩිම වර්ධනයක් පෙන්වන අංශ කෙරෙහි අවධානය යොමු කරන්න.';
    } else if (overallDelta <= 2) {
      trendCode = 'fluctuating';
      trendLabel = 'Slight Fluctuation';
      trendLabelSi = 'සුළු උච්චාවචනයන්';
      emoji = '⚡';
      summary =
          "Life's ups and downs can shift scores without a clear direction. "
          'Regular self-care and mindfulness practice can help stabilize '
          'your emotional state over time.';
      summarySi =
          'ජීවිතයේ ඇතිවන හැලහැප්පීම් හේතුවෙන් ස්ථිර දිශාවකින් තොරව ලකුණු වෙනස් විය හැක. '
          'නිතිපතා තමා ගැන සැලකිලිමත් වීම සහ සිහිකල්පනාව පුහුණු කිරීම කාලයත් සමඟ '
          'ඔබේ චිත්තවේගී තත්ත්වය ස්ථාවර කරගැනීමට උපකාරී වනු ඇත.';
    } else {
      trendCode = 'declining';
      trendLabel = 'Needs Attention';
      trendLabelSi = 'අවධානය යොමු කළ යුතුය';
      emoji = '⚠️';
      summary =
          'Your emotional distress scores have increased across the three '
          'assessments. This is a meaningful signal — please consider '
          'reaching out to a healthcare professional or using MindfulBot for '
          'support. You are not alone, and help is available.';
      summarySi =
          'ඇගයීම් තුන හරහාම ඔබේ චිත්තවේගී ආතති මට්ටම් වැඩි වී ඇත. මෙය '
          'සැලකිලිමත් විය යුතු තත්ත්වයකි — කරුණාකර සෞඛ්‍ය වෘත්තිකයෙකුගේ සහාය '
          'ලබාගැනීමට හෝ MindfulBot වෙතින් සහාය ලබාගැනීමට සලකා බලන්න. ඔබ තනි වී නැත, ඔබට අවශ්‍ය සහාය ලබාගත හැක.';
    }

    final arrows = '(${dep[0]} → ${dep[1]} → ${dep[2]})';
    final arrowsAnx = '(${anx[0]} → ${anx[1]} → ${anx[2]})';
    final arrowsStr = '(${str[0]} → ${str[1]} → ${str[2]})';

    return QuestionnaireVerdict(
      trendLabel: trendLabel,
      trendLabelSi: trendLabelSi,
      emoji: emoji,
      summary: summary,
      summarySi: summarySi,
      subscaleInsights: {
        'Depression':
            '${_capitalize(depTrend)}. Final level: ${_severityName(depLvl[2])} $arrows.',
        'Anxiety':
            '${_capitalize(anxTrend)}. Final level: ${_severityName(anxLvl[2])} $arrowsAnx.',
        'Stress':
            '${_capitalize(strTrend)}. Final level: ${_severityName(strLvl[2])} $arrowsStr.',
      },
      subscaleInsightsSi: {
        'මානසික අවපීඩනය':
            '$depTrendSi. අවසාන මට්ටම: ${_severityNameSi(depLvl[2])} $arrows.',
        'කාංසාව':
            '$anxTrendSi. අවසාන මට්ටම: ${_severityNameSi(anxLvl[2])} $arrowsAnx.',
        'ආතතිය':
            '$strTrendSi. අවසාන මට්ටම: ${_severityNameSi(strLvl[2])} $arrowsStr.',
      },
      trendCode: trendCode,
      computedAt: DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAAS Analytical Engine
// ─────────────────────────────────────────────────────────────────────────────

class MAASVerdictEngine {
  static String _classLabel(double score) {
    if (score >= 4.5) return 'High';
    if (score >= 3.0) return 'Average';
    return 'Low';
  }

  static String _classLabelSi(double score) {
    if (score >= 4.5) return 'ඉහළ';
    if (score >= 3.0) return 'සාමාන්‍ය';
    return 'අඩු';
  }

  static QuestionnaireVerdict compute(Map<int, Map<String, dynamic>> attempts) {
    final s1 = (attempts[1]!['maasScore'] as num).toDouble();
    final s2 = (attempts[2]!['maasScore'] as num).toDouble();
    final s3 = (attempts[3]!['maasScore'] as num).toDouble();

    final d12 = s2 - s1;
    final d23 = s3 - s2;
    final overall = s3 - s1;

    final String trendCode;
    final String trendLabel;
    final String trendLabelSi;
    final String emoji;
    final String summary;
    final String summarySi;
    final String scoreTrend;
    final String scoreTrendSi;

    if (d12 > 0.3 && d23 > 0.3) {
      trendCode = 'improving';
      trendLabel = 'Consistent Growth';
      trendLabelSi = 'අඛණ්ඩ වර්ධනය';
      emoji = '🌟';
      summary =
          'Outstanding! Your mindfulness score has steadily risen across all '
          'three assessments. You are actively cultivating present-moment '
          'awareness in your daily life — keep it up!';
      summarySi =
          'විශිෂ්ටයි! ඇගයීම් තුන හරහාම ඔබේ සිහිකල්පනා ලකුණු මට්ටම අඛණ්ඩව '
          'ඉහළ ගොස් ඇත. ඔබේ දෛනික ජීවිතයේ වර්තමාන මොහොත පිළිබඳ අවධානය ඔබ '
          'ඉතා හොඳින් පවත්වාගෙන යයි — ඒ අයුරින්ම ඉදිරියට යන්න!';
      scoreTrend = 'grew consistently across all 3 attempts';
      scoreTrendSi = 'ඇගයීම් 3 තුළම අඛණ්ඩව වර්ධනය විය';
    } else if (overall > 0.75 && d12 <= 0.1) {
      trendCode = 'improving';
      trendLabel = 'Late Bloomer';
      trendLabelSi = 'පසුව ඇතිවූ වර්ධනයක්';
      emoji = '🌺';
      summary =
          'A strong finish! Your mindfulness dipped slightly in the middle, '
          'but you ended with a notable jump. Perseverance paid off.';
      summarySi =
          'සාර්ථක අවසානයක්! මැද භාගයේදී ඔබේ සිහිකල්පනා මට්ටම සුළු වශයෙන් '
          'අඩු වුවද, අවසානයේදී එය සැලකිය යුතු ලෙස ඉහළ ගොස් ඇත. '
          'ඔබගේ අඛණ්ඩ උත්සාහය සාර්ථක වී ඇත.';
      scoreTrend = 'dipped mid-way then recovered strongly';
      scoreTrendSi = 'මැද භාගයේදී අඩු වී ඉන්පසු ප්‍රබල ලෙස වර්ධනය විය';
    } else if (overall > 0.5) {
      trendCode = 'improving';
      trendLabel = 'Steady Improvement';
      trendLabelSi = 'ක්‍රමානුකූල වර්ධනයක්';
      emoji = '🌱';
      summary =
          'Your mindfulness levels show a positive overall trend. Minor '
          'fluctuations are normal — what matters is the direction.';
      summarySi =
          'ඔබේ සිහිකල්පනා මට්ටම් සමස්තයක් ලෙස ධනාත්මක වර්ධනයක් පෙන්නුම් කරයි. '
          'සුළු උච්චාවචනයන් සාමාන්‍යයි — වැදගත් වන්නේ ඔබේ වර්ධන දිශානතියයි.';
      scoreTrend = 'improved overall with minor variations';
      scoreTrendSi = 'සුළු වෙනස්කම් සහිතව සමස්තයක් ලෙස වර්ධනය විය';
    } else if (s1 >= 4.0 && s3 >= 4.0 && overall.abs() <= 0.5) {
      trendCode = 'stable';
      trendLabel = 'Consistently Mindful';
      trendLabelSi = 'අඛණ්ඩ සිහිකල්පනාවෙන් යුක්තයි';
      emoji = '💚';
      summary =
          'You have maintained a strong level of mindfulness throughout all '
          'three assessments — a sign of a well-established awareness practice.';
      summarySi =
          'ඔබ සියලුම ඇගයීම් පුරාවට ඉහළ සිහිකල්පනා මට්ටමක් පවත්වාගෙන ඇත — '
          'මෙය මනාව ස්ථාපිත වූ සිහිකල්පනා පුහුණුවක ප්‍රතිඵලයකි.';
      scoreTrend = 'remained consistently high';
      scoreTrendSi = 'අඛණ්ඩව ඉහළ මට්ටමක පැවතුණි';
    } else if (s1 < 3.5 && s3 >= 4.0) {
      trendCode = 'improving';
      trendLabel = 'Remarkable Recovery';
      trendLabelSi = 'සුවිශේෂී වර්ධනයක්';
      emoji = '🏆';
      summary =
          'Exceptional progress! You started with a lower mindfulness level '
          'and reached a healthy, mindful state by the final assessment. '
          'Your growth is truly remarkable.';
      summarySi =
          'සුවිශේෂී ප්‍රගතියක්! ඔබ අඩු සිහිකල්පනා මට්ටමකින් ආරම්භ කර අවසාන ඇගයීම '
          'වන විට සෞඛ්‍ය සම්පන්න, ඉහළ සිහිකල්පනා මට්ටමකට ළඟා වී ඇත. '
          'ඔබේ මෙම වර්ධනය ඇත්තෙන්ම විශිෂ්ටයි.';
      scoreTrend = 'improved dramatically from low to high';
      scoreTrendSi =
          'අඩු මට්ටමක සිට ඉහළ මට්ටමක් දක්වා සැලකිය යුතු ලෙස වර්ධනය විය';
    } else if (overall < -0.5 && d12 < -0.2 && d23 < -0.2) {
      trendCode = 'declining';
      trendLabel = 'Consistent Decline';
      trendLabelSi = 'අඛණ්ඩ පිරිහීමක්';
      emoji = '⚠️';
      summary =
          'Your mindfulness scores have decreased steadily across the three '
          'assessments. This could reflect increased stress or reduced practice. '
          'Try dedicating a few minutes daily to mindful breathing.';
      summarySi =
          'ඇගයීම් තුන පුරාවටම ඔබේ සිහිකල්පනා ලකුණු අඛණ්ඩව අඩුවී ඇත. මෙයින් '
          'වැඩිවූ ආතතියක් හෝ පුහුණුවීම් අඩුවීමක් පෙන්නුම් කළ හැක. දිනකට '
          'මිනිත්තු කිහිපයක් හෝ සිහිකල්පනාවෙන් හුස්ම ගැනීමේ පුහුණුව සඳහා වෙන් කිරීමට උත්සාහ කරන්න.';
      scoreTrend = 'declined consistently';
      scoreTrendSi = 'අඛණ්ඩව අඩු විය';
    } else if (overall < -0.5) {
      trendCode = 'declining';
      trendLabel = 'Overall Decline';
      trendLabelSi = 'සමස්ත පිරිහීමක්';
      emoji = '💙';
      summary =
          'Your overall mindfulness trend shows a decline. Scattered attention '
          'is normal, but building a consistent practice can help restore '
          'your awareness over time.';
      summarySi =
          'ඔබේ සමස්ත සිහිකල්පනා මට්ටමේ අඩුවීමක් දක්නට ලැබේ. '
          'අවධානය වෙනතකට යොමුවීම සාමාන්‍ය දෙයකි, නමුත් අඛණ්ඩ පුහුණුවක් ගොඩනඟා '
          'ගැනීමෙන් කාලයත් සමඟ ඔබේ සිහිකල්පනාව නැවත වර්ධනය කරගත හැක.';
      scoreTrend = 'declined overall';
      scoreTrendSi = 'සමස්තයක් ලෙස අඩු විය';
    } else {
      trendCode = 'stable';
      trendLabel = 'Developing Awareness';
      trendLabelSi = 'වර්ධනය වන අවධානය';
      emoji = '🔄';
      summary =
          "Your scores show variation but haven't moved significantly in "
          'either direction — a common phase in developing mindfulness. '
          'Consistency in practice is the key to growth.';
      summarySi =
          'ඔබේ ලකුණුවල විචලනයක් දක්නට ලැබෙන නමුත් විශේෂිත දිශාවකට වෙනස් වී නැත '
          '— මෙය සිහිකල්පනාව වර්ධනය කිරීමේ මූලික අවධියේදී සාමාන්‍ය තත්ත්වයකි. '
          'අඛණ්ඩ පුහුණුව මෙම වර්ධනයේ යතුරයි.';
      scoreTrend = 'stayed in a developing range with minor fluctuations';
      scoreTrendSi = 'සුළු වෙනස්කම් සහිතව වර්ධනීය මට්ටමක පැවතුණි';
    }

    return QuestionnaireVerdict(
      trendLabel: trendLabel,
      trendLabelSi: trendLabelSi,
      emoji: emoji,
      summary: summary,
      summarySi: summarySi,
      subscaleInsights: {
        'Mindfulness Score':
            '${_capitalize(scoreTrend)}. '
            'Started: ${s1.toStringAsFixed(2)} (${_classLabel(s1)}) → '
            'Mid: ${s2.toStringAsFixed(2)} → '
            'Final: ${s3.toStringAsFixed(2)} (${_classLabel(s3)}).',
      },
      subscaleInsightsSi: {
        'සිහිකල්පනා ලකුණ':
            '${_capitalize(scoreTrendSi)}. '
            'ආරම්භය: ${s1.toStringAsFixed(2)} (${_classLabelSi(s1)}) → '
            'මැද: ${s2.toStringAsFixed(2)} → '
            'අවසානය: ${s3.toStringAsFixed(2)} (${_classLabelSi(s3)}).',
      },
      trendCode: trendCode,
      computedAt: DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PWS-18 Analytical Engine
// ─────────────────────────────────────────────────────────────────────────────

class PWS18VerdictEngine {
  static String _levelLabel(double score) {
    if (score >= 5.5) return 'Flourishing';
    if (score >= 4.0) return 'Developing';
    return 'Needs Growth';
  }

  static String _levelLabelSi(double score) {
    if (score >= 5.5) return 'පරිපූර්ණයි';
    if (score >= 4.0) return 'වර්ධනය වෙමින් පවතී';
    return 'වර්ධනයක් අවශ්‍යයි';
  }

  static String _subscaleNameSi(String key) {
    const map = {
      'Autonomy': 'ස්වාධීනත්වය',
      'Environmental Mastery': 'පරිසරය කළමනාකරණය',
      'Personal Growth': 'පෞද්ගලික වර්ධනය',
      'Positive Relations with Others': 'අන් අය සමඟ ඇති ධනාත්මක සබඳතා',
      'Purpose in Life': 'ජීවිතයේ අරමුණ',
      'Self-Acceptance': 'තමා පිළිබඳ පිළිගැනීම',
    };
    return map[key] ?? key;
  }

  static double _avgScore(Map<String, dynamic> attempt) {
    final raw = attempt['subscaleScores'];
    if (raw == null) return 0.0;
    final map = raw as Map<String, dynamic>;
    if (map.isEmpty) return 0.0;
    return map.values.fold<double>(0, (s, v) => s + (v as num).toDouble()) /
        map.length;
  }

  static String _subscaleTrend(double s1, double s2, double s3) {
    final d12 = s2 - s1;
    final d23 = s3 - s2;
    if (d12 > 0.35 && d23 > 0.35) return 'consistently improved';
    if (d12 < -0.35 && d23 < -0.35) return 'consistently declined';
    if (d12 > 0.2 && d23 < -0.2) return 'improved then dipped';
    if (d12 < -0.2 && d23 > 0.2) return 'dipped then recovered';
    return 'remained stable';
  }

  static String _subscaleTrendSi(double s1, double s2, double s3) {
    final d12 = s2 - s1;
    final d23 = s3 - s2;
    if (d12 > 0.35 && d23 > 0.35) return 'අඛණ්ඩව වර්ධනය විය';
    if (d12 < -0.35 && d23 < -0.35) return 'අඛණ්ඩව අඩු විය';
    if (d12 > 0.2 && d23 < -0.2) return 'වර්ධනය වී ඉන්පසු අඩු විය';
    if (d12 < -0.2 && d23 > 0.2) return 'අඩු වී ඉන්පසු නැවත වර්ධනය විය';
    return 'ස්ථාවරව පැවතුණි';
  }

  static QuestionnaireVerdict compute(Map<int, Map<String, dynamic>> attempts) {
    final a1 = attempts[1]!;
    final a2 = attempts[2]!;
    final a3 = attempts[3]!;

    final avg1 = _avgScore(a1);
    final avg2 = _avgScore(a2);
    final avg3 = _avgScore(a3);
    final overall = avg3 - avg1;
    final d12 = avg2 - avg1;
    final d23 = avg3 - avg2;

    // Per-subscale analysis
    final sc1 = _toDoubleMap(
      a1['subscaleScores'] as Map<String, dynamic>? ?? {},
    );
    final sc2 = _toDoubleMap(
      a2['subscaleScores'] as Map<String, dynamic>? ?? {},
    );
    final sc3 = _toDoubleMap(
      a3['subscaleScores'] as Map<String, dynamic>? ?? {},
    );

    final Map<String, String> subscaleInsights = {};
    final Map<String, String> subscaleInsightsSi = {};
    String? mostImproved;
    String? mostDeclined;
    double maxGain = 0;
    double maxLoss = 0;

    for (final key in sc1.keys) {
      final v1 = sc1[key] ?? 0.0;
      final v2 = sc2[key] ?? 0.0;
      final v3 = sc3[key] ?? 0.0;
      final trend = _subscaleTrend(v1, v2, v3);
      final trendSi = _subscaleTrendSi(v1, v2, v3);
      subscaleInsights[key] =
          '${_capitalize(trend)}. '
          'Final: ${v3.toStringAsFixed(1)} (${_levelLabel(v3)})';
      subscaleInsightsSi[_subscaleNameSi(key)] =
          '${_capitalize(trendSi)}. '
          'අවසානය: ${v3.toStringAsFixed(1)} (${_levelLabelSi(v3)})';
      final delta = v3 - v1;
      if (delta > maxGain) {
        maxGain = delta;
        mostImproved = key;
      }
      if (delta < maxLoss) {
        maxLoss = delta;
        mostDeclined = key;
      }
    }

    final String trendCode;
    final String trendLabel;
    final String trendLabelSi;
    final String emoji;
    final String summary;
    final String summarySi;

    if (d12 > 0.4 && d23 > 0.4) {
      trendCode = 'improving';
      trendLabel = 'Flourishing Journey';
      trendLabelSi = 'සාර්ථක ගමනක්';
      emoji = '🌟';
      summary =
          'Your wellbeing has consistently grown across all three assessments, '
          'reflecting real improvement in multiple dimensions of psychological '
          'health.${mostImproved != null ? ' "$mostImproved" showed the greatest growth.' : ''}';
      summarySi =
          'ඔබේ යහපැවැත්ම ඇගයීම් තුන පුරාවටම අඛණ්ඩව වර්ධනය වී ඇති අතර, '
          'මානසික සෞඛ්‍යයේ අංශ කිහිපයකම සැබෑ දියුණුවක් පෙන්නුම් කරයි.'
          '${mostImproved != null ? ' විශේෂයෙන්ම "${_subscaleNameSi(mostImproved)}" අංශයේ ඉහළම වර්ධනයක් දක්නට ලැබේ.' : ''}'; // ignore: unnecessary_non_null_assertion
    } else if (overall > 0.5) {
      trendCode = 'improving';
      trendLabel = 'Growing Wellbeing';
      trendLabelSi = 'වර්ධනය වන යහපැවැත්ම';
      emoji = '🌱';
      summary =
          'Your overall wellbeing score has improved from the first to the '
          'last assessment.${mostImproved != null ? ' "$mostImproved" was your strongest area of growth.' : ''} '
          'Keep nurturing the habits that brought you here.';
      summarySi =
          'පළමු ඇගයීමේ සිට අවසාන ඇගයීම දක්වා ඔබේ සමස්ත යහපැවැත්ම ලකුණු මට්ටම වර්ධනය වී ඇත.'
          '${mostImproved != null ? ' ඔබේ වැඩිම වර්ධනයක් පෙන්වන අංශය වන්නේ "${_subscaleNameSi(mostImproved)}" ය.' : ''} '
          'මෙම තත්ත්වයට ඔබව ගෙන ආ යහපත් පුරුදු තවදුරටත් වර්ධනය කරගන්න.';
    } else if (overall < -0.5 && d12 < 0 && d23 < 0) {
      trendCode = 'declining';
      trendLabel = 'Needs Attention';
      trendLabelSi = 'අවධානය යොමු කළ යුතුය';
      emoji = '⚠️';
      summary =
          'Your wellbeing scores show a consistent decline across the three '
          'assessments.${mostDeclined != null ? ' "$mostDeclined" had the most significant drop.' : ''} '
          'This is a valuable signal — consider what may be affecting your '
          'wellbeing and reach out for support if needed.';
      summarySi =
          'ඇගයීම් තුන පුරාවටම ඔබේ යහපැවැත්ම ලකුණු අඛණ්ඩ අඩුවීමක් පෙන්නුම් කරයි.'
          '${mostDeclined != null ? ' "${_subscaleNameSi(mostDeclined)}" අංශයේ විශාලතම අඩුවීම දක්නට ලැබේ.' : ''} '
          'මෙය වැදගත් සංඥාවකි — ඔබේ යහපැවැත්මට බලපාන කරුණු මොනවාදැයි සලකා බලා, අවශ්‍ය නම් සහාය ලබාගැනීමට යොමුවන්න.';
    } else if (overall < -0.5) {
      trendCode = 'declining';
      trendLabel = 'Declining Wellbeing';
      trendLabelSi = 'පිරිහෙන යහපැවැත්ම';
      emoji = '💙';
      summary =
          'Your overall wellbeing trend shows a decline, though the journey '
          'was not linear. Identifying the specific subscales most affected '
          'can help you focus your efforts where they matter most.';
      summarySi =
          'ඔබේ සමස්ත යහපැවැත්මේ අඩුවීමක් දක්නට ලැබුණද, එය එකම අයුරින් සිදුවී නොමැත. '
          'වැඩිපුරම බලපෑමට ලක්ව ඇති අංශ මොනවාදැයි හඳුනාගැනීමෙන්, ඔබේ උත්සාහය වඩාත් '
          'වැදගත් තැන් වෙත යොමු කිරීමට උපකාරී වනු ඇත.';
    } else if (avg3 >= 5.0 && overall.abs() <= 0.5) {
      trendCode = 'stable';
      trendLabel = 'Stable & Flourishing';
      trendLabelSi = 'ස්ථාවර සහ සාර්ථකයි';
      emoji = '💚';
      summary =
          'Your wellbeing has remained consistently high throughout all '
          'assessments, reflecting strong psychological health across multiple '
          'dimensions. Keep up your excellent practices!';
      summarySi =
          'ඔබේ යහපැවැත්ම සියලුම ඇගයීම් පුරාවට ඉහළ මට්ටමක ස්ථාවරව පවතී. '
          'එය අංශ කිහිපයක් ඔස්සේම පවතින ශක්තිමත් මානසික සෞඛ්‍යයක ප්‍රතිඵලයකි. '
          'ඔබේ මෙම විශිෂ්ට පුරුදු ඒ අයුරින්ම පවත්වාගෙන යන්න!';
    } else if (d12 > 0.2 && d23 < -0.2) {
      trendCode = 'fluctuating';
      trendLabel = 'Peaked Mid-Journey';
      trendLabelSi = 'මැද භාගයේ උපරිමයක්';
      emoji = '🔄';
      summary =
          'Your wellbeing peaked in the middle assessment before dipping. '
          'Reflect on what practices worked well during that period and '
          'try to reintroduce them.';
      summarySi =
          'ඔබේ යහපැවැත්ම මැද ඇගයීමේදී උපරිමයකට පැමිණ ඉන්පසු අඩු වී ඇත. '
          'එම කාලය තුළ ඔබ අනුගමනය කළ සාර්ථක පුරුදු මොනවාදැයි කල්පනා කර '
          'ඒවා නැවත ක්‍රියාත්මක කිරීමට උත්සාහ කරන්න.';
    } else if (d12 < -0.2 && d23 > 0.2) {
      trendCode = 'fluctuating';
      trendLabel = 'Recovering Well';
      trendLabelSi = 'සාර්ථක ප්‍රකෘතිමත් වීමක්';
      emoji = '🌺';
      summary =
          'After a dip in the second assessment, your wellbeing bounced back '
          'in the final one. This resilience is a positive sign — you are '
          'finding your way back to a better state.';
      summarySi =
          'දෙවන ඇගයීමේදී වූ අඩුවීමෙන් පසු, අවසාන ඇගයීමේදී ඔබේ යහපැවැත්ම '
          'නැවතත් සාර්ථක ලෙස ඉහළ ගොස් ඇත. මෙම නැඟී සිටීමේ හැකියාව ඉතා '
          'ධනාත්මක ලක්ෂණයකි — ඔබ නැවතත් යහපත් තත්ත්වයක් කරා ගමන් කරමින් සිටී.';
    } else {
      trendCode = 'stable';
      trendLabel = 'Steady Progress';
      trendLabelSi = 'ක්‍රමානුකූල ප්‍රගතියක්';
      emoji = '⚡';
      summary =
          'Your wellbeing scores have been relatively consistent throughout '
          'the three assessments. Look at the subscales with the most room '
          'for growth to target your next improvements.';
      summarySi =
          'ඔබේ යහපැවැත්ම ලකුණු ඇගයීම් තුන පුරාවටම සාපේක්ෂව ස්ථාවරව පවතී. '
          'ඔබේ මීළඟ වර්ධනය සඳහා, වැඩිම දියුණුවක් ලබාගත හැකි අංශ වෙත අවධානය යොමු කරන්න.';
    }

    return QuestionnaireVerdict(
      trendLabel: trendLabel,
      trendLabelSi: trendLabelSi,
      emoji: emoji,
      summary: summary,
      summarySi: summarySi,
      subscaleInsights: subscaleInsights,
      subscaleInsightsSi: subscaleInsightsSi,
      trendCode: trendCode,
      computedAt: DateTime.now(),
    );
  }

  static Map<String, double> _toDoubleMap(Map<String, dynamic> raw) =>
      raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
}

// ─────────────────────────────────────────────────────────────────────────────
// Firestore persistence
// ─────────────────────────────────────────────────────────────────────────────

class VerdictFirestoreService {
  static final _db = FirebaseFirestore.instance;

  static bool _isCurrentUser(String userId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid == userId;
  }

  static Future<void> saveVerdict({
    required String userId,
    required String subcollection,
    required QuestionnaireVerdict verdict,
  }) async {
    if (!_isCurrentUser(userId)) {
      if (kDebugMode) debugPrint('Blocked saveVerdict for non-owner.');
      return;
    }
    await _db
        .collection('users')
        .doc(userId)
        .collection(subcollection)
        .doc('final_verdict')
        .set(verdict.toMap());
  }

  static Future<QuestionnaireVerdict?> loadVerdict({
    required String userId,
    required String subcollection,
  }) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection(subcollection)
          .doc('final_verdict')
          .get();
      if (doc.exists && doc.data() != null) {
        return QuestionnaireVerdict.fromMap(doc.data()!);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading verdict ($subcollection): $e');
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
