//
//  ProfileInfoPresenter.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 21.05.18.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//
import UIKit

extension UIView {
    class func fromNib<T: UIView>() -> T {
        Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }

    class func fromNib(named: String) -> UIView {
        Bundle.main.loadNibNamed(named, owner: nil, options: nil)![0] as! UIView
    }
}
