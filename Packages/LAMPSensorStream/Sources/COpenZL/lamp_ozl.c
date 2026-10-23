// lamp_ozl.c: implementation of lamp_ozl.h. See that file for the contract.

#include "lamp_ozl.h"

#include "openzl/codecs/zl_conversion.h"
#include "openzl/codecs/zl_delta.h"
#include "openzl/codecs/zl_field_lz.h"
#include "openzl/codecs/zl_split_by_struct.h"
#include "openzl/codecs/zl_transpose.h"
#include "openzl/codecs/zl_zstd.h"
#include "openzl/zl_compress.h"
#include "openzl/zl_compressor.h"
#include "openzl/zl_decompress.h"
#include "openzl/zl_errors.h"

// Builds the accelerometer graph on compressor:
//   split each 20-byte record into fields {8, 4, 4, 4};
//   timestamp -> little-endian int64 -> delta -> field LZ;
//   x, y, z   -> byte-plane transpose -> zstd.
static ZL_GraphID build_accel_graph(ZL_Compressor* compressor) {
  ZL_GraphID timestamp = ZL_Compressor_registerStaticGraph_fromPipelineNodes1o(
      compressor, ZL_NODELIST(ZL_NODE_INTERPRET_TOKEN_AS_LE, ZL_NODE_DELTA_INT),
      ZL_GRAPH_FIELD_LZ);
  ZL_GraphID axis = ZL_Compressor_registerStaticGraph_fromNode1o(
      compressor, ZL_NODE_TRANSPOSE_SPLIT, ZL_GRAPH_ZSTD);
  const size_t field_sizes[4] = {8, 4, 4, 4};
  const ZL_GraphID successors[4] = {timestamp, axis, axis, axis};
  return ZL_Compressor_registerSplitByStructGraph(compressor, field_sizes,
                                                  successors, 4);
}

size_t lamp_ozl_compress_bound(size_t src_size) {
  return ZL_compressBound(src_size);
}

int64_t lamp_ozl_compress_accel(const void* src, size_t src_size, void* dst,
                                size_t dst_capacity) {
  if (src == NULL || dst == NULL || src_size == 0 ||
      src_size % LAMP_OZL_RECORD_SIZE != 0) {
    return LAMP_OZL_ERR_ARGUMENT;
  }
  int64_t result = LAMP_OZL_ERR_OPENZL;
  ZL_Compressor* compressor = ZL_Compressor_create();
  ZL_CCtx* cctx = ZL_CCtx_create();
  if (compressor == NULL || cctx == NULL) goto done;
  if (ZL_isError(ZL_Compressor_setParameter(compressor, ZL_CParam_formatVersion,
                                            LAMP_OZL_FORMAT_VERSION))) {
    goto done;
  }
  ZL_GraphID graph = build_accel_graph(compressor);
  if (ZL_isError(ZL_Compressor_selectStartingGraphID(compressor, graph))) {
    goto done;
  }
  if (ZL_isError(ZL_CCtx_refCompressor(cctx, compressor))) goto done;
  if (ZL_isError(ZL_CCtx_setParameter(cctx, ZL_CParam_formatVersion,
                                      LAMP_OZL_FORMAT_VERSION))) {
    goto done;
  }
  ZL_Report report = ZL_CCtx_compress(cctx, dst, dst_capacity, src, src_size);
  if (ZL_isError(report)) {
    result = ZL_errorCode(report) == ZL_ErrorCode_dstCapacity_tooSmall
                 ? LAMP_OZL_ERR_CAPACITY
                 : LAMP_OZL_ERR_OPENZL;
    goto done;
  }
  result = (int64_t)ZL_validResult(report);
done:
  ZL_CCtx_free(cctx);
  ZL_Compressor_free(compressor);
  return result;
}

int64_t lamp_ozl_decompressed_size(const void* src, size_t src_size) {
  if (src == NULL || src_size == 0) return LAMP_OZL_ERR_ARGUMENT;
  ZL_Report report = ZL_getDecompressedSize(src, src_size);
  if (ZL_isError(report)) return LAMP_OZL_ERR_OPENZL;
  return (int64_t)ZL_validResult(report);
}

int64_t lamp_ozl_frame_format_version(const void* src, size_t src_size) {
  if (src == NULL || src_size == 0) return LAMP_OZL_ERR_ARGUMENT;
  ZL_FrameInfo* info = ZL_FrameInfo_create(src, src_size);
  if (info == NULL) return LAMP_OZL_ERR_OPENZL;
  ZL_Report report = ZL_FrameInfo_getFormatVersion(info);
  ZL_FrameInfo_free(info);
  if (ZL_isError(report)) return LAMP_OZL_ERR_OPENZL;
  return (int64_t)ZL_validResult(report);
}

int64_t lamp_ozl_decompress(const void* src, size_t src_size, void* dst,
                            size_t dst_capacity) {
  if (src == NULL || dst == NULL || src_size == 0) return LAMP_OZL_ERR_ARGUMENT;
  ZL_Report outputs = ZL_getNumOutputs(src, src_size);
  if (ZL_isError(outputs)) return LAMP_OZL_ERR_OPENZL;
  if (ZL_validResult(outputs) != 1) return LAMP_OZL_ERR_FORMAT;
  ZL_DCtx* dctx = ZL_DCtx_create();
  if (dctx == NULL) return LAMP_OZL_ERR_OPENZL;
  ZL_Report report = ZL_DCtx_decompress(dctx, dst, dst_capacity, src, src_size);
  ZL_DCtx_free(dctx);
  if (ZL_isError(report)) {
    return ZL_errorCode(report) == ZL_ErrorCode_dstCapacity_tooSmall
               ? LAMP_OZL_ERR_CAPACITY
               : LAMP_OZL_ERR_OPENZL;
  }
  return (int64_t)ZL_validResult(report);
}
