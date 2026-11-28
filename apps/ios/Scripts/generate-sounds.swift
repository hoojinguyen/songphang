#!/usr/bin/env swift
import Foundation

let sampleRate = 22_050.0

struct Partial {
  let frequency: Double
  let amplitude: Double
  let startSeconds: Double
  let durationSeconds: Double
  let decayRate: Double
}

func renderSamples(durationSeconds: Double, partials: [Partial], masterGain: Double) -> [Int16] {
  let count = Int(durationSeconds * sampleRate)
  var output = [Int16](repeating: 0, count: count)
  let attackSeconds = 0.004

  for index in 0..<count {
    let time = Double(index) / sampleRate
    var sample = 0.0
    for partial in partials {
      let localTime = time - partial.startSeconds
      guard localTime >= 0, localTime <= partial.durationSeconds else { continue }
      let attack = min(1.0, localTime / attackSeconds)
      let tailFade = min(1.0, max(0.0, (partial.durationSeconds - localTime) / 0.012))
      let envelope = attack * exp(-partial.decayRate * localTime) * tailFade
      sample += partial.amplitude * envelope * sin(2.0 * .pi * partial.frequency * localTime)
    }
    let clamped = max(-1.0, min(1.0, sample * masterGain))
    output[index] = Int16((clamped * Double(Int16.max)).rounded())
  }
  return output
}

func writeWAV(samples: [Int16], to url: URL) throws {
  let numChannels: UInt16 = 1
  let bitsPerSample: UInt16 = 16
  let byteRate = UInt32(sampleRate) * UInt32(numChannels) * UInt32(bitsPerSample / 8)
  let blockAlign = numChannels * (bitsPerSample / 8)
  let dataByteCount = UInt32(samples.count * MemoryLayout<Int16>.size)
  let riffChunkSize = 36 + dataByteCount

  var data = Data()
  data.append(contentsOf: "RIFF".utf8)
  var leRiff = riffChunkSize.littleEndian
  data.append(Data(bytes: &leRiff, count: 4))
  data.append(contentsOf: "WAVE".utf8)

  data.append(contentsOf: "fmt ".utf8)
  var fmtSize = UInt32(16).littleEndian
  var audioFormat = UInt16(1).littleEndian
  var leChannels = numChannels.littleEndian
  var leSampleRate = UInt32(sampleRate).littleEndian
  var leByteRate = byteRate.littleEndian
  var leBlockAlign = blockAlign.littleEndian
  var leBits = bitsPerSample.littleEndian
  data.append(Data(bytes: &fmtSize, count: 4))
  data.append(Data(bytes: &audioFormat, count: 2))
  data.append(Data(bytes: &leChannels, count: 2))
  data.append(Data(bytes: &leSampleRate, count: 4))
  data.append(Data(bytes: &leByteRate, count: 4))
  data.append(Data(bytes: &leBlockAlign, count: 2))
  data.append(Data(bytes: &leBits, count: 2))

  data.append(contentsOf: "data".utf8)
  var leDataSize = dataByteCount.littleEndian
  data.append(Data(bytes: &leDataSize, count: 4))

  for sample in samples {
    var leSample = sample.littleEndian
    data.append(Data(bytes: &leSample, count: 2))
  }

  try data.write(to: url, options: .atomic)
}

func convertToCAF(wavURL: URL, cafURL: URL) throws {
  let process = Process()
  process.executableURL = URL(filePath: "/usr/bin/afconvert")
  process.arguments = ["-f", "caff", "-d", "LEI16", wavURL.path(), cafURL.path()]
  try process.run()
  process.waitUntilExit()
  guard process.terminationStatus == 0 else {
    throw NSError(domain: "GenerateSounds", code: Int(process.terminationStatus))
  }
}

let scriptURL = URL(filePath: CommandLine.arguments[0]).standardizedFileURL
let iosRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let soundsDir = iosRoot.appending(
  path: "SongPhangKit/Sources/DesignSystem/Resources/Sounds",
  directoryHint: .isDirectory
)
try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)

let specs: [(name: String, duration: Double, gain: Double, partials: [Partial])] = [
  (
    name: "coin",
    duration: 0.15,
    gain: 0.18,
    partials: [
      Partial(
        frequency: 987.77, amplitude: 0.75, startSeconds: 0.0, durationSeconds: 0.06,
        decayRate: 28.0),
      Partial(
        frequency: 1975.53, amplitude: 0.25, startSeconds: 0.0, durationSeconds: 0.05,
        decayRate: 36.0),
      Partial(
        frequency: 1318.51, amplitude: 0.80, startSeconds: 0.048, durationSeconds: 0.102,
        decayRate: 22.0),
      Partial(
        frequency: 2637.02, amplitude: 0.20, startSeconds: 0.048, durationSeconds: 0.09,
        decayRate: 32.0),
    ]
  ),
  (
    name: "ting",
    duration: 0.24,
    gain: 0.17,
    partials: [
      Partial(
        frequency: 880.0, amplitude: 0.80, startSeconds: 0.0, durationSeconds: 0.24, decayRate: 14.0
      ),
      Partial(
        frequency: 1760.0, amplitude: 0.20, startSeconds: 0.0, durationSeconds: 0.18,
        decayRate: 22.0),
    ]
  ),
  (
    name: "chord",
    duration: 0.36,
    gain: 0.18,
    partials: [
      Partial(
        frequency: 523.25, amplitude: 0.38, startSeconds: 0.0, durationSeconds: 0.36, decayRate: 8.5
      ),
      Partial(
        frequency: 659.25, amplitude: 0.34, startSeconds: 0.022, durationSeconds: 0.338,
        decayRate: 9.0),
      Partial(
        frequency: 783.99, amplitude: 0.34, startSeconds: 0.044, durationSeconds: 0.316,
        decayRate: 9.5),
    ]
  ),
]

for spec in specs {
  let tempWAV = FileManager.default.temporaryDirectory
    .appendingPathComponent("sp-\(spec.name)-\(UUID().uuidString).wav")
  defer { try? FileManager.default.removeItem(at: tempWAV) }
  let cafURL = soundsDir.appending(path: "\(spec.name).caf")
  let samples = renderSamples(
    durationSeconds: spec.duration,
    partials: spec.partials,
    masterGain: spec.gain
  )
  try writeWAV(samples: samples, to: tempWAV)
  try convertToCAF(wavURL: tempWAV, cafURL: cafURL)
  let attrs = try FileManager.default.attributesOfItem(atPath: cafURL.path())
  let bytes = (attrs[.size] as? NSNumber)?.intValue ?? 0
  print("Generated \(spec.name).caf (\(Int(spec.duration * 1000)) ms, \(bytes) bytes)")
}
