// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PoieticPlayground",
    platforms: [ .macOS(.v15), ],
    products: [
        .executable(
            name: "PoieticPlayground",
            targets: ["PoieticPlayground"]),
    ],
    dependencies: [
                .package(url: "https://github.com/openpoiesis/poietic-core", branch: "main"),
                .package(url: "https://github.com/openpoiesis/poietic-flows", branch: "main"),
                .package(url: "https://github.com/openpoiesis/poietic-diagram", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "PoieticPlayground",
            dependencies: [
                .product(name: "PoieticCore", package: "poietic-core"),
                .product(name: "PoieticFlows", package: "poietic-flows"),
                .product(name: "Diagramming", package: "poietic-diagram"),
                "Csdl3",
                "CIimgui",
                "Cstb",
            ],
            resources: [
              .copy("Resources/icons/"),
            ],
            swiftSettings: [.unsafeFlags([
                "-cxx-interoperability-mode=default",
            ])]
        ),
        .systemLibrary(
            name: "Csdl3",
            pkgConfig: "sdl3",
            providers: [
                .apt(["sdl3-dev"]),
                .brew(["sdl3"])
            ]
        ),
        .target(
            name: "CIimgui",
            dependencies: [
                "Csdl3"
            ],
            cxxSettings: [ ],
            linkerSettings: [ ]
        ),
        .target(
            name: "Cstb",
            cxxSettings: [ ],
        )
    ]
)
