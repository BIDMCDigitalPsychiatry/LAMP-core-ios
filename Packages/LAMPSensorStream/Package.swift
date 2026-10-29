// swift-tools-version:5.7
//
// LAMPSensorStream: encodes, stores, and uploads high-rate accelerometer frames
// for the sensor-stream contract (LAMP-protocol/docs/sensor-stream.md).
//
// The `SensorStream` target has no UIKit, CoreMotion, or CoreLocation code, so
// you can run its tests on the macOS host with
// `swift test --package-path Packages/LAMPSensorStream`.
import PackageDescription

let package = Package(
    name: "LAMPSensorStream",
    platforms: [.iOS(.v14), .macOS(.v12)],
    products: [.library(name: "SensorStream", targets: ["SensorStream"])],
    targets: [
        // OpenZL v0.3.0, zstd, and lz4, vendored by scripts/vendor-openzl.sh.
        // Only lamp_ozl.h is public.
        .target(
            name: "COpenZL",
            path: "Sources/COpenZL",
            exclude: ["vendor/LICENSES", "vendor/VERSION"],
            sources: ["lamp_ozl.c", "vendor/openzl/src", "vendor/zstd", "vendor/lz4/lz4.c", "vendor/lz4/lz4hc.c"],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("vendor/config"),
                .headerSearchPath("vendor/openzl"),
                .headerSearchPath("vendor/openzl/include"),
                .headerSearchPath("vendor/openzl/src"),
                .headerSearchPath("vendor/zstd"),
                .headerSearchPath("vendor/lz4"),
                .define("_GNU_SOURCE"),
                .define("_REENTRANT"),
                .define("ZSTD_DISABLE_ASM", to: "1"),
                .define("ZSTD_LEGACY_SUPPORT", to: "0"),
                .define("XXH_NAMESPACE", to: "ZSTD_"),
                // SwiftPM and Xcode pass -DDEBUG=1 in debug builds; OpenZL's ZL_LOG(DEBUG, ...)
                // token-pastes DEBUG, so it must stay undefined for this target.
                .unsafeFlags(["-UDEBUG", "-w"]),
            ]),
        .target(name: "SensorStream", dependencies: ["COpenZL"], path: "Sources/SensorStream"),
        .testTarget(
            name: "SensorStreamTests",
            dependencies: ["SensorStream"],
            path: "Tests/SensorStreamTests",
            resources: [.copy("Fixtures")]),
    ],
    cLanguageStandard: .gnu11
)
