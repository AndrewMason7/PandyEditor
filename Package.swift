// swift-tools-version: 5.9
//
//  Package.swift
//  PandyEditor 🐼
//
//  A shareable, high-performance code editor library for iOS.
//  Engineered to Strict FiveKit Compliance.
//
//  ICON: Assets/icon.jpg - The PandaEditor mascot
//
//  STRICT FIVEKIT COMPLIANCE:
//  1. Dependency Management: Explicitly declares FiveKit dependency.
//  2. Platform Support: Targets iOS 15+ for ProMotion and modern APIs.
//  3. Resource Bundling: Assets folder included for icon and branding.
//

import PackageDescription

let package = Package(
    name: "PandyEditor",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PandyEditor",
            targets: ["PandyEditor"]),
    ],
    dependencies: [
        // FiveKit: FiveSheep's in-house app development toolkit
        // Provides FoundationPlus (String subscripts, .negated, etc.) and SwiftUIElements
        .package(path: "./FiveKit"),
    ],
    targets: [
        .target(
            name: "PandyEditor",
            dependencies: [
                .product(name: "FiveKit", package: "FiveKit"),
            ],
            path: "Sources/SwiftCodeEditorLib",
            resources: [
                // Bundle the icon for use in consuming apps
                .copy("../../Assets/icon.jpg")
            ]),
    ]
)

