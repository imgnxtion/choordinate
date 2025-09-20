import Foundation
import Combine

final class ChordStore: ObservableObject {
    @Published var bindings: [ChordBinding]

    private var cancellables = Set<AnyCancellable>()
    private let storageURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        self.storageURL = ChordStore.makeStorageURL()
        self.bindings = (try? ChordStore.load(from: storageURL, decoder: decoder)) ?? []

        $bindings
            .dropFirst()
            .debounce(for: .seconds(0.4), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.persistIfPossible()
            }
            .store(in: &cancellables)
    }

    func add(_ binding: ChordBinding) {
        bindings.append(binding)
    }

    func update(_ binding: ChordBinding) {
        guard let index = bindings.firstIndex(where: { $0.id == binding.id }) else { return }
        bindings[index] = binding
    }

    func remove(_ binding: ChordBinding) {
        bindings.removeAll { $0.id == binding.id }
    }

    private func persistIfPossible() {
        do {
            try ChordStore.save(bindings, to: storageURL, encoder: encoder)
        } catch {
            NSLog("ChordStore save error: \(error.localizedDescription)")
        }
    }

    private static func makeStorageURL() -> URL {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: true)) ?? fm.homeDirectoryForCurrentUser
        let folder = base.appendingPathComponent("Chordinate", isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent("bindings.json")
    }

    private static func load(from url: URL, decoder: JSONDecoder) throws -> [ChordBinding] {
        let data = try Data(contentsOf: url)
        return try decoder.decode([ChordBinding].self, from: data)
    }

    private static func save(_ bindings: [ChordBinding], to url: URL, encoder: JSONEncoder) throws {
        let data = try encoder.encode(bindings)
        try data.write(to: url, options: [.atomic])
    }
}
