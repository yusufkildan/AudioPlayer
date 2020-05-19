//
//  Downloader.swift
//  AudioPlayer
//
//  Created by Yusuf Kildan on 16.05.2020.
//  Copyright © 2020 Yusuf Kildan. All rights reserved.
//

import Foundation

final class Downloader: NSObject {
    
    // MARK: - Properties
    
    weak var delegate: DownloaderDelegate?
    private(set) var progress: Float = 0
    var state: DownloaderState = .notStarted {
        didSet {
            delegate?.downloader(self, didChangeState: state)
        }
    }
    var totalBytesReceived: Int64 = 0
    var totalBytesCount: Int64 = 0
    private lazy var session: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    private var task: URLSessionTask?
    var url: URL? {
        didSet {
            if state == .started {
                stop()
            }
            
            if let url = url {
                progress = 0
                state = .notStarted
                totalBytesCount = 0
                totalBytesReceived = 0
                task = session.dataTask(with: url)
            } else {
                task = nil
            }
        }
    }
    
    // MARK: - Methods
    
    func start() {
        guard let task = task else { return }
        switch state {
        case .completed, .started:
            return
        default:
            state = .started
            task.resume()
        }
    }
    
    func pause() {
        guard let task = task, state == .started else { return }
        state = .paused
        task.suspend()
    }
    
    func stop() {
        guard let task = task, state == .started else { return }
        state = .stopped
        task.cancel()
    }
}

// MARK: - URLSessionDelegate

extension Downloader: URLSessionDataDelegate {
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        totalBytesCount = response.expectedContentLength
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        totalBytesReceived += Int64(data.count)
        progress = Float(totalBytesReceived) / Float(totalBytesCount)
        delegate?.downloader(self, didReceiveData: data, progress: progress)
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        state = .completed
        delegate?.downloader(self, didCompleteWithError: error)
    }
}
