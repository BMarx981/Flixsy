import 'dart:math' as math;
import 'dart:ui';

/// Snapshot of the sky/water palette at a moment in the day cycle, together
/// with where the sun and moon are. All positions are fractions of the
/// canvas (0..1) so the painter can scale them to any size.
class OceanSkyState {
  const OceanSkyState({
    required this.skyTop,
    required this.skyHorizon,
    required this.waterTop,
    required this.waterDeep,
    required this.horizonGlow,
    required this.horizonGlowAlpha,
    required this.sunPos,
    required this.sunColor,
    required this.sunAlpha,
    required this.moonPos,
    required this.moonColor,
    required this.moonAlpha,
  });

  final Color skyTop;
  final Color skyHorizon;
  final Color waterTop;
  final Color waterDeep;

  /// Warm wash painted just above and below the horizon line — strongest at
  /// sunrise/sunset, absent at midday and midnight.
  final Color horizonGlow;
  final double horizonGlowAlpha;

  /// Sun centre in canvas-fraction coords; only painted when [sunAlpha] > 0.
  /// The sun emerges at the middle-top of the sky and arcs to the west to
  /// set at the same horizon point as the moon.
  final Offset sunPos;
  final Color sunColor;
  final double sunAlpha;

  /// Moon centre in canvas-fraction coords; only painted when [moonAlpha] > 0.
  final Offset moonPos;
  final Color moonColor;
  final double moonAlpha;
}

/// Interpolates an [OceanSkyState] from the cycle parameter [t] (0..1, wraps).
/// Both the sun and the moon are visible at their respective phases; only
/// the moon casts a reflection on the water (the painter handles that).
OceanSkyState oceanSkyStateAt(double t) {
  final cycle = t % 1.0;
  final palette = _lerpPalette(cycle);
  final sun = _sunState(cycle);
  final moon = _moonState(cycle);

  return OceanSkyState(
    skyTop: palette.skyTop,
    skyHorizon: palette.skyHorizon,
    waterTop: palette.waterTop,
    waterDeep: palette.waterDeep,
    horizonGlow: palette.horizonGlow,
    horizonGlowAlpha: palette.horizonGlowAlpha,
    sunPos: sun.pos,
    sunColor: sun.color,
    sunAlpha: sun.alpha,
    moonPos: moon.pos,
    moonColor: moon.color,
    moonAlpha: moon.alpha,
  );
}

class _Keyframe {
  const _Keyframe({
    required this.t,
    required this.skyTop,
    required this.skyHorizon,
    required this.waterTop,
    required this.waterDeep,
    required this.horizonGlow,
    required this.horizonGlowAlpha,
  });

  final double t;
  final Color skyTop;
  final Color skyHorizon;
  final Color waterTop;
  final Color waterDeep;
  final Color horizonGlow;
  final double horizonGlowAlpha;
}

// Day cycle keyframes. The list must be monotonic in `t`, start at 0 and end
// at 1 with matching colours so the cycle wraps without a visible seam.
const List<_Keyframe> _keyframes = [
  _Keyframe(
    t: 0.00,
    skyTop: Color(0xFF050817),
    skyHorizon: Color(0xFF0E1A3F),
    waterTop: Color(0xFF050B22),
    waterDeep: Color(0xFF02030D),
    horizonGlow: Color(0xFF223060),
    horizonGlowAlpha: 0.15,
  ),
  _Keyframe(
    t: 0.18,
    skyTop: Color(0xFF1A1E45),
    skyHorizon: Color(0xFF4A2C5C),
    waterTop: Color(0xFF0A1230),
    waterDeep: Color(0xFF050818),
    horizonGlow: Color(0xFF7A3A5E),
    horizonGlowAlpha: 0.30,
  ),
  _Keyframe(
    t: 0.26,
    skyTop: Color(0xFF5C4E7C),
    skyHorizon: Color(0xFFFFAB7B),
    waterTop: Color(0xFF2B3258),
    waterDeep: Color(0xFF0C1024),
    horizonGlow: Color(0xFFFFB37A),
    horizonGlowAlpha: 0.55,
  ),
  _Keyframe(
    t: 0.38,
    skyTop: Color(0xFF6EA9D4),
    skyHorizon: Color(0xFFBFE0F0),
    waterTop: Color(0xFF1F4566),
    waterDeep: Color(0xFF0A1A30),
    horizonGlow: Color(0xFFE6F0F8),
    horizonGlowAlpha: 0.25,
  ),
  _Keyframe(
    t: 0.50,
    skyTop: Color(0xFF4A92C7),
    skyHorizon: Color(0xFFB5E0F0),
    waterTop: Color(0xFF1F5380),
    waterDeep: Color(0xFF0A1F38),
    horizonGlow: Color(0xFFCFE6F2),
    horizonGlowAlpha: 0.18,
  ),
  _Keyframe(
    t: 0.62,
    skyTop: Color(0xFF6CA8D2),
    skyHorizon: Color(0xFFE8C7A0),
    waterTop: Color(0xFF1F4566),
    waterDeep: Color(0xFF0A1A30),
    horizonGlow: Color(0xFFFFD0A0),
    horizonGlowAlpha: 0.30,
  ),
  _Keyframe(
    t: 0.74,
    skyTop: Color(0xFF5A4E7C),
    skyHorizon: Color(0xFFFF7E5C),
    waterTop: Color(0xFF2A2E58),
    waterDeep: Color(0xFF0C0E24),
    horizonGlow: Color(0xFFFF9060),
    horizonGlowAlpha: 0.60,
  ),
  _Keyframe(
    t: 0.85,
    skyTop: Color(0xFF2A1E45),
    skyHorizon: Color(0xFF5A2A4C),
    waterTop: Color(0xFF14182E),
    waterDeep: Color(0xFF060818),
    horizonGlow: Color(0xFF7A3A5E),
    horizonGlowAlpha: 0.30,
  ),
  _Keyframe(
    t: 1.00,
    skyTop: Color(0xFF050817),
    skyHorizon: Color(0xFF0E1A3F),
    waterTop: Color(0xFF050B22),
    waterDeep: Color(0xFF02030D),
    horizonGlow: Color(0xFF223060),
    horizonGlowAlpha: 0.15,
  ),
];

