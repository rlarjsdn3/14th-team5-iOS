//
//  Button.swift
//  BBAlert
//
//  Created by 김건우 on 8/7/24.
//

import UIKit

extension BBAlert {
    
    public enum Button {
        case normal(title: String? = nil, tint: UIColor? = nil, action: ((BBAlert?) -> Void)? = nil)
        case cancel
    }
    
}
