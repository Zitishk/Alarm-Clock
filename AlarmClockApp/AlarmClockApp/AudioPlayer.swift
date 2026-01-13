import Foundation
import AVFoundation

class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying: Bool = false
    private var fadeTimer: Timer?

    override init() {
        super.init()
        // No audio session configuration needed on macOS
        // AVAudioSession is iOS-specific
    }

    func play(url: URL, loop: Bool = false) -> Bool {
        // Stop any currently playing audio first
        stop()

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self  // Set delegate to track playback
            audioPlayer?.numberOfLoops = loop ? -1 : 0  // -1 means infinite loop
            audioPlayer?.prepareToPlay()

            let success = audioPlayer?.play() ?? false
            if success {
                isPlaying = true
                print("Playing audio: \(url.lastPathComponent) (loop: \(loop))")
            } else {
                print("Failed to start audio playback")
            }
            return success
        } catch {
            print("Failed to play audio: \(error)")
            isPlaying = false
            return false
        }
    }

    func playWithFadeIn(url: URL, targetVolume: Float, duration: Double) -> Bool {
        // Stop any currently playing audio first
        stop()

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = -1  // Infinite loop for alarm
            audioPlayer?.volume = 0.0  // Start at zero volume
            audioPlayer?.prepareToPlay()

            let success = audioPlayer?.play() ?? false
            if success {
                isPlaying = true
                print("Playing audio with fade-in: \(url.lastPathComponent)")
                print("Target volume: \(Int(targetVolume * 100))%, Duration: \(Int(duration))s")

                // Start fade-in
                startFadeIn(targetVolume: targetVolume, duration: duration)
            } else {
                print("Failed to start audio playback")
            }
            return success
        } catch {
            print("Failed to play audio: \(error)")
            isPlaying = false
            return false
        }
    }

    private func startFadeIn(targetVolume: Float, duration: Double) {
        let steps = 100  // Number of volume increments
        let stepDuration = duration / Double(steps)
        let volumeIncrement = targetVolume / Float(steps)

        var currentStep = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }

            currentStep += 1
            let newVolume = volumeIncrement * Float(currentStep)

            if currentStep >= steps {
                player.volume = targetVolume
                timer.invalidate()
                self.fadeTimer = nil
                print("Fade-in complete at \(Int(targetVolume * 100))%")
            } else {
                player.volume = min(newVolume, targetVolume)
            }
        }
    }

    func stop() {
        fadeTimer?.invalidate()
        fadeTimer = nil

        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
            print("Audio stopped")
        }
        audioPlayer = nil
        isPlaying = false
    }

    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }

    // AVAudioPlayerDelegate method - called when audio finishes playing
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Audio finished playing. Success: \(flag)")
        isPlaying = false
    }

    // AVAudioPlayerDelegate method - called on playback error
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio decode error: \(error?.localizedDescription ?? "unknown")")
        isPlaying = false
    }
}
