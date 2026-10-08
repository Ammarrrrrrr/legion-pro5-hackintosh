// Grabs ~45 frames from the default camera WITHOUT drawing them on screen (no Metal/Core Image),
// prints their brightness and saves the last one as a PNG next to this file.
// Run in Terminal.app:  /Volumes/1401/camera/grab        (allow camera access for Terminal if asked, then run again)
import AVFoundation
import AppKit

final class Grabber: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var frames = 0, stats: [String] = []
    var last: CVPixelBuffer?
    let done = DispatchSemaphore(value: 0)
    func captureOutput(_ o: AVCaptureOutput, didOutput sb: CMSampleBuffer, from c: AVCaptureConnection) {
        guard let pb = CMSampleBufferGetImageBuffer(sb) else { return }
        frames += 1
        if frames % 15 == 0 { stats.append("frame \(frames): " + measure(pb)) }
        if frames == 45 { last = pb; done.signal() }
    }
}

func measure(_ pb: CVPixelBuffer) -> String {
    CVPixelBufferLockBaseAddress(pb, .readOnly); defer { CVPixelBufferUnlockBaseAddress(pb, .readOnly) }
    let w = CVPixelBufferGetWidth(pb), h = CVPixelBufferGetHeight(pb), bpr = CVPixelBufferGetBytesPerRow(pb)
    let p = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
    var sum = 0, mx = 0, n = 0
    for y in stride(from: 0, to: h, by: 8) { for x in stride(from: 0, to: w, by: 8) {
        let q = p + y * bpr + x * 4; let l = (Int(q[0]) + Int(q[1]) + Int(q[2])) / 3
        sum += l; mx = max(mx, l); n += 1 } }
    return "\(w)x\(h) mean brightness \(sum / max(n, 1)) / 255, max \(mx)"
}

let dir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
switch AVCaptureDevice.authorizationStatus(for: .video) {
case .authorized: break
case .notDetermined:
    let s = DispatchSemaphore(value: 0); var ok = false
    AVCaptureDevice.requestAccess(for: .video) { ok = $0; s.signal() }; s.wait()
    if !ok { print("camera access denied"); exit(3) }
default: print("camera access denied - System Settings > Privacy & Security > Camera > allow Terminal"); exit(3)
}
guard let dev = AVCaptureDevice.default(for: .video) else { print("no camera found"); exit(1) }
print("camera: \(dev.localizedName)")
let g = Grabber(), session = AVCaptureSession()
do { session.addInput(try AVCaptureDeviceInput(device: dev)) } catch { print("input error: \(error)"); exit(1) }
let out = AVCaptureVideoDataOutput()
out.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
out.setSampleBufferDelegate(g, queue: DispatchQueue(label: "cam"))
session.addOutput(out)
session.startRunning()
let r = g.done.wait(timeout: .now() + 15)
session.stopRunning()
g.stats.forEach { print($0) }
guard r == .success, let pb = g.last else { print("only \(g.frames) frames arrived in 15 s"); exit(2) }
CVPixelBufferLockBaseAddress(pb, .readOnly)
let w = CVPixelBufferGetWidth(pb), h = CVPixelBufferGetHeight(pb)
let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pb), width: w, height: h, bitsPerComponent: 8,
                    bytesPerRow: CVPixelBufferGetBytesPerRow(pb), space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
let png = NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
CVPixelBufferUnlockBaseAddress(pb, .readOnly)
let file = dir.appendingPathComponent("frame.png")
try png.write(to: file)
print("saved \(file.path)")
