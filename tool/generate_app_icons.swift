#!/usr/bin/env swift

import AppKit
import Foundation

struct IconTarget {
  let path: String
  let size: Int
}

struct Pixel: Hashable {
  let x: Int
  let y: Int
}

enum IconGeneratorError: Error, CustomStringConvertible {
  case invalidArguments
  case sourceMissing(String)
  case sourceUnreadable(String)
  case bitmapCreationFailed
  case cgImageCreationFailed
  case pngEncodingFailed(String)
  case writeFailed(String)

  var description: String {
    switch self {
    case .invalidArguments:
      return "Usage: swift tool/generate_app_icons.swift <source-png-path>"
    case .sourceMissing(let path):
      return "Source image not found at \(path)"
    case .sourceUnreadable(let path):
      return "Unable to read source image at \(path)"
    case .bitmapCreationFailed:
      return "Unable to create bitmap context"
    case .cgImageCreationFailed:
      return "Unable to create CGImage from source"
    case .pngEncodingFailed(let path):
      return "Unable to encode PNG for \(path)"
    case .writeFailed(let path):
      return "Unable to write PNG to \(path)"
    }
  }
}

let backgroundColor = NSColor(
  calibratedRed: 10.0 / 255.0,
  green: 7.0 / 255.0,
  blue: 22.0 / 255.0,
  alpha: 1.0
)

let canvasSize = CGFloat(1024)
let logoInsetRatio: CGFloat = 0.14

let iconTargets: [IconTarget] = [
  IconTarget(path: "android/app/src/main/res/mipmap-mdpi/ic_launcher.png", size: 48),
  IconTarget(path: "android/app/src/main/res/mipmap-hdpi/ic_launcher.png", size: 72),
  IconTarget(path: "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", size: 96),
  IconTarget(path: "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", size: 144),
  IconTarget(path: "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", size: 192),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png", size: 20),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png", size: 40),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png", size: 60),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png", size: 29),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png", size: 58),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png", size: 87),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png", size: 40),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png", size: 80),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png", size: 120),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png", size: 120),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png", size: 180),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png", size: 76),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png", size: 152),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png", size: 167),
  IconTarget(path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png", size: 1024),
  IconTarget(path: "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png", size: 16),
  IconTarget(path: "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png", size: 32),
  IconTarget(path: "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png", size: 64),
  IconTarget(path: "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png", size: 128),
  IconTarget(path: "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png", size: 256),
  IconTarget(path: "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png", size: 512),
  IconTarget(path: "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png", size: 1024),
]

func renderMasterIcon(from sourceImage: NSImage) throws -> NSBitmapImageRep {
  let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize),
    pixelsHigh: Int(canvasSize),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  )

  guard let bitmap else {
    throw IconGeneratorError.bitmapCreationFailed
  }

  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

  let canvasRect = NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
  backgroundColor.setFill()
  canvasRect.fill()

  let sourceSize = sourceImage.size
  let maxLogoSize = canvasSize * (1.0 - (logoInsetRatio * 2.0))
  let scale = min(maxLogoSize / sourceSize.width, maxLogoSize / sourceSize.height)
  let drawSize = NSSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
  let drawRect = NSRect(
    x: (canvasSize - drawSize.width) / 2.0,
    y: (canvasSize - drawSize.height) / 2.0,
    width: drawSize.width,
    height: drawSize.height
  )

  sourceImage.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)

  NSGraphicsContext.restoreGraphicsState()
  return bitmap
}

