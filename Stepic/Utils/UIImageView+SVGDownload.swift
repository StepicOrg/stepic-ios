//
//  UIImageView+SVGDownload.swift
//  Stepic
//
//  Created by Alexander Karpov on 20.02.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation
import SDWebImage
import Alamofire
#if !os(tvOS)
import SVGKit
#endif

extension UIImageView {

    func setImageWithURL(url optionalURL: URL?, placeholder: UIImage, completion: (() -> Void)? = nil) {
        guard let url = optionalURL else {
            self.image = placeholder
            completion?()
            return
        }

        guard url.pathExtension != "svg" else {
            #if !os(tvOS)
                self.image = placeholder
                AlamofireDefaultSessionManager.shared.request(url).responseData(completionHandler: {
                    response in
                    if response.result.error != nil {
                        return
                    }

                    guard let data = response.result.value else {
                        return
                    }

                    DispatchQueue.global(qos: .userInitiated).async {
                        let svgImage = SVGKImage(data: data)
                        if !(svgImage?.hasSize() ?? true) {
                            svgImage?.size = CGSize(width: 200, height: 200)
                        }
                        let img = svgImage?.uiImage ?? placeholder
                        DispatchQueue.main.async {
                            self.image = img
                        }
                    }
                })
            #endif
            return
        }

        self.sd_setImage(with: optionalURL, placeholderImage: placeholder, options: SDWebImageOptions.retryFailed, completed: { _, _, _, _ in
            completion?()
        })
    }
}
