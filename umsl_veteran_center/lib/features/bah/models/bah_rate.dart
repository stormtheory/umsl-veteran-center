// lib/features/bah/models/bah_rate.dart
//
// Models for the BAH/MHA calculator.
// All rates loaded from assets/data/bah_rates.json — never hardcoded.
// Update the JSON each academic year; no Dart changes needed.

// ---------------------------------------------------------------------------
// Training time tier — used for rate lookups
// ---------------------------------------------------------------------------
enum TrainingTime {
  full,
  threeQuarter,
  half,
  less;

  String get label {
    switch (this) {
      case TrainingTime.full:          return 'Full-time';
      case TrainingTime.threeQuarter:  return '3/4 time';
      case TrainingTime.half:          return '1/2 time';
      case TrainingTime.less:          return 'Less than 1/2 time';
    }
  }

  // Derive training time from the ratio of enrolled hours to full-time hours
  static TrainingTime fromRatio(double ratio) {
    if (ratio >= 1.0)    return TrainingTime.full;
    if (ratio >= 0.75)   return TrainingTime.threeQuarter;
    if (ratio >= 0.5)    return TrainingTime.half;
    return TrainingTime.less;
  }
}

// ---------------------------------------------------------------------------
// BahTier — one row in the tiers array per benefit
// ---------------------------------------------------------------------------
class BahTier {
  final String id;
  final String label;
  final double minRatio;
  final int? monthlyRate;       // flat rate for Ch. 30, 35, 1606
  final double? mhaMultiplier;  // multiplier for Ch. 33 in-person
  final double? onlineMultiplier; // multiplier for Ch. 33 online

  const BahTier({
    required this.id,
    required this.label,
    required this.minRatio,
    this.monthlyRate,
    this.mhaMultiplier,
    this.onlineMultiplier,
  });

  factory BahTier.fromJson(Map<String, dynamic> j) => BahTier(
        id:               j['id'] as String,
        label:            j['label'] as String,
        minRatio:         (j['min_ratio'] as num).toDouble(),
        monthlyRate:      j['monthly_rate'] as int?,
        mhaMultiplier:    (j['mha_multiplier'] as num?)?.toDouble(),
        onlineMultiplier: (j['online_multiplier'] as num?)?.toDouble(),
      );

  TrainingTime get trainingTime => TrainingTime.values.firstWhere(
        (t) => t.name == id || (id == 'three_quarter' && t == TrainingTime.threeQuarter),
        orElse: () => TrainingTime.less,
      );
}

// ---------------------------------------------------------------------------
// BahBenefit — one benefit program with its tiers
// ---------------------------------------------------------------------------
class BahBenefit {
  final String id;
  final String name;
  final String shortName;
  final bool hasMha;
  final String note;
  final bool counselorDriven; // Ch. 31 — rate set by counselor
  final bool tuitionOnly;     // MO Heroes — no housing at all
  final int regularFtHours;
  final int? mhaFullInperson;
  final int? mhaFullOnline;
  final List<BahTier> tiers;

  const BahBenefit({
    required this.id,
    required this.name,
    required this.shortName,
    required this.hasMha,
    required this.note,
    required this.counselorDriven,
    required this.tuitionOnly,
    required this.regularFtHours,
    this.mhaFullInperson,
    this.mhaFullOnline,
    required this.tiers,
  });