_Keyframe _lerpPalette(double t) {
  for (var i = 0; i < _keyframes.length - 1; i++) {
    final a = _keyframes[i];
    final b = _keyframes[i + 1];
    if (t >= a.t && t <= b.t) {
      final f = (t - a.t) / (b.t - a.t);
      return _Keyframe(
        t: t,
        skyTop: Color.lerp(a.skyTop, b.skyTop, f)!,
        skyHorizon: Color.lerp(a.skyHorizon, b.skyHorizon, f)!,
        waterTop: Color.lerp(a.waterTop, b.waterTop, f)!,
        waterDeep: Color.lerp(a.waterDeep, b.waterDeep, f)!,
        horizonGlow: Color.lerp(a.horizonGlow, b.horizonGlow, f)!,
        horizonGlowAlpha:
            a.horizonGlowAlpha + (b.horizonGlowAlpha - a.horizonGlowAlpha) * f,
      );
    }
  }
  return _keyframes.last;
}

// Luminary arc constants. The day half is [_sunrise, _sunset]; the night
// half is the rest, with the moon rising on the east (x=0.85) and setting
// on the west (x=0.15).
const double _sunrise = 0.22;
const double _sunset = 0.78;
const double _luminaryEdgeFade = 0.04;
const double _luminaryEastX = 0.85;
const double _luminaryWestX = 0.15;
const double _luminaryPeakLift = 0.85;

// Sun emerges from the middle-top of the screen and arcs down to set at the
// same west-horizon point as the moon. _sunStartX gives a top-centre origin.
// The sun stays invisible through the first half of the day and only fades
// in over the last 50% as it descends, then fades out at the horizon.
const double _sunStartX = 0.50;
const double _sunFadeInStart = 0.50;
const double _sunFadeOut = 0.06;

const Color _sunNoonColor = Color(0xFFFFE9B0);
const Color _sunHorizonColor = Color(0xFFFF8A56);
const Color _moonColor = Color(0xFFE3E9F0);

class _LuminaryState {
  const _LuminaryState({
    required this.pos,
    required this.color,
    required this.alpha,
  });

  final Offset pos;
  final Color color;
  final double alpha;
}

_LuminaryState _sunState(double t) {
  if (t < _sunrise || t > _sunset) {
    return const _LuminaryState(
      pos: Offset.zero,
      color: _sunNoonColor,
      alpha: 0,
    );
  }
  final phase = (t - _sunrise) / (_sunset - _sunrise);

  // Arc: start at middle-top (x=0.5, y=0) and finish at the west horizon
  // (x=_luminaryWestX, y=_horizonFraction). y is eased so the sun lingers
  // up top and accelerates downward as it nears the horizon — the natural
  // rhythm of a setting sun.
  final x = _sunStartX + (_luminaryWestX - _sunStartX) * phase;
  final y = _horizonFraction * math.pow(phase, 1.6).toDouble();

  // Golden when high, warmer and redder as it approaches the horizon.
  final warmth = phase * phase;
  final color = Color.lerp(_sunNoonColor, _sunHorizonColor, warmth)!;

  // Stay invisible through the first half, then fade in across the back
  // half of the day. A short fade-out at the very end lets the sun dissolve
  // into the horizon line at sunset.
  final fadeIn =
      ((phase - _sunFadeInStart) / (1.0 - _sunFadeInStart - _sunFadeOut))
          .clamp(0.0, 1.0);
  final fadeOut = ((1.0 - phase) / _sunFadeOut).clamp(0.0, 1.0);
  final alpha = fadeIn * fadeOut;

  return _LuminaryState(pos: Offset(x, y), color: color, alpha: alpha);
}

_LuminaryState _moonState(double t) {
  // Moon is up during the night half: [_sunset, 1] ∪ [0, _sunrise]. Convert
  // to a single [0, 1] phase by anchoring at sunset.
  final nightLength = (1 - _sunset) + _sunrise;
  final double nightT;
  if (t >= _sunset) {
    nightT = t - _sunset;
  } else if (t <= _sunrise) {
    nightT = (1 - _sunset) + t;
  } else {
    return const _LuminaryState(
      pos: Offset.zero,
      color: _moonColor,
      alpha: 0,
    );
  }
  final phase = nightT / nightLength;
  final x = _luminaryEastX + (_luminaryWestX - _luminaryEastX) * phase;
  final lift = math.sin(phase * math.pi) * _luminaryPeakLift;
  final y = _horizonFraction - _horizonFraction * lift;

  final fadeIn = (nightT / _luminaryEdgeFade).clamp(0.0, 1.0);
  final fadeOut = ((nightLength - nightT) / _luminaryEdgeFade).clamp(0.0, 1.0);
  final alpha = fadeIn * fadeOut * 0.85;

  return _LuminaryState(pos: Offset(x, y), color: _moonColor, alpha: alpha);
}

/// Fraction of canvas height where the horizon line sits. Exposed so the
/// painter and the palette compute identical positions.
const double _horizonFraction = 0.42;
const double oceanHorizonFraction = _horizonFraction;
