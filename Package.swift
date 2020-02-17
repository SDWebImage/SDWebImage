// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SDWebImage",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v8),
        .tvOS(.v9),
        .watchOS(.v2)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SDWebImage",
            targets: ["SDWebImage"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SDWebImage",
            dependencies: [],
            path: ".",
            sources: ["SDWebImage/Core", "SDWebImage/Private"],
            publicHeadersPath: "SDWebImage/Core",
            cSettings: [
                .headerSearchPath("SDWebImage/Core"),
                .headerSearchPath("SDWebImage/Private")
            ]
        )
    ]
)
