//
//  DeleteDeviceExecutableTask.swift
//  Stepic
//
//  Created by Alexander Karpov on 04.05.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON

/*
 ExecutableTask for deleting device on the server
 */
final class DeleteDeviceExecutableTask: Executable, DictionarySerializable {
    var id: String {
        get {
            description
        }
    }

    init(userId: Int, deviceId: Int) {
        self.userId = userId
        self.deviceId = deviceId
    }

    required convenience init?(dictionary dict: [String: Any]) {
        let taskDict = dict["task"] as? [String: Any]
        let typeString = dict["type"] as? String
        let userId = taskDict?["user"] as? Int
        let deviceId = taskDict?["device"] as? Int
        if let user = userId,
           let device = deviceId,
           let typeS = typeString {
            if ExecutableTaskType(rawValue: typeS) != ExecutableTaskType.deleteDevice {
                return nil
            }
            self.init(userId: user, deviceId: device)
        } else {
            return nil
        }
    }

    func serializeToDictionary() -> [String: Any] {
        let res: [String: Any] =
            [
                "type": type.rawValue,
                "task": [
                    "user": userId,
                    "device": deviceId
                ]
            ]
        print(res)
        return res
    }

    var type: ExecutableTaskType { .deleteDevice }

    var userId: Int
    var deviceId: Int

    var description: String { "\(type.rawValue) \(userId) \(deviceId)" }

    func execute(success: @escaping () -> Void, failure: @escaping (ExecutionError) -> Void) {
        let recoveryManager = PersistentUserTokenRecoveryManager(baseName: "Users")

        guard let token = recoveryManager.recoverStepicToken(userId: self.userId) else {
            return
        }

        let device = self.deviceId
        let user = self.userId

        ApiDataDownloader.devices.delete(
            device,
            headers: APIDefaults.Headers.bearer(token.accessToken),
            success: {
                print("user \(user) successfully deleted device with id \(device)")
                success()
            },
            error: { error in
                print("error \(error) while removing device, trying to refresh token and retry")
                ApiDataDownloader.auth.refreshTokenWith(
                    token.refreshToken,
                    success: { token in
                        print("successfully refreshed token")
                        if AuthInfo.shared.userId == user {
                            AuthInfo.shared.token = token
                        }
                        recoveryManager.writeStepicToken(token, userId: user)
                        ApiDataDownloader.devices.delete(
                            device,
                            headers: APIDefaults.Headers.bearer(token.accessToken),
                            success: {
                                print("user \(user) successfully deleted device with id \(device) after refreshing the token")
                                success()
                            },
                            error: { error in
                                print("error while deleting device with refreshed token")
                                switch error {
                                case .notFound:
                                    print("device not found on deletion, not writing executable task")
                                    failure(.remove)
                                    return
                                case .other(let error, _, let message):
                                    print(message ?? "")
                                    if error != nil {
                                        failure(.retry)
                                    } else {
                                        failure(.remove)
                                    }
                                    return
                                }
                            }
                        )
                    },
                    failure: { error in
                        print("error while refreshing the token :(")
                        failure(error == .other ? .retry : .remove)
                    }
                )
            }
        )
    }
}
