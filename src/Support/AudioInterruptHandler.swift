//
//  AudioInterruptHandler.swift
//  OpenAI
//
//  Created by Eric DeLabar on 2/20/25.
//

import Foundation
import AVFoundation
import os

protocol AudioInterruptHandlerDelegate: Sendable {
    func audioInterrupted(reason: AVAudioSession.InterruptionReason?)
    func audioInterruptionEnded(shouldResume: Bool)
}

final class AudioInterruptHandler: NSObject, @unchecked Sendable {
    
    let audioInterruptedLock = OSAllocatedUnfairLock()
    var _audioInterrupted: (@Sendable (AVAudioSession.InterruptionReason?) -> Void)?
    var audioInterrupted: (@Sendable (AVAudioSession.InterruptionReason?) -> Void)? {
        get {
            audioInterruptedLock.withLock { self._audioInterrupted }
        }
        set {
            audioInterruptedLock.withLock { self._audioInterrupted = newValue }
        }
    }
    
    let audioInterruptionEndedLock = OSAllocatedUnfairLock()
    var _audioInterruptionEnded: (@Sendable (Bool) -> Void)?
    var audioInterruptionEnded: (@Sendable (Bool) -> Void)? {
        get {
            audioInterruptionEndedLock.withLock { self._audioInterruptionEnded }
        }
        set {
            audioInterruptionEndedLock.withLock { self._audioInterruptionEnded = newValue }
        }
    }
    
    override init() {
        super.init()
        
        // Get the default notification center instance.
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(handleAudioSessionInterruption),
                       name: AVAudioSession.interruptionNotification,
                       object: AVAudioSession.sharedInstance())
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @MainActor
    @objc func handleAudioSessionInterruption(notification: Notification) {
        guard let info = notification.userInfo else {
            return
        }
        
        var interruptReason: AVAudioSession.InterruptionReason?
        if let reasonValue = info[AVAudioSessionInterruptionReasonKey] as? UInt,
           let reason = AVAudioSession.InterruptionReason(rawValue: reasonValue) {
            interruptReason = reason
        }
        
        guard let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began: // system began interrupting the audio
            
            audioInterrupted?(interruptReason)
            
        case .ended: // system ended interrupting the audio
            guard let info = notification.userInfo else {
                return
            }
            
            guard let optionValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionValue)

            audioInterruptionEnded?(options.contains(.shouldResume))
            
        @unknown default:
            fatalError("🎤❌ Unknown AVAudioSession.InterruptionType: \(typeValue)")
        }
    }
    
}
