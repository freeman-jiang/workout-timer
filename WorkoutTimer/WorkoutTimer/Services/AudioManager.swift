import AVFoundation
import Foundation
import os.log

private let logger = Logger(subsystem: "com.workout.timer", category: "AudioManager")

enum SoundEffect: String {
    case countdown = "countdown"
    case highPitch = "phase"
    case lowPitch = "rest"
    case complete = "complete"
}

enum ToneType {
    case countdown   // Short beep for 3-2-1
    case highPitch   // Work phase start (higher frequency)
    case lowPitch    // Rest phase start (lower frequency)
    case complete    // Workout complete
}

/// Thread-safe tone request that gets picked up by the audio render thread
private struct ToneRequest {
    let frequency: Float
    let samplesToPlay: Int
    let fadeInSamples: Int
    let fadeOutSamples: Int
}

@MainActor
final class AudioManager {
    private let audioEngine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!

    private let sampleRate: Float = 48000
    private let amplitude: Float = 0.6

    // Thread-safe communication with audio thread via lock
    private let lock = NSLock()
    private var pendingRequest: ToneRequest?

    // Audio thread state (only accessed from render callback)
    private var currentFrequency: Float = 880
    private var currentPhase: Float = 0
    private var samplesToPlay: Int = 0
    private var fadeInSamples: Int = 200
    private var fadeOutSamples: Int = 200
    private var currentSample: Int = 0

    // Scheduled sound work items
    private var scheduledWorkItems: [DispatchWorkItem] = []

    // Frequency definitions
    private let frequencies: [ToneType: Float] = [
        .countdown: 330,    // E4 - countdown beeps
        .highPitch: 440,    // A4 - work/rest phase transition
        .lowPitch: 440,     // A4 - work/rest phase transition
        .complete: 440      // A4 - workout complete
    ]

    init() {
        setupAudioSession()
        setupAudioEngine()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    private func setupAudioEngine() {
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1)!

        sourceNode = AVAudioSourceNode { [unowned self] _, _, frameCount, audioBufferList -> OSStatus in
            let audioBuffer = UnsafeMutableAudioBufferListPointer(audioBufferList)[0]
            let samples = audioBuffer.mData!.assumingMemoryBound(to: Float.self)

            // Check for pending tone request (thread-safe)
            self.lock.lock()
            if let request = self.pendingRequest {
                self.currentFrequency = request.frequency
                self.samplesToPlay = request.samplesToPlay
                self.fadeInSamples = request.fadeInSamples
                self.fadeOutSamples = request.fadeOutSamples
                self.currentPhase = 0
                self.currentSample = 0
                self.pendingRequest = nil
            }
            self.lock.unlock()

            let phaseDelta = (2.0 * Float.pi * self.currentFrequency) / self.sampleRate

            for i in 0..<Int(frameCount) {
                if self.currentSample < self.samplesToPlay {
                    // Calculate envelope for fade in/out
                    var envelope: Float = 1.0
                    if self.currentSample < self.fadeInSamples {
                        envelope = Float(self.currentSample) / Float(self.fadeInSamples)
                    } else if self.currentSample > self.samplesToPlay - self.fadeOutSamples {
                        let remaining = self.samplesToPlay - self.currentSample
                        envelope = Float(remaining) / Float(self.fadeOutSamples)
                    }

                    samples[i] = sin(self.currentPhase) * self.amplitude * envelope
                    self.currentPhase += phaseDelta
                    if self.currentPhase >= 2.0 * Float.pi {
                        self.currentPhase -= 2.0 * Float.pi
                    }
                    self.currentSample += 1
                } else {
                    samples[i] = 0
                }
            }

            return noErr
        }

        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: audioEngine.mainMixerNode, format: format)

