// mindLAMP
//
// JSON persistence for the video upload queue. Protocol + file-backed implementation for production and tests.

import Foundation

// MARK: - Protocol (unit-test seam)

/// Persists `VideoDiaryUploadJob` records and a queue index under a dedicated Application Support subtree.
protocol VideoDiaryUploadJobStoring: Sendable {
    /// Root directory for `jobs/`, `videos/`, and the queue index (created on first use).
    var rootDirectory: URL { get }

    func loadQueueIndex() throws -> VideoDiaryUploadQueueIndex
    func saveQueueIndex(_ index: VideoDiaryUploadQueueIndex) throws
    func saveJob(_ job: VideoDiaryUploadJob) throws
    func loadJob(id: UUID) throws -> VideoDiaryUploadJob
    func deleteJobFile(id: UUID) throws
    /// Copies the recorded file into `videos/{jobId}.ext` and returns the **filename only** stored on the job.
    func stageVideoFile(from sourceURL: URL, jobId: UUID) throws -> String
    func videoFileURL(fileName: String) throws -> URL
    /// Deletes all staged videos, job JSON, and clears the queue index.
    func removeAllUploadData() throws
    /// Removes the job JSON and staged video file for one job.
    func removeArtifacts(jobId: UUID, videoFileName: String) throws
}

// MARK: - File-backed store

/// Default store: `Application Support/VideoDiaryUploads/{queue.json,jobs,videos}`.
final class FileVideoDiaryUploadJobStore: VideoDiaryUploadJobStoring, @unchecked Sendable {
    let rootDirectory: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Production convenience: `Application Support/{subdirectory}/`.
    convenience init(
        fileManager: FileManager = .default,
        applicationSupportSubdirectory: String = "VideoDiaryUploads"
    ) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let root = base.appendingPathComponent(applicationSupportSubdirectory, isDirectory: true)
        self.init(fileManager: fileManager, rootDirectory: root)
    }

    /// Designated initializer — inject any folder (use a temp `URL` in unit tests).
    init(fileManager: FileManager, rootDirectory: URL) {
        self.fileManager = fileManager
        self.rootDirectory = rootDirectory
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    func loadQueueIndex() throws -> VideoDiaryUploadQueueIndex {
        let url = queueIndexURL
        guard fileManager.fileExists(atPath: url.path) else {
            return .empty
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(VideoDiaryUploadQueueIndex.self, from: data)
    }

    func saveQueueIndex(_ index: VideoDiaryUploadQueueIndex) throws {
        try ensureDirectories()
        try writeJSON(index, to: queueIndexURL)
    }

    func saveJob(_ job: VideoDiaryUploadJob) throws {
        try ensureDirectories()
        try writeJSON(job, to: jobFileURL(id: job.id))
    }

    func loadJob(id: UUID) throws -> VideoDiaryUploadJob {
        let data = try Data(contentsOf: jobFileURL(id: id))
        return try decoder.decode(VideoDiaryUploadJob.self, from: data)
    }

    func deleteJobFile(id: UUID) throws {
        let url = jobFileURL(id: id)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func stageVideoFile(from sourceURL: URL, jobId: UUID) throws -> String {
        try ensureDirectories()
        let ext = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
        let fileName = "\(jobId.uuidString).\(ext)"
        let dest = videosDirectory.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: dest.path) {
            try fileManager.removeItem(at: dest)
        }
        try fileManager.copyItem(at: sourceURL, to: dest)
        // Avoid backing up large temp uploads to iCloud.
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableDest = dest
        try mutableDest.setResourceValues(resourceValues)
        return fileName
    }

    func videoFileURL(fileName: String) throws -> URL {
        let url = videosDirectory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: url.path) else {
            throw VideoDiaryUploadStoreError.missingStagedVideo
        }
        return url
    }

    func removeAllUploadData() throws {
        if fileManager.fileExists(atPath: rootDirectory.path) {
            try fileManager.removeItem(at: rootDirectory)
        }
    }

    func removeArtifacts(jobId: UUID, videoFileName: String) throws {
        try deleteJobFile(id: jobId)
        let videoURL = videosDirectory.appendingPathComponent(videoFileName)
        if fileManager.fileExists(atPath: videoURL.path) {
            try fileManager.removeItem(at: videoURL)
        }
    }

    // MARK: - Private

    private var queueIndexURL: URL {
        rootDirectory.appendingPathComponent("queue.json", isDirectory: false)
    }

    private var jobsDirectory: URL {
        rootDirectory.appendingPathComponent("jobs", isDirectory: true)
    }

    private var videosDirectory: URL {
        rootDirectory.appendingPathComponent("videos", isDirectory: true)
    }

    private func jobFileURL(id: UUID) -> URL {
        jobsDirectory.appendingPathComponent("\(id.uuidString).json", isDirectory: false)
    }

    private func ensureDirectories() throws {
        if !fileManager.fileExists(atPath: rootDirectory.path) {
            try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: jobsDirectory.path) {
            try fileManager.createDirectory(at: jobsDirectory, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: videosDirectory.path) {
            try fileManager.createDirectory(at: videosDirectory, withIntermediateDirectories: true)
        }
    }

    private func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try encoder.encode(value)
        // `.atomic` writes to a temporary file and replaces the destination safely.
        try data.write(to: url, options: [.atomic])
    }
}

enum VideoDiaryUploadStoreError: Error {
    case missingStagedVideo
}
