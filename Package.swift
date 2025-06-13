// swift-tools-version:5.5
//
//  Package.swift
//  FlightFramework
//
//  Created by Rohit T P on 14/06/25.
//
import PackageDescription

let package = Package(
    name: "TravelCommon",
    platforms: [
        .iOS(.v13), // Adjust minimum iOS version as needed
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "TravelCommon",
            targets: ["TravelCommon"]),
    ],
    dependencies: [
        // Add FlightSwaggerClient dependency
        .package(url: "https://github.com/Lascade-Co/CommonSwaggerClient.git", from: "main")
        // OR if using local package:
        // .package(path: "../FlightSwaggerClient")
    ],
    targets: [
        .target(
            name: "TravelCommon",
            dependencies: ["CommonSwaggerClient"],
            path: "TravelCommon",
                        swiftSettings: [
                            .unsafeFlags([
                                "-enable-library-evolution",
                                "-emit-module-interface"
                            ])
                        ]
        ),
    ]
)
