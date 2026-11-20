//
//  FaceZoneMap.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 19/11/26.
//


import CoreGraphics

nonisolated struct FaceZoneMap {
    private let entries: [FaceZoneTemplate.Entry]
    private let layout: FaceZoneLayout

    init?(points: FacePoints) {
        guard let frame = FaceZoneFrame(points: points) else { return nil }
        layout = points.layout
        entries = FaceZoneTemplate.shapes(for: points.layout, frame: frame)
    }

    func zone(of p: CGPoint, locked: FaceZone? = nil) -> FaceZone? {
        if let locked, contains(locked, p, grownBy: FaceZoneConfig.lockGrowth(for: locked, layout: layout)) { return locked }
        return entries.first { $0.shape.contains(p) }?.zone
    }

    func zone(primary: CGPoint, others: [CGPoint], locked: FaceZone? = nil) -> FaceZone? {
        if let locked, let direct = zone(of: primary),
           FaceZoneConfig.priority(of: direct) < FaceZoneConfig.priority(of: locked) {
            return direct
        }
        let probes = [primary] + others
        if let locked, probes.contains(where: { contains(locked, $0, grownBy: FaceZoneConfig.lockGrowth(for: locked, layout: layout)) }) {
            return locked
        }
        return probes.compactMap { zone(of: $0) }
            .min { FaceZoneConfig.priority(of: $0) < FaceZoneConfig.priority(of: $1) }
    }

    func holds(_ zone: FaceZone, at p: CGPoint) -> Bool {
        self.zone(of: p, locked: zone) == zone
    }

    private func contains(_ zone: FaceZone, _ p: CGPoint, grownBy factor: CGFloat) -> Bool {
        entries.contains { $0.zone == zone && $0.shape.contains(p, grownBy: factor) }
    }
}