        do {
            try audioEngine.start()
        } catch {
            logger.error("Failed to start audio engine: \(error.localizedDescription)")
        }
    }

    // MARK: - Tone Playback

    func playTone(_ type: ToneType, durationMs: Int = 100) {
        let frequency = frequencies[type] ?? 880
        let totalSamples = Int(sampleRate * Float(durationMs) / 1000.0)

        logger.info("Playing tone: \(String(describing: type)), freq: \(frequency), duration: \(durationMs)ms, samples: \(totalSamples)")

        let request = ToneRequest(
            frequency: frequency,
            samplesToPlay: totalSamples,
            fadeInSamples: 200,
            fadeOutSamples: 200
        )

        lock.lock()
        pendingRequest = request
        lock.unlock()
    }

    // MARK: - Public API

    func playWorkStart() {
        playTone(.highPitch, durationMs: 150)
    }

    func playRestStart() {
        playTone(.lowPitch, durationMs: 150)
    }

    func playCountdownBeep() {
        playTone(.countdown, durationMs: 80)
    }

    func playWorkoutComplete() {
        // Play 3 beeps with delays
        playTone(.lowPitch, durationMs: 150)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.playTone(.lowPitch, durationMs: 150)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.playTone(.lowPitch, durationMs: 150)
        }
    }

    // MARK: - Background Audio (engine stays running)

    func startBackgroundAudio() {
        // Engine is always running, nothing special needed
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                logger.error("Failed to restart audio engine: \(error.localizedDescription)")
            }
        }
    }

    func stopBackgroundAudio() {
        // Keep engine running for quick response, just cancel any scheduled sounds
        cancelScheduledSounds()
    }

    // MARK: - Scheduled Sounds

    func cancelScheduledSounds() {
        logger.info("Cancelling \(self.scheduledWorkItems.count) scheduled sounds")
        for workItem in scheduledWorkItems {
            workItem.cancel()
        }
        scheduledWorkItems.removeAll()
    }

    func scheduleCountdownAndTransition(
        phaseDuration: TimeInterval,
        transitionSound: SoundEffect,
        transitionTimes: Int,
        playTransitionNow: Bool = true
    ) {
        cancelScheduledSounds()

        logger.info("Scheduling sounds for phase duration: \(phaseDuration)s, transition: \(transitionSound.rawValue), times: \(transitionTimes), playNow: \(playTransitionNow)")

        // Delay to sync with UI number transition animation
        let beepOffset: TimeInterval = 0.15

        // Play transition sound with same delay as countdown beeps
        // Heartbeat pattern: two quick beeps
        if playTransitionNow {
            let toneType: ToneType = transitionSound == .highPitch ? .highPitch : .lowPitch
            DispatchQueue.main.asyncAfter(deadline: .now() + beepOffset) { [weak self] in
                self?.playTone(toneType, durationMs: 80)
            }

            // Play additional transition tones if requested (fast heartbeat timing ~150ms apart)
            for i in 1..<transitionTimes {
                DispatchQueue.main.asyncAfter(deadline: .now() + beepOffset + Double(i) * 0.15) { [weak self] in
                    self?.playTone(toneType, durationMs: 80)
                }
            }
        }

        // Schedule countdown beeps at 3, 2, 1 seconds before phase end
        for secondsBefore in 1...3 {
            let delay = phaseDuration - TimeInterval(secondsBefore) + beepOffset
            if delay > 0 {
                let workItem = DispatchWorkItem { [weak self] in
                    self?.playCountdownBeep()
                }
                scheduledWorkItems.append(workItem)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
                logger.info("Scheduled countdown beep at delay: \(delay)s")
            }
        }
    }

    // MARK: - Legacy API for compatibility

    func playSound(_ sound: SoundEffect, times: Int = 1) {
        let toneType: ToneType
        switch sound {
        case .countdown:
            toneType = .countdown
        case .highPitch:
            toneType = .highPitch
        case .lowPitch, .complete:
            toneType = .lowPitch
        }

        playTone(toneType, durationMs: 150)

        if times > 1 {
            for i in 1..<times {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) { [weak self] in
                    self?.playTone(toneType, durationMs: 150)
                }
            }
        }
    }
}
