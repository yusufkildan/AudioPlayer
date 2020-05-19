//
//  ParserPropertyChangeCallback.swift
//  AudioPlayer
//
//  Created by Yusuf Kildan on 17.05.2020.
//  Copyright © 2020 Yusuf Kildan. All rights reserved.
//

import Foundation
import AVFoundation

func ParserPropertyChangeCallback(
    _ context: UnsafeMutableRawPointer,
    _ streamID: AudioFileStreamID,
    _ propertyID: AudioFileStreamPropertyID,
    _ flags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>
) {
    let parser = Unmanaged<DefaultParser>.fromOpaque(context).takeUnretainedValue()
    
    /// Parse the various properties
    switch propertyID {
    case kAudioFileStreamProperty_DataFormat:
        var format = AudioStreamBasicDescription()
        GetPropertyValue(&format, streamID, propertyID)
        parser.dataFormat = AVAudioFormat(streamDescription: &format)
    case kAudioFileStreamProperty_AudioDataPacketCount:
        GetPropertyValue(&parser.packetCount, streamID, propertyID)
    default:
        break
    }
}

// MARK: - Utils

/// Generic method for getting an AudioFileStream property. This method takes care of getting the size of the property and takes in the
/// expected value type and reads it into the value provided. Note it is an inout method so the value passed in will be mutated.
///  This is not as functional as we'd like, but allows us to make this method generic.
/// - Parameters:
///   - value: A value of the expected type of the underlying property
///   - streamID: An `AudioFileStreamID` representing the current audio file stream parser.
///   - propertyID: An `AudioFileStreamPropertyID` representing the particular property to get.
func GetPropertyValue<T>(
    _ value: inout T,
    _ streamID: AudioFileStreamID,
    _ propertyID: AudioFileStreamPropertyID
) {
    var propSize: UInt32 = 0
    guard AudioFileStreamGetPropertyInfo(streamID, propertyID, &propSize, nil) == noErr else {
        return
    }
    
    guard AudioFileStreamGetProperty(streamID, propertyID, &propSize, &value) == noErr else {
        return
    }
}
