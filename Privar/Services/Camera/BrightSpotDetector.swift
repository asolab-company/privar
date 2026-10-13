import CoreGraphics
import Foundation

struct BrightSpotDetector {
  private var previous: CGPoint?
  private var stability = 0
  private struct Spot {
    let center: CGPoint
    let radius: Double
    let score: Double
  }

  mutating func detect(bytes: UnsafePointer<UInt8>, width: Int, height: Int, stride: Int) -> CGRect?
  {
    guard width >= 5, height >= 5, stride >= width * 4 else { return clear() }

    let step = max(1, min(width, height) / 360)
    let columns = (width + step - 1) / step
    let rows = (height + step - 1) / step
    var peaks = [UInt8](repeating: 0, count: columns * rows)
    var luminance = peaks
    var histogram = [Int](repeating: 0, count: 256)
    for gy in 0..<rows {
      for gx in 0..<columns {
        var peak = 0
        var light = 0
        for y in (gy * step)..<min((gy + 1) * step, height) {
          for x in (gx * step)..<min((gx + 1) * step, width) {
            let i = y * stride + x * 4
            let b = Int(bytes[i])
            let g = Int(bytes[i + 1])
            let r = Int(bytes[i + 2])
            let value = max(b, max(g, r))
            if value > peak {
              peak = value
              light = (29 * b + 150 * g + 77 * r) >> 8
            }
          }
        }
        let i = gy * columns + gx
        peaks[i] = UInt8(peak)
        luminance[i] = UInt8(light)
        histogram[peak] += 1
      }
    }
    var median = 0
    var cumulative = 0
    for value in 0..<256 {
      cumulative += histogram[value]
      if cumulative >= peaks.count / 2 {
        median = value
        break
      }
    }
    let threshold = max(140, median + 35)
    var contrast = [UInt8](repeating: 0, count: peaks.count)
    let directions = [(-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1)]

    let radii = [max(2, columns / 90), max(4, columns / 45), max(8, columns / 22)]
    for gy in 0..<rows {
      for gx in 0..<columns {
        let i = gy * columns + gx
        let peak = Int(peaks[i])
        guard peak >= threshold, luminance[i] >= 40 else { continue }
        var best = 0
        for radius in radii {
          var sum = 0
          var samples = 0
          var darker = 0
          for (dx, dy) in directions {
            let x = gx + dx * radius
            let y = gy + dy * radius
            guard x >= 0, x < columns, y >= 0, y < rows else { continue }
            let surrounding = Int(peaks[y * columns + x])
            sum += surrounding
            samples += 1
            if peak - surrounding >= 35 { darker += 1 }
          }
          guard samples >= 5, darker * 4 >= samples * 3 else { continue }
          best = max(best, peak - sum / samples)
        }
        if best >= 55 { contrast[i] = UInt8(min(255, best)) }
      }
    }
    var spots: [Spot] = []
    for seed in contrast.indices where contrast[seed] > 0 {
      var stack = [seed]
      var count = 0
      var total = 0.0
      var weightedX = 0.0
      var weightedY = 0.0
      var minX = columns
      var maxX = 0
      var minY = rows
      var maxY = 0
      var scores = [Int: UInt8]()
      scores[seed] = contrast[seed]
      contrast[seed] = 0
      while let i = stack.popLast() {
        let x = i % columns
        let y = i / columns
        let score = Double(scores.removeValue(forKey: i) ?? 0)
        count += 1
        total += score
        weightedX += (Double(x) + 0.5) * score
        weightedY += (Double(y) + 0.5) * score
        minX = min(minX, x)
        maxX = max(maxX, x)
        minY = min(minY, y)
        maxY = max(maxY, y)
        for (dx, dy) in directions {
          let nx = x + dx
          let ny = y + dy
          guard nx >= 0, nx < columns, ny >= 0, ny < rows else { continue }
          let next = ny * columns + nx
          if contrast[next] > 0 {
            scores[next] = contrast[next]
            contrast[next] = 0
            stack.append(next)
          }
        }
      }
      let bw = Double((maxX - minX + 1) * step)
      let bh = Double((maxY - minY + 1) * step)

      guard total > 0, Double(count * step * step) <= Double(width * height) * 0.0125,
        bw <= Double(width) * 0.18, bh <= Double(height) * 0.18,
        max(bw, bh) / max(1, min(bw, bh)) <= 3.5
      else { continue }
      let center = CGPoint(
        x: weightedX / total * Double(step) / Double(width),
        y: weightedY / total * Double(step) / Double(height))
      let radius = max(Double(step) * 3, max(bw, bh) * 0.8, Double(width) * 0.0225)
      spots.append(Spot(center: center, radius: radius, score: total / Double(count)))
    }
    guard var best = spots.max(by: { $0.score < $1.score }) else { return clear() }
    if let previous,
      let nearby = spots.filter({
        hypot($0.center.x - previous.x, $0.center.y - previous.y) < 0.045
      })
      .max(by: { $0.score < $1.score }), nearby.score >= best.score * 0.7
    {
      best = nearby
    }
    if let previous, hypot(previous.x - best.center.x, previous.y - best.center.y) < 0.045 {
      stability += 1
    } else {
      stability = 1
    }
    previous = best.center
    guard stability >= 4 else { return nil }
    let rx = best.radius / Double(width)
    let ry = best.radius / Double(height)
    return CGRect(x: best.center.x - rx, y: best.center.y - ry, width: rx * 2, height: ry * 2)
      .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
  }
  private mutating func clear() -> CGRect? {
    previous = nil
    stability = 0
    return nil
  }
}
