// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // экспортируем статическую библиотеку PieChart
        .library(
            name: "PieChart",
            type: .static,
            targets: ["PieChart"]
        ),
    ],
    dependencies: [
        // никаких внешних зависимостей
    ],
    targets: [
        .target(
            name: "PieChart",
            path: "Sources/PieChart"
        ),
        .testTarget(
            name: "PieChartTests",
            dependencies: ["PieChart"],
            path: "Tests/PieChartTests"
        ),
    ]
)
