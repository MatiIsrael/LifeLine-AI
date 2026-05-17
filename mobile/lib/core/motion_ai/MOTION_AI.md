# Lifeline AI — Edge Motion Detection Architecture

## Overview

On-device motion intelligence runs entirely on the phone (edge AI). No sensor data is uploaded for classification. A rule-based classifier runs today; TensorFlow Lite can replace or ensemble it when `assets/models/motion_classifier.tflite` is added.

---

## Data flow

```
Accelerometer (sensors_plus)  ──┐
                                ├──► Batch timer (~200ms)
Gyroscope (sensors_plus)      ──┘           │
                                            ▼
                              Sliding window (64 samples)
                                            │
                                            ▼
                              MotionFeatureExtractor
                              (max G, jerk, gyro var, free-fall…)
                                            │
                                            ▼
                              EdgeMotionClassifier
                              (+ optional TfliteMotionClassifier)
                                            │
                            confidence ≥ threshold & cooldown OK
                                            ▼
                              EmergencyVerificationDialog
                              (20s default — "I'm OK" / "Need Help")
                                            │
                         no response / Need Help ──► SOS API + contacts
```

**Background path:** `BackgroundMonitorService` runs the same pipeline inside an Android foreground service and sends `motion_detected` events to the Flutter UI isolate.

---

## How detection works

| Event | Signal pattern |
|-------|----------------|
| **Fall** | Free-fall (accel &lt; ~0.5g) then impact (&gt; ~2.6g) |
| **Car crash** | Very high impact (&gt; ~4g) + low post-impact variance |
| **Panic** | Multiple high peaks + high gyro variance |
| **Abnormal** | Large jerk without fall/crash signature |
| **Inactivity** | Low variance after recent high impact (possible unconsciousness) |

**False positive reduction:**
- Minimum confidence score (72–84% depending on sensitivity)
- Cooldown between alerts (3–5 minutes)
- Per-type enable toggles in settings
- Human verification step before SOS
- Tunable `aiSensitivity` slider (strict ↔ sensitive)

---

## Battery optimization

| Technique | Detail |
|-----------|--------|
| **Batching** | Sensors sampled by OS; pipeline runs every ~200ms, not per event |
| **Normal sensor rate** | `SensorInterval.normalInterval` (~50Hz cap) |
| **Window size** | Fixed 64-sample buffer — O(1) memory |
| **Cooldown** | No repeated alerts for several minutes |
| **Foreground only when needed** | Background service stops when user disables monitoring |
| **No cloud ML** | Zero network cost for classification |
| **Disarm on logout** | Pipeline stopped when triggers disarmed |

---

## File map

```
motion_ai/
  config/motion_detection_thresholds.dart
  models/motion_event_type.dart
  models/motion_features.dart
  models/motion_detection_result.dart
  pipeline/motion_sensor_sample.dart
  pipeline/motion_feature_extractor.dart
  pipeline/edge_motion_classifier.dart
  pipeline/tflite_motion_classifier.dart
  pipeline/motion_detection_pipeline.dart
  services/motion_ai_monitor_service.dart
  motion_ai_bridge.dart
```

---

## TensorFlow Lite (optional)

1. Train a small model on feature vectors (12 floats).
2. Place at `assets/models/motion_classifier.tflite`.
3. Add `tflite_flutter` to `pubspec.yaml`.
4. Implement inference in `TfliteMotionClassifier.classify()`.

Until then, rule-based edge logic is production-ready.
