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
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "TravelCommon",
            targets: ["TravelCommon"]),
    ],
    dependencies: [
        // Use branch instead of "from" for branch names
        .package(url: "https://github.com/Lascade-Co/CommonSwaggerClient.git", .branch("main"))
        // OR use a version tag:
        // .package(url: "https://github.com/Lascade-Co/CommonSwaggerClient.git", from: "1.0.0")
        // OR use a commit hash:
        // .package(url: "https://github.com/Lascade-Co/CommonSwaggerClient.git", .revision("commit-hash"))
    ],
    targets: [
        .target(
            name: "TravelCommon",
            dependencies: [
                // Specify the exact product from CommonSwaggerClient
                .product(name: "AdsSwaggerClient", package: "CommonSwaggerClient"),
                // If you need both:
                // .product(name: "AdsSwaggerClient", package: "CommonSwaggerClient"),
            ],
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
