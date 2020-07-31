//
//  DevicesAPI.swift
//  Stepic
//
//  Created by Alexander Karpov on 22.04.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Alamofire
import PromiseKit
import SwiftyJSON
import UIKit

//TODO: Refactor this after DeviceError refactoring
final class DevicesAPI: APIEndpoint {
    override var name: String { "devices" }

    func retrieve(registrationId: String) -> Promise<Device?> {
        Promise { seal in
            retrieve(params: ["registration_id": registrationId]).done {
                seal.fulfill($0.1.first)
            }.catch {
                seal.reject($0)
            }
        }
    }

    func retrieve(userId: Int, page: Int = 1) -> Promise<(Meta, [Device])> {
        self.retrieve(params: ["user": userId, "page": page])
    }

    func retrieve(deviceId: Int, headers: HTTPHeaders = AuthInfo.shared.initialHTTPHeaders) -> Promise<Device> {
        Promise { seal in
            self.manager.request(
                "\(StepikApplicationsInfo.apiURL)/\(self.name)/\(deviceId)",
                parameters: [:],
                headers: headers
            ).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    seal.reject(NetworkError(error: error))
                case .success(let json):
                    if let r = response.response,
                       !(200...299 ~= r.statusCode) {
                        switch r.statusCode {
                            // when we pass wrong (but existing) device id we get 403 with error presented in field "detail"
                        case 403, 404:
                            return seal.reject(DeviceError.notFound)
                        default:
                            return seal.reject(
                                DeviceError.other(error: nil, code: r.statusCode, message: json.rawString())
                            )
                        }
                    }
                    seal.fulfill(Device(json: json["devices"].arrayValue[0]))
                }
            }
        }
    }

    //TODO: Update this after errors refactoring. DeviceError is something that should be dealt with
    func update(_ device: Device, headers: HTTPHeaders = AuthInfo.shared.initialHTTPHeaders) -> Promise<Device> {
        Promise { seal in
            guard let deviceId = device.id else {
                throw DeviceError.notFound
            }

            let params: Parameters? = [
                "device": device.json as AnyObject
            ]

            self.manager.request(
                "\(StepikApplicationsInfo.apiURL)/\(self.name)/\(deviceId)",
                method: .put,
                parameters: params,
                encoding: JSONEncoding.default,
                headers: headers
            ).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    seal.reject(error)
                case .success(let json):
                    if let r = response.response,
                       !(200...299 ~= r.statusCode) {
                        switch r.statusCode {
                        case 404:
                            return seal.reject(DeviceError.notFound)
                        default:
                            return seal.reject(
                                DeviceError.other(error: nil, code: r.statusCode, message: json.rawString())
                            )
                        }
                    }
                    seal.fulfill(Device(json: json["devices"].arrayValue[0]))
                }
            }
        }
    }

    //TODO: Update this after errors refactoring. DeviceError is something that should be dealt with
    func create(_ device: Device, headers: HTTPHeaders = AuthInfo.shared.initialHTTPHeaders) -> Promise<Device> {
        let params = ["device": device.json]

        return Promise { seal in
            manager.request(
                "\(StepikApplicationsInfo.apiURL)/devices",
                method: .post,
                parameters: params,
                encoding: JSONEncoding.default,
                headers: headers
            ).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    seal.reject(error)
                case .success(let json):
                    if let r = response.response,
                       !(200...299 ~= r.statusCode) {
                        switch r.statusCode {
                        case 404:
                            return seal.reject(DeviceError.notFound)
                        default:
                            return seal.reject(
                                DeviceError.other(
                                    error: nil,
                                    code: r.statusCode,
                                    message: json.rawString()
                                )
                            )
                        }
                    }
                    seal.fulfill(Device(json: json["devices"].arrayValue[0]))
                }
            }
        }
    }

    //TODO: Update this after errors refactoring. DeviceError is something that should be dealt with
    func delete(_ deviceId: Int, headers: HTTPHeaders = APIDefaults.Headers.bearer) -> Promise<Void> {
        Promise { seal in
            self.manager.request(
                "\(StepikApplicationsInfo.apiURL)/devices/\(deviceId)",
                method: .delete,
                headers: headers
            ).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    seal.reject(error)
                case .success(let json):
                    if let r = response.response,
                       !(200...299 ~= r.statusCode) {
                        switch r.statusCode {
                        case 404:
                            return seal.reject(DeviceError.notFound)
                        default:
                            return seal.reject(
                                DeviceError.other(error: nil, code: r.statusCode, message: json.rawString())
                            )
                        }
                    }
                    seal.fulfill(())
                }
            }
        }
    }

    private func retrieve(
        params: Parameters,
        headers: HTTPHeaders = AuthInfo.shared.initialHTTPHeaders
    ) -> Promise<(Meta, [Device])> {
        Promise { seal in
            self.manager.request(
                "\(StepikApplicationsInfo.apiURL)/\(self.name)",
                parameters: params,
                headers: headers
            ).responseSwiftyJSON { response in
                switch response.result {
                case .failure(let error):
                    seal.reject(NetworkError(error: error))
                case .success(let json):
                    if let r = response.response,
                       !(200...299 ~= r.statusCode) {
                        switch r.statusCode {
                        case 404:
                            return seal.reject(DeviceError.notFound)
                        default:
                            return seal.reject(
                                DeviceError.other(error: nil, code: r.statusCode, message: json.rawString())
                            )
                        }
                    }

                    let meta = Meta(json: json["meta"])
                    let devices = json["devices"].arrayValue.map { Device(json: $0) }

                    seal.fulfill((meta, devices))
                }
            }
        }
    }
}

enum DeviceError: Error {
    case notFound
    case other(error: Error?, code: Int?, message: String?)
}

extension DevicesAPI {
    @available(*, deprecated, message: "Legacy method with callbacks")
    @discardableResult
    func create(
        _ device: Device,
        headers: HTTPHeaders = APIDefaults.Headers.bearer,
        success: @escaping (Device) -> Void,
        error errorHandler: @escaping (String) -> Void
    ) -> Request? {
        self.create(device, headers: headers).done { success($0) }.catch { errorHandler($0.localizedDescription) }
        return nil
    }

    @discardableResult
    func delete(
        _ deviceId: Int,
        headers: HTTPHeaders = APIDefaults.Headers.bearer,
        success: @escaping () -> Void,
        error errorHandler: @escaping (DeviceError) -> Void
    ) -> Request? {
        self.delete(deviceId, headers: headers).done {
            success()
        }.catch { error in
            if let deviceError = error as? DeviceError {
                errorHandler(deviceError)
            } else {
                errorHandler(.other(error: error, code: nil, message: nil))
            }
        }
        return nil
    }

    @discardableResult
    func retrieve(
        _ deviceId: Int,
        headers: HTTPHeaders = APIDefaults.Headers.bearer,
        success: @escaping (Device) -> Void,
        error errorHandler: @escaping (String) -> Void
    ) -> Request? {
        self.retrieve(deviceId: deviceId, headers: headers)
            .done { success($0) }
            .catch { errorHandler($0.localizedDescription) }
        return nil
    }
}
