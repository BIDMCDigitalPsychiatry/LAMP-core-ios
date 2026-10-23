# LAMPSensorStream

LAMPSensorStream encodes, stores, and uploads the high-rate accelerometer
sensors (`lamp.accelerometer10hz`, `20hz`, `50hz`, `100hz`) and gates
`lamp.gps1m` fixes for the mindLAMP iOS app. The wire format is defined in
the sensor-stream contract, `LAMP-protocol/docs/sensor-stream.md`; the golden
vectors in `Tests/SensorStreamTests/Fixtures` are copied unchanged from
`LAMP-protocol/test-vectors/sensor-stream`.

## Targets

| Target | Contents |
|---|---|
| `COpenZL` | OpenZL v0.3.0, zstd, and lz4, vendored under `Sources/COpenZL/vendor`, plus the `lamp_ozl.c` shim. Only `include/lamp_ozl.h` is public. |
| `SensorStream` | Pure Swift with no UIKit, CoreMotion, or CoreLocation code, so it builds and tests on macOS. |

`SensorStream` contains:

| Type | Role |
|---|---|
| `SensorStreamKey`, `SensorTier` | The five specs; per tier, `accelerometerUpdateInterval` (0.1, 0.05, 0.02, 0.01 s), nominal rate, and the 5 s drain interval. |
| `Gps1mGate` | Keeps at most one `lamp.gps1m` fix per 60 s. |
| `SensorClock` | Converts `CMLogItem.timestamp` (seconds since boot) to epoch ms with one offset per session; a drift over 1,000 ms starts a new session. |
| `AccelerometerSession` | The collector's drain logic: checks drift at each sample's arrival, so samples before a clock change or a deep sleep keep their own session's offset, then hands records to a `FrameRecorder`. |
| `UnitConversion` | Converts g to m/s² in Android axes: `value * -9.80665`, as `Float`. |
| `AccelRecordPacker` | Packs 20-byte little-endian records after a stable sort. |
| `FramePartitioner` | Splits batches into 5-minute windows and applies the close rules; late records become new partial frames and are never dropped. |
| `OpenZLCodec` | Compresses at format version 24 and decodes with the contract's five checks. |
| `FrameStore`, `FrameRecorder` | Keep frames under `Documents/SensorStream/{open,sealed,quarantine}`, appending open frames as records arrive and sealing them crash-safely. `recoverOpenFramesOncePerProcess()` seals frames that an earlier process left open. |
| `MultipartBodyWriter` | Writes the upload body to a file, with the text fields before the `frame` part. |
| `UploadPolicy` | Maps each response status to delete, quarantine, or retry, and to whether the uploader refreshes the session (401 and 403) and backs off. |
| `UploadRunGuard` | Ends an upload run's background task exactly once, and on expiry cancels the request and stops the run. |

## Run the tests

```sh
swift test --package-path Packages/LAMPSensorStream
```

`ProducedArtifactTests` writes a frame, its multipart body, and its metadata
to `$TMPDIR/lamp-ios-produced/` for cross-language checks.

## Update OpenZL

1. Regenerate the vendored tree from the repository root:

   ```sh
   scripts/vendor-openzl.sh Packages/LAMPSensorStream/Sources/COpenZL/vendor v0.3.0
   ```

2. Copy `lamp_ozl.c` and `lamp_ozl.h` unchanged from `LAMP-protocol/tools/openzl/`.
3. Keep `LAMP_OZL_FORMAT_VERSION` at 24 until every decoder (LAMP-cortex,
   LAMP-raphe, and server tooling) reads the newer format.
4. Run the tests; `OpenZLCodecTests` checks that compression still matches the
   golden `frame.openzl` byte for byte.

The `COpenZL` target passes `-UDEBUG` because Xcode and SwiftPM define
`DEBUG=1` in debug builds, which breaks OpenZL's `ZL_LOG(DEBUG, ...)` macro.
Xcode accepts these unsafe flags because the package is local.
