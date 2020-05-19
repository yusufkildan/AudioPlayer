//
//  DownloaderDelegate.swift
//  AudioPlayer
//
//  Created by Yusuf Kildan on 16.05.2020.
//  Copyright © 2020 Yusuf Kildan. All rights reserved.
//

import Foundation

protocol DownloaderDelegate: class {
    func downloader(_ downloader: Downloader, didChangeState state: DownloaderState)
    func downloader(_ downloader: Downloader, didCompleteWithError error: Error?)
    func downloader(_ downloader: Downloader, didReceiveData data: Data, progress: Float)
}
