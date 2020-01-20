import Foundation

class DownloaderTask: DownloaderTaskProtocol {
    private(set) var url: URL

    private(set) var priority: DownloaderTaskPriority

    private(set) var id: Int

    /// Current executor
    private(set) weak var executor: DownloaderProtocol?

    var progressReporter: ((_ progress: Float?) -> Void)?

    var completionReporter: ((_ location: URL) -> Void)?

    var failureReporter: ((_ error: Error) -> Void)?

    var stateReporter: ((_ newState: DownloaderTaskState) -> Void)?

    var state: DownloaderTaskState {
        self.executor?.getTaskState(for: self) ?? .detached
    }

    convenience init(url: URL, priority: DownloaderTaskPriority = .default) {
        let id = Int(arc4random_uniform(UInt32(Int32.max))) &* url.hashValue
        self.init(id: id, url: url, executor: nil, priority: priority)
    }

    init(id: Int, url: URL, executor: DownloaderProtocol? = nil, priority: DownloaderTaskPriority) {
        self.id = id
        self.url = url
        self.priority = priority
        self.executor = executor
    }

    func add(to executor: DownloaderProtocol) {
        self.executor = executor
        try? executor.add(task: self)
    }

    func resume() {
        try? self.executor?.resume(task: self)
    }

    func pause() {
        try? self.executor?.pause(task: self)
    }

    func cancel() {
        try? self.executor?.cancel(task: self)
    }
}
