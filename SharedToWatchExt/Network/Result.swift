//
//  Result.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 23/08/16.
//

import Foundation

public enum Result<T> {
    case success(T)
    case failure(Error)
}
