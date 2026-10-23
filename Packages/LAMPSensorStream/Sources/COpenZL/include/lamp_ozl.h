// lamp_ozl.h: the only OpenZL API that mindLAMP clients call.
//
// Compresses and decompresses accelerometer frames for the sensor-stream
// contract (LAMP-protocol/docs/sensor-stream.md). A frame is N packed
// 20-byte little-endian records: int64 timestamp, float32 x, y, z.
//
// The same source file is compiled by the golden-vector generator
// (LAMP-protocol), the Android JNI library and the iOS Swift package, so every
// platform builds the identical OpenZL graph.

#ifndef LAMP_OZL_H
#define LAMP_OZL_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Size of one packed accelerometer record, in bytes.
#define LAMP_OZL_RECORD_SIZE 20

// OpenZL frame format version written by lamp_ozl_compress_accel(). Pinned so
// that frames stay readable by every deployed decoder (OpenZL v0.2.0+).
#define LAMP_OZL_FORMAT_VERSION 24

// Error codes. Every function returns a value >= 0 on success.
#define LAMP_OZL_ERR_ARGUMENT -1  // NULL pointer, or size not a multiple of 20.
#define LAMP_OZL_ERR_CAPACITY -2  // Destination buffer too small.
#define LAMP_OZL_ERR_OPENZL -3    // OpenZL reported an error.
#define LAMP_OZL_ERR_FORMAT -4    // Frame is not a single serial output.

// Returns the worst-case compressed size for src_size input bytes.
size_t lamp_ozl_compress_bound(size_t src_size);

// Compresses src_size bytes of packed records (src_size must be a non-zero
// multiple of 20) into dst. Returns the compressed size, or a negative error.
int64_t lamp_ozl_compress_accel(const void* src, size_t src_size, void* dst,
                                size_t dst_capacity);

// Returns the decompressed size stored in a frame, or a negative error.
int64_t lamp_ozl_decompressed_size(const void* src, size_t src_size);

// Returns the OpenZL format version of a frame, or a negative error.
int64_t lamp_ozl_frame_format_version(const void* src, size_t src_size);

// Decompresses a frame into dst. Fails with LAMP_OZL_ERR_FORMAT unless the
// frame has exactly one output. Returns the decompressed size, or a negative
// error.
int64_t lamp_ozl_decompress(const void* src, size_t src_size, void* dst,
                            size_t dst_capacity);

#ifdef __cplusplus
}
#endif

#endif  // LAMP_OZL_H
