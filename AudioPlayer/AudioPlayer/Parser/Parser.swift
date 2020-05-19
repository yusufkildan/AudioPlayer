//
//  Parser.swift
//  AudioPlayer
//
//  Created by Yusuf Kildan on 16.05.2020.
//  Copyright © 2020 Yusuf Kildan. All rights reserved.
//

import AVFoundation

protocol Parser: class {
    
    // MARK: - Properties
    
    /// A dataFormat property that describes the format of the audio packets.
    var dataFormat: AVAudioFormat? { get }
    
    /// A duration property that describes the total duration of the file in seconds.
    var duration: TimeInterval? { get }
    
    /// An isParsingComplete property indicating whether all the packets have been parsed.
    /// This will always be evaluated as the count of the packets property being equal to the totalPacketCount property.
    var isParsingComplete: Bool { get }
    
    /// A packets property that holds an array of duples.
    /// Each duple contains a chunk of binary audio data (Data) and an optional packet description (AudioStreamPacketDescription) if it is a compressed format.
    var packets: [(Data, AudioStreamPacketDescription?)] { get }
    
    /// A totalFrameCount property that describes the total amount of frames in the entire audio file.
    var totalFrameCount: AVAudioFrameCount? { get }
    
    /// A totalPacketCount property that describes the total amount of packets in the entire audio file.
    var totalPacketCount: AVAudioPacketCount? { get }
    
    // MARK: - Methods
    
    /// Takes in binary audio data and progressively parses it to provide us the properties listed above.
    func parse(data: Data) throws
    
    /// Provides a frame offset given a time in seconds
    func frameOffset(forTime time: TimeInterval) -> AVAudioFramePosition?
    
    /// Provides a packet offset given a frame.
    func packetOffset(forFrame frame: AVAudioFramePosition) -> AVAudioPacketCount?
    
    /// Provides a time offset given a frame
    func timeOffset(forFrame frame: AVAudioFrameCount) -> TimeInterval?
}

extension Parser {
    
    var duration: TimeInterval? {
        guard let sampleRate = dataFormat?.sampleRate else {
            return nil
        }
        
        guard let totalFrameCount = totalFrameCount else {
            return nil
        }
        
        return TimeInterval(totalFrameCount) / TimeInterval(sampleRate)
    }
    
    var totalFrameCount: AVAudioFrameCount? {
        guard let framesPerPacket = dataFormat?.streamDescription.pointee.mFramesPerPacket else {
            return nil
        }
        
        guard let totalPacketCount = totalPacketCount else {
            return nil
        }
        
        return AVAudioFrameCount(totalPacketCount) * AVAudioFrameCount(framesPerPacket)
    }
    
    var isParsingComplete: Bool {
        guard let totalPacketCount = totalPacketCount else {
            return false
        }
        
        return packets.count == totalPacketCount
    }
    
    func frameOffset(forTime time: TimeInterval) -> AVAudioFramePosition? {
        guard let _ = dataFormat?.streamDescription.pointee,
            let frameCount = totalFrameCount,
            let duration = duration else {
                return nil
        }
        
        let ratio = time / duration
        return AVAudioFramePosition(Double(frameCount) * ratio)
    }
    
    func packetOffset(forFrame frame: AVAudioFramePosition) -> AVAudioPacketCount? {
        guard let framesPerPacket = dataFormat?.streamDescription.pointee.mFramesPerPacket else {
            return nil
        }
        
        return AVAudioPacketCount(frame) / AVAudioPacketCount(framesPerPacket)
    }
    
    func timeOffset(forFrame frame: AVAudioFrameCount) -> TimeInterval? {
        guard let _ = dataFormat?.streamDescription.pointee,
            let frameCount = totalFrameCount,
            let duration = duration else {
                return nil
        }
        
        return TimeInterval(frame) / TimeInterval(frameCount) * duration
    }
}

final class DefaultParser: Parser {
    
    // MARK: - Properties
    
    var dataFormat: AVAudioFormat?
    var packets: [(Data, AudioStreamPacketDescription?)] = []
    var totalPacketCount: AVAudioPacketCount? {
        if dataFormat == nil { return nil }
        
        return max(AVAudioPacketCount(packetCount), AVAudioPacketCount(packets.count))
    }
    
    /// A `UInt64` corresponding to the total frame count parsed by the Audio File Stream Services
    var frameCount: UInt64 = 0
    
    /// A `UInt64` corresponding to the total packet count parsed by the Audio File Stream Services
    var packetCount: UInt64 = 0
    
    /// The `AudioFileStreamID` used by the Audio File Stream Services for converting the binary data into audio packets
    private var streamID: AudioFileStreamID?
    
    // MARK: - Initializers
    
    init() throws {
        // We're creating a context object that we can pass into the AudioFileStreamOpen method
        // that will allow us to access our Parser class instance within static C methods.
        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        
        let streamOpen = AudioFileStreamOpen(
            context,
            ParserPropertyChangeCallback,
            ParserPacketCallback,
            kAudioFileMP3Type,
            &streamID
        )
        
        if streamOpen != noErr {
            throw ParserError.streamCouldNotOpen
        }
    }
    
    // MARK: - Methods
    
    func parse(data: Data) throws {
        
    }
}