func cleanedSourceBitmap(from sourceImage: NSImage) throws -> NSBitmapImageRep {
  var proposedRect = NSRect(origin: .zero, size: sourceImage.size)
  guard let cgImage = sourceImage.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
    throw IconGeneratorError.cgImageCreationFailed
  }

  let width = cgImage.width
  let height = cgImage.height

  guard let sourceBitmap = NSBitmapImageRep(cgImage: cgImage) as NSBitmapImageRep? else {
    throw IconGeneratorError.bitmapCreationFailed
  }

  let alphaThreshold = 24
  let minimumComponentArea = 180
  let neighborOffsets = [
    (-1, -1), (0, -1), (1, -1),
    (-1, 0),           (1, 0),
    (-1, 1),  (0, 1),  (1, 1),
  ]

  func alphaAt(x: Int, y: Int) -> Int {
    Int((sourceBitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0.0) * 255.0)
  }

  var visited = Set<Pixel>()
  var preservedMask = Set<Pixel>()

  for y in 0..<height {
    for x in 0..<width {
      let pixel = Pixel(x: x, y: y)
      if visited.contains(pixel) || alphaAt(x: x, y: y) < alphaThreshold {
        continue
      }

      var queue = [pixel]
      var index = 0
      var component = [Pixel]()
      visited.insert(pixel)

      while index < queue.count {
        let current = queue[index]
        index += 1
        component.append(current)

        for (dx, dy) in neighborOffsets {
          let nextX = current.x + dx
          let nextY = current.y + dy
          guard nextX >= 0, nextX < width, nextY >= 0, nextY < height else {
            continue
          }

          let next = Pixel(x: nextX, y: nextY)
          if visited.contains(next) || alphaAt(x: nextX, y: nextY) < alphaThreshold {
            continue
          }

          visited.insert(next)
          queue.append(next)
        }
      }

      if component.count >= minimumComponentArea {
        for point in component {
          preservedMask.insert(point)
          for dx in -2...2 {
            for dy in -2...2 {
              let nx = point.x + dx
              let ny = point.y + dy
              guard nx >= 0, nx < width, ny >= 0, ny < height else {
                continue
              }
              preservedMask.insert(Pixel(x: nx, y: ny))
            }
          }
        }
      }
    }
  }

  let cleanedBitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  )

  guard let cleanedBitmap else {
    throw IconGeneratorError.bitmapCreationFailed
  }

  for y in 0..<height {
    for x in 0..<width {
      let point = Pixel(x: x, y: y)
      let outputColor = preservedMask.contains(point)
        ? (sourceBitmap.colorAt(x: x, y: y) ?? .clear)
        : .clear
      cleanedBitmap.setColor(outputColor, atX: x, y: y)
    }
  }

  return cleanedBitmap
}

func resizedBitmap(from imageRep: NSBitmapImageRep, size: Int) throws -> NSBitmapImageRep {
  let targetImage = NSImage(size: NSSize(width: size, height: size))
  targetImage.addRepresentation(imageRep)

  let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  )

  guard let bitmap else {
    throw IconGeneratorError.bitmapCreationFailed
  }

  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
  NSGraphicsContext.current?.imageInterpolation = .high

  targetImage.draw(
    in: NSRect(x: 0, y: 0, width: size, height: size),
    from: .zero,
    operation: .copy,
    fraction: 1.0
  )

  NSGraphicsContext.restoreGraphicsState()
  return bitmap
}

func writeBitmap(_ bitmap: NSBitmapImageRep, to outputPath: String) throws {
  guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    throw IconGeneratorError.pngEncodingFailed(outputPath)
  }

  let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent(outputPath)

  do {
    try pngData.write(to: outputURL)
  } catch {
    throw IconGeneratorError.writeFailed(outputPath)
  }
}

do {
  guard CommandLine.arguments.count == 2 else {
    throw IconGeneratorError.invalidArguments
  }

  let sourcePath = CommandLine.arguments[1]
  guard FileManager.default.fileExists(atPath: sourcePath) else {
    throw IconGeneratorError.sourceMissing(sourcePath)
  }

  guard let sourceImage = NSImage(contentsOfFile: sourcePath) else {
    throw IconGeneratorError.sourceUnreadable(sourcePath)
  }

  let cleanedSource = try cleanedSourceBitmap(from: sourceImage)
  try writeBitmap(cleanedSource, to: sourcePath)

  let cleanedImage = NSImage(size: NSSize(width: cleanedSource.pixelsWide, height: cleanedSource.pixelsHigh))
  cleanedImage.addRepresentation(cleanedSource)

  let masterBitmap = try renderMasterIcon(from: cleanedImage)
  try writeBitmap(cleanedSource, to: ".tmp_branding/cleaned-FlixsyAppIcon.png")
  try writeBitmap(masterBitmap, to: ".tmp_branding/generated-app-icon-1024.png")

  for target in iconTargets {
    let resized = try resizedBitmap(from: masterBitmap, size: target.size)
    try writeBitmap(resized, to: target.path)
  }

  print("Generated \(iconTargets.count) app icons from \(sourcePath)")
} catch {
  fputs("\(error)\n", stderr)
  exit(1)
}
