//
//  XHCodablePropertyWrapper.swift
//  XCamera
//
//  Created by batman on 2021/7/18.
//  Copyright © 2021 xhey. All rights reserved.
//

import Foundation

typealias DefaultCodable<T> = Default<T> where T: DefaultValue
typealias LosslessCodable<T> = Lossless<T> where T: LosslessValue

