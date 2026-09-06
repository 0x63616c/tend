import AppKit
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
NSColor(calibratedWhite: 0.055, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: 1024, height: 1024).fill()
let font = NSFont.systemFont(ofSize: 790, weight: .medium)
let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(calibratedWhite: 0.95, alpha: 1)]
let mark = "t" as NSString
let size = mark.size(withAttributes: attributes)
mark.draw(at: NSPoint(x: (1024-size.width)/2, y: (1024-size.height)/2+45), withAttributes: attributes)
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
