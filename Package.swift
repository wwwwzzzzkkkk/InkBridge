// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "MacPDFAnnotator",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "MacPDFAnnotator", targets: ["MacPDFAnnotator"]),
  ],
  targets: [
    .executableTarget(
      name: "MacPDFAnnotator",
      path: "MacPDFAnnotator/Sources"
    ),
  ]
)
