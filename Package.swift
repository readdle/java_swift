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
        .package(url: "https://github.com/readdle/CJavaVM.git", .exact("2.4.1")),
    ],
    targets: [
        .target(
            name: "java_swift",
            path: "Sources"
        )
    ]
)
