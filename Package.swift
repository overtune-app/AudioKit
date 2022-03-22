// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AudioKit",
    platforms: [.macOS(.v10_13), .iOS(.v11), .tvOS(.v11)],
    products: [.library(name: "AudioKit", targets: ["AudioKit", "AudioKitEX","SoundpipeAudioKit"])],
    dependencies:[
        .package(url: "https://github.com/AudioKit/KissFFT", from: "1.0.0"),
    ],
    targets: [
        .target(name: "AudioKit"),
        .target(name: "AudioKitEX", dependencies: ["AudioKit", "CAudioKitEX"]),
        .target(name: "CAudioKitEX", cxxSettings: [.headerSearchPath(".")]),
        .target(name: "Soundpipe",
                dependencies: ["KissFFT"],
                exclude: ["lib/inih/LICENSE.txt"],
                cSettings: [
                    .headerSearchPath("lib/inih"),
                    .headerSearchPath("Sources/soundpipe/lib/inih"),
                    .headerSearchPath("modules"),
                    .headerSearchPath("external")
                ]),
        .target(name: "SoundpipeAudioKit", dependencies: ["AudioKit", "AudioKitEX", "CSoundpipeAudioKit"]),
        .target(name: "CSoundpipeAudioKit", dependencies: ["AudioKit", "AudioKitEX", "Soundpipe"]),
        .testTarget(name: "AudioKitTests", dependencies: ["AudioKit"], resources: [.copy("TestResources/")]),
        .testTarget(name: "AudioKitEXTests", dependencies: ["AudioKitEX"], resources: [.copy("TestResources/")])
    ],
    cxxLanguageStandard: .cxx14
)
