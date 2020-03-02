//
//  Result.swift
//  lampv2
//
//  Created by ZCO Engineer on 23/08/16.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(LMError)
}
