// swift-tools-version:4.0
//
//  Package.swift
//  SwiftJava
//
//  Created by John Holdsworth on 20/07/2016.
//  Copyright (c) 2016 John Holdsworth. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "java_swift",
    products: [
        .library(
            name: "java_swift",
            targets: ["java_swift"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/readdle/swift-android-ndk.git", .exact("1.1.4")),
    ],
    targets: [
        .target(
            name: "java_swift",
            dependencies: [
                .product(name: "AndroidNDK", package: "swift-android-ndk"),
            ],
            path: "Sources"
        )
    ],
    swiftLanguageVersions: [5, 4]
)

