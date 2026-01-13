// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AlarmClockApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "AlarmClockApp",
            targets: ["AlarmClockApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "AlarmClockApp",
            path: "AlarmClockApp"
        )
    ]
)
