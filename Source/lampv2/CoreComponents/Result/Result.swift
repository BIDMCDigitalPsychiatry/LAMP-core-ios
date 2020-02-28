//
//  Result.swift
//  lampv2
//
//  Created by ZCO Engineer on 23/08/16.
//  Copyright © 2020 lamp All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(LMError)
}
