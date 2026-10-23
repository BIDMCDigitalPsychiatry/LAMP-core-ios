# LAMP-core-ios
Core scaffolding for digital phenotyping apps with reactive user interfaces. (iOS)

## Sensor-stream sensors

The app collects five sensors defined by the sensor-stream contract
(`LAMP-protocol/docs/sensor-stream.md`). They run on iPhone only; the watch
app is unchanged.

| Spec | What the app does |
|---|---|
| `lamp.accelerometer10hz`, `20hz`, `50hz`, `100hz` | Samples `CMMotionManager` at 10 to 100 Hz, converts to m/s² in Android axes, and stores compressed 5-minute frames in `Documents/SensorStream`. `BackgroundServices` uploads them to `POST /participant/{id}/sensor-stream`. |
| `lamp.gps1m` | Requests best-accuracy continuous location and keeps one fix per 60 s, sent as `lamp.gps1m` sensor events through the existing JSON upload. |

### Precedence

`SensorStreamRouting` decides which collectors run:

- If several accelerometer tiers are configured, only the fastest runs.
- Any accelerometer tier replaces the legacy 5 Hz `lamp.accelerometer` JSON
  stream, so two motion streams never compete. `lamp.device_motion` still runs.
- `lamp.gps1m` runs alongside `lamp.gps`; each keeps its own spec.

### Background behavior

Motion updates continue in the background only while the app's continuous
location updates keep it running (`UIBackgroundModes` includes `location`).
Uploads run inside `beginBackgroundTask`. Frames survive app termination: open
frames are appended to disk every 5 s and sealed on the next start.

### Code

- `Packages/LAMPSensorStream`: the local Swift package (encoding, storage,
  upload policy) with OpenZL vendored from source. See its
  [README](Packages/LAMPSensorStream/README.md).
- `SharedToWatchExt/SensorManager/HighRateAccelerometer.swift`,
  `Gps1mCollector.swift`, `SensorStreamRouting.swift`, and
  `SharedToWatchExt/OperationQueue/SensorStreamUploader.swift`: the iOS app
  side, compiled into the `mindLAMP` target only.

### Test

```sh
swift test --package-path Packages/LAMPSensorStream
xcodebuild test -project mindLAMP.xcodeproj -scheme mindLAMP \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
