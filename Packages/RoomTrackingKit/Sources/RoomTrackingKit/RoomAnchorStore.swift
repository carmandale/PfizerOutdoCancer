import Foundation
import simd

struct StoredRoomAnchor: Codable {
    let matrix: [[Float]]
}

public struct RoomAnchorStore {
    private let fileURL: URL

    public init(filename: String = "RoomAnchor.json") {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsURL.appendingPathComponent(filename)
    }

    public func save(transform: simd_float4x4) throws {
        let matrix = [
            [transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w],
            [transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w],
            [transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w],
            [transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w]
        ]
        let stored = StoredRoomAnchor(matrix: matrix)
        let data = try JSONEncoder().encode(stored)
        try data.write(to: fileURL, options: .atomic)
    }

    public func load() throws -> simd_float4x4? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        let stored = try JSONDecoder().decode(StoredRoomAnchor.self, from: data)
        let columns = stored.matrix.map { SIMD4<Float>($0) }
        return simd_float4x4(columns)
    }

    public func delete() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
