import SwiftUI
import AppKit
import UserNotifications

struct ContentView: View {
    @StateObject private var alarmManager = AlarmManager()
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var notificationDelegate = NotificationDelegate()
    @State private var alarmTime = Date()
    @State private var selectedAudioURL: URL?
    @State private var selectedFileName: String = "No song selected"
    @State private var showAlarmPopup = false

    // New state variables for features
    @State private var hourString: String = ""
    @State private var minuteString: String = ""
    @State private var maxVolume: Float = 1.0
    @State private var fadeInDuration: Double = 30.0  // seconds
    @State private var snoozeDuration: Int = 5  // minutes
    @State private var showMathPuzzle = false
    @State private var mathAnswer: String = ""
    @State private var correctAnswer: Int = 0
    @State private var isSnoozed = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Alarm Clock")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            Divider()

            // Time Picker - Simple Text Entry
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Alarm Time:")
                    .font(.headline)

                HStack(spacing: 10) {
                    TextField("HH", text: $hourString)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
                        .onChange(of: hourString) { _, newValue in
                            // Limit to 2 digits and 0-23 range
                            let filtered = newValue.filter { $0.isNumber }
                            hourString = String(filtered.prefix(2))
                        }

                    Text(":")
                        .font(.title2)

                    TextField("MM", text: $minuteString)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
                        .onChange(of: minuteString) { _, newValue in
                            // Limit to 2 digits and 0-59 range
                            let filtered = newValue.filter { $0.isNumber }
                            minuteString = String(filtered.prefix(2))
                        }

                    Text("(24-hour format)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            // File Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Alarm Song:")
                    .font(.headline)

                HStack {
                    Text(selectedFileName)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Choose Song") {
                        selectAudioFile()
                    }
                    .buttonStyle(.borderedProminent)
                }