  factory BahBenefit.fromJson(String id, Map<String, dynamic> j) => BahBenefit(
        id:               id,
        name:             j['name'] as String,
        shortName:        j['short_name'] as String,
        hasMha:           j['has_mha'] as bool? ?? false,
        note:             j['note'] as String? ?? '',
        counselorDriven:  j['counselor_driven'] as bool? ?? false,
        tuitionOnly:      j['tuition_only'] as bool? ?? false,
        regularFtHours:   j['regular_ft_hours'] as int? ?? 12,
        mhaFullInperson:  j['mha_full_inperson'] as int?,
        mhaFullOnline:    j['mha_full_online'] as int?,
        tiers: (j['tiers'] as List<dynamic>? ?? [])
            .map((t) => BahTier.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  // Calculate monthly amount given credit hours, full-time threshold, online flag
  BahResult calculate({
    required int creditHours,
    required int ftHours,
    required bool onlineOnly,
  }) {
    // Handle special cases first
    if (counselorDriven) {
      return BahResult(
        monthlyAmount: 0,
        trainingTime:  TrainingTime.full,
        label:         'Set by your VR&E counselor',
        note:          note,
        isCounselorDriven: true,
        tiers:         [],
      );
    }

    if (tuitionOnly) {
      return BahResult(
        monthlyAmount: 0,
        trainingTime:  TrainingTime.full,
        label:         'Tuition waiver only — no housing allowance',
        note:          note,
        isTuitionOnly: true,
        tiers:         [],
      );
    }

    final ratio = ftHours > 0
        ? (creditHours / ftHours).clamp(0.0, 1.0)
        : 0.0;
    final tt = TrainingTime.fromRatio(ratio);
    final tier = tiers.firstWhere(
      (t) => t.id == _ttId(tt),
      orElse: () => tiers.last,
    );

    int monthly = 0;
    String label = '';

    if (id == 'ch33') {
      // Ch. 33 — MHA based on in-person vs online and ratio
      if (tt == TrainingTime.less) {
        monthly = 0;
        label   = 'Less than 1/2 time — \$0 MHA';
      } else if (onlineOnly) {
        monthly = ((mhaFullOnline ?? 0) * (tier.mhaMultiplier ?? 0)).round();
        label   = '${tt.label} · online rate';
      } else {
        monthly = ((mhaFullInperson ?? 0) * (tier.mhaMultiplier ?? 1.0)).round();
        label   = tt == TrainingTime.full
            ? 'Full-time in-person'
            : '${tt.label} · ${(ratio * 100).round()}% of full-time rate';
      }
    } else {
      // Flat rate benefits — Ch. 30, 35, 1606
      monthly = tier.monthlyRate ?? 0;
      label   = tt.label;
    }

    // Build tier display list
    final tierDisplay = tiers.map((t) {
      final isActive = t.id == _ttId(tt);
      int amt = 0;
      if (id == 'ch33') {
        if (t.id == 'less') {
          amt = 0;
        } else if (onlineOnly) {
          amt = ((mhaFullOnline ?? 0) * (t.onlineMultiplier ?? 0)).round();
        } else {
          amt = ((mhaFullInperson ?? 0) * (t.mhaMultiplier ?? 0)).round();
        }
      } else {
        amt = t.monthlyRate ?? 0;
      }
      return BahTierDisplay(
        label:    t.label,
        amount:   amt,
        isActive: isActive,
        isZero:   amt == 0 && t.id == 'less',
      );
    }).toList();

    return BahResult(
      monthlyAmount: monthly,
      trainingTime:  tt,
      ratio:         ratio,
      label:         label,
      note:          id == 'ch33' && !onlineOnly && tt != TrainingTime.full && tt != TrainingTime.less
          ? 'At least one in-person class keeps you off the online-only rate.'
          : note,
      isZeroMha:     tt == TrainingTime.less && id == 'ch33',
      tiers:         tierDisplay,
    );
  }

  static String _ttId(TrainingTime tt) {
    switch (tt) {
      case TrainingTime.full:         return 'full';
      case TrainingTime.threeQuarter: return 'three_quarter';
      case TrainingTime.half:         return 'half';
      case TrainingTime.less:         return 'less';
    }
  }
}

// ---------------------------------------------------------------------------
// SummerSession — from summer_sessions array in JSON
// ---------------------------------------------------------------------------
class SummerSession {
  final String id;
  final String label;
  final String sessions;
  final String datesNote;
  final int weeks;
  final int ftHoursUndergrad;
  final int ftHoursGraduate;
  final int maxHours;

  const SummerSession({
    required this.id,
    required this.label,
    required this.sessions,
    required this.datesNote,
    required this.weeks,
    required this.ftHoursUndergrad,
    required this.ftHoursGraduate,
    required this.maxHours,
  });

  factory SummerSession.fromJson(Map<String, dynamic> j) => SummerSession(
        id:               j['id'] as String,
        label:            j['label'] as String,
        sessions:         j['sessions'] as String,
        datesNote:        j['dates_note'] as String,
        weeks:            j['weeks'] as int,
        ftHoursUndergrad: j['ft_hours_undergrad'] as int,
        ftHoursGraduate:  j['ft_hours_graduate'] as int,
        maxHours:         j['max_hours'] as int,
      );

  int ftHours(bool isGraduate) =>
      isGraduate ? ftHoursGraduate : ftHoursUndergrad;
}

// ---------------------------------------------------------------------------
// BahResult — output of a calculation
// ---------------------------------------------------------------------------
class BahResult {
  final int monthlyAmount;
  final TrainingTime trainingTime;
  final double ratio;
  final String label;
  final String note;
  final bool isZeroMha;
  final bool isCounselorDriven;
  final bool isTuitionOnly;
  final List<BahTierDisplay> tiers;

  const BahResult({
    required this.monthlyAmount,
    required this.trainingTime,
    this.ratio = 1.0,
    required this.label,
    required this.note,
    this.isZeroMha = false,
    this.isCounselorDriven = false,
    this.isTuitionOnly = false,
    required this.tiers,
  });
}

class BahTierDisplay {
  final String label;
  final int amount;
  final bool isActive;
  final bool isZero;

  const BahTierDisplay({
    required this.label,
    required this.amount,
    required this.isActive,
    required this.isZero,
  });
}
