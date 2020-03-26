import Alamofire
import Foundation

final class AlamofireRequestsLogger {
    private let queue: DispatchQueue

    init(queue: DispatchQueue = DispatchQueue(label: "AlamofireRequestsLogger", qos: .background)) {
        self.queue = queue
    }

    deinit {
        self.stop()
    }

    func startIfDebug() {
        #if DEBUG
            self.start()
        #endif
    }

    func start() {
        self.stop()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.networkRequestDidStart(notification:)),
            name: Foundation.Notification.Name.Task.DidResume,
            object: nil
        )
    }

    func stop() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func networkRequestDidStart(notification: Foundation.Notification) {
        self.queue.async { [weak self] in
            self?.log(notification: notification)
        }
    }

    private func log(notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let task = userInfo[Foundation.Notification.Key.Task] as? URLSessionTask,
              let request = task.originalRequest,
              let httpMethod = request.httpMethod,
              let requestURL = request.url?.absoluteString.removingPercentEncoding else {
            return
        }

        print("---------------------")
        print("Request: \(httpMethod) '\(requestURL)':")

        if let httpHeaderFields = request.allHTTPHeaderFields {
            print("Headers: [")
            for (key, value) in httpHeaderFields {
                print("  \(key): \(value)")
            }
            print("]")
        }

        if let httpBody = request.httpBody,
           let httpBodyString = String(data: httpBody, encoding: .utf8) {
            print("Body: \(httpBodyString)")
        }
    }
}