                // Test Song Button
                HStack {
                    Button(audioPlayer.isPlaying ? "Stop Test" : "Test Song") {
                        if audioPlayer.isPlaying {
                            audioPlayer.stop()
                        } else {
                            if let url = selectedAudioURL {
                                _ = audioPlayer.play(url: url, loop: false)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedAudioURL == nil)

                    if audioPlayer.isPlaying {
                        Text("Playing...")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            .padding()

            // Volume and Fade-in Controls
            VStack(alignment: .leading, spacing: 12) {
                Text("Alarm Settings:")
                    .font(.headline)

                // Max Volume Slider
                VStack(alignment: .leading, spacing: 4) {
                    Text("Max Volume: \(Int(maxVolume * 100))%")
                        .font(.subheadline)
                    Slider(value: $maxVolume, in: 0.1...1.0)
                }

                // Fade-in Duration
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fade-in Duration: \(Int(fadeInDuration)) seconds")
                        .font(.subheadline)
                    Slider(value: $fadeInDuration, in: 5...120, step: 5)
                }

                // Snooze Duration
                VStack(alignment: .leading, spacing: 4) {
                    Text("Snooze Duration: \(snoozeDuration) minutes")
                        .font(.subheadline)
                    Slider(value: Binding(
                        get: { Double(snoozeDuration) },
                        set: { snoozeDuration = Int($0) }
                    ), in: 1...30, step: 1)
                }
            }
            .padding()

            // Alarm Status Display
            if alarmManager.isAlarmSet, let scheduledTime = alarmManager.scheduledAlarmTime {
                VStack(spacing: 8) {
                    Text("Alarm Status: ACTIVE")
                        .font(.headline)
                        .foregroundColor(.green)

                    Text("Scheduled for: \(alarmManager.formatTime(scheduledTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text("No alarm set")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Set/Disable Alarm Buttons
            HStack(spacing: 15) {
                Button("Set Alarm") {
                    if let hour = Int(hourString), let minute = Int(minuteString),
                       hour >= 0 && hour <= 23, minute >= 0 && minute <= 59 {
                        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                        components.hour = hour
                        components.minute = minute
                        components.second = 0

                        if let alarmDate = Calendar.current.date(from: components) {
                            alarmManager.setAlarm(
                                time: alarmDate,
                                audioURL: selectedAudioURL,
                                maxVolume: maxVolume,
                                fadeInDuration: fadeInDuration
                            )
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedAudioURL == nil || hourString.isEmpty || minuteString.isEmpty)

                Button("Disable Alarm") {
                    alarmManager.disableAlarm()
                    audioPlayer.stop()  // Stop any playing audio
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!alarmManager.isAlarmSet)
            }
            .padding()

            Spacer()
        }
        .frame(width: 550, height: 700)
        .onAppear {
            setupNotifications()
        }
        .sheet(isPresented: $showAlarmPopup) {
            VStack(spacing: 20) {
                Text("⏰ ALARM!")
                    .font(.system(size: 48, weight: .bold))
                    .padding()

                if isSnoozed {
                    Text("Snoozed! Close this or stop alarm completely.")
                        .font(.title3)
                        .foregroundColor(.orange)
                } else {
                    Text("Wake up! It's time!")
                        .font(.title2)
                }

                if showMathPuzzle {
                    // Math Puzzle to Stop Alarm
                    VStack(spacing: 15) {
                        Text("Solve to stop alarm:")
                            .font(.headline)

                        Text(generateMathProblem())
                            .font(.title)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)

                        TextField("Answer", text: $mathAnswer)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                            .multilineTextAlignment(.center)
                            .font(.title2)

                        Button("Submit Answer") {
                            if let answer = Int(mathAnswer), answer == correctAnswer {
                                audioPlayer.stop()
                                showAlarmPopup = false
                                showMathPuzzle = false
                                mathAnswer = ""
                            } else {
                                mathAnswer = ""
                                // Show feedback
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(mathAnswer.isEmpty)
                    }
                    .padding()
                } else {
                    // Both options always available
                    VStack(spacing: 15) {
                        if isSnoozed {
                            Button("Close (Alarm will ring in \(snoozeDuration) min)") {
                                showAlarmPopup = false
                                isSnoozed = false
                            }
                            .buttonStyle(.bordered)
                            .font(.title3)
                            .controlSize(.large)
                        } else {
                            Button("Snooze \(snoozeDuration) min") {
                                snoozeAlarm()
                            }
                            .buttonStyle(.bordered)
                            .font(.title3)
                            .controlSize(.large)
                        }

                        Button("I'm Awake - Stop Alarm") {
                            showMathPuzzle = true
                            generateNewMathProblem()
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.title3)
                        .controlSize(.large)
                    }
                    .padding()
                }
            }
            .padding(40)
            .frame(minWidth: 400, minHeight: 400)
            .interactiveDismissDisabled(true)  // Prevent dismissing without solving
        }
        .onChange(of: showAlarmPopup) { oldValue, newValue in
            // If popup is dismissed (goes from true to false), ensure audio is stopped
            if oldValue == true && newValue == false {
                audioPlayer.stop()
                showMathPuzzle = false
            }
        }
    }

    func setupNotifications() {
        // Set the notification delegate
        UNUserNotificationCenter.current().delegate = notificationDelegate

        // Set the callback for when alarm is triggered
        notificationDelegate.alarmTriggeredCallback = {
            handleAlarmTriggered()
        }

        // Request notification permission
        Task {
            await alarmManager.requestNotificationPermission()
        }
    }

    func handleAlarmTriggered() {
        print("Alarm triggered!")

        // Play the audio file with fade-in
        if let audioURL = alarmManager.scheduledAudioURL {
            _ = audioPlayer.playWithFadeIn(
                url: audioURL,
                targetVolume: maxVolume,
                duration: fadeInDuration
            )
        }

        // Show alarm popup and reset state
        showAlarmPopup = true
        showMathPuzzle = false
        isSnoozed = false  // Reset snooze state for new alarm
    }

    func snoozeAlarm() {
        // Stop audio temporarily
        audioPlayer.stop()

        // Mark as snoozed so UI updates
        isSnoozed = true

        // Schedule new alarm for snooze duration minutes from now
        let snoozeTime = Date().addingTimeInterval(TimeInterval(snoozeDuration * 60))
        alarmManager.setAlarm(
            time: snoozeTime,
            audioURL: selectedAudioURL,
            maxVolume: maxVolume,
            fadeInDuration: fadeInDuration
        )

        print("Alarm snoozed for \(snoozeDuration) minutes - you can still stop it")
    }

    func generateNewMathProblem() {
        let num1 = Int.random(in: 10...50)
        let num2 = Int.random(in: 10...50)
        let operation = Int.random(in: 0...1)

        if operation == 0 {
            // Addition
            correctAnswer = num1 + num2
        } else {
            // Subtraction (ensure positive result)
            if num1 > num2 {
                correctAnswer = num1 - num2
            } else {
                correctAnswer = num2 - num1
            }
        }
    }

    func generateMathProblem() -> String {
        // This displays the current problem
        // We need to reconstruct it from the answer
        // For simplicity, we'll generate it fresh each time the view updates
        let num1 = Int.random(in: 10...50)
        let num2 = Int.random(in: 10...50)
        let operation = Int.random(in: 0...1)

        if operation == 0 {
            correctAnswer = num1 + num2
            return "\(num1) + \(num2) = ?"
        } else {
            if num1 > num2 {
                correctAnswer = num1 - num2
                return "\(num1) - \(num2) = ?"
            } else {
                correctAnswer = num2 - num1
                return "\(num2) - \(num1) = ?"
            }
        }
    }

    func selectAudioFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mp3, .audio]
        panel.message = "Select an MP3 file for your alarm"

        if panel.runModal() == .OK {
            if let url = panel.url {
                selectedAudioURL = url
                selectedFileName = url.lastPathComponent
            }
        }
    }
}
