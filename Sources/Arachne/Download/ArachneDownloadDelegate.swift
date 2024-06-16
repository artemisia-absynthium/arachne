//
// ArachneDownloadDelegate.swift - A URLSessionDownloadDelegate and URLSessionTaskDelegate
// which provides the same behavior of async tasks before redirecting to a user defined delegate
// This source file is part of the Arachne open source project
//
// Copyright (c) 2023 artemisia-absynthium
// Licensed under MIT
//
// See https://github.com/artemisia-absynthium/arachne/blob/main/LICENSE for license information
//

import Foundation

class ArachneDownloadDelegate: NSObject, URLSessionDownloadDelegate, URLSessionTaskDelegate {
    private let didResumeDownload: (Int64, Int64) -> Void
    private let didWriteData: (Int64, Int64, Int64) -> Void
    private let didCompleteTask: (URL?, URLResponse?, Error?) -> Void

    private var downloadedFileURL: URL?
    private var fileWriteError: Error?

    init(didResumeDownload: @escaping (Int64, Int64) -> Void,
         didWriteData: @escaping (Int64, Int64, Int64) -> Void,
         didCompleteTask: @escaping (URL?, URLResponse?, Error?) -> Void) {
        self.didResumeDownload = didResumeDownload
        self.didWriteData = didWriteData
        self.didCompleteTask = didCompleteTask
        self.downloadedFileURL = nil
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let tempDestination = try FileManager.default
                .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent(location.lastPathComponent)
            if FileManager.default.fileExists(atPath: tempDestination.path) {
                try FileManager.default.removeItem(at: tempDestination)
            }
            try FileManager.default.copyItem(at: location, to: tempDestination)
            downloadedFileURL = tempDestination
        } catch {
            fileWriteError = error
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        didResumeDownload(fileOffset, expectedTotalBytes)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        didWriteData(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }

    // MARK: - URLSessionTaskDelegate

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        didCompleteTask(downloadedFileURL, task.response, error ?? fileWriteError)
        session.invalidateAndCancel()
    }
}
