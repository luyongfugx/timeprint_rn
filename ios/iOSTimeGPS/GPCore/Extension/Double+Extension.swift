//
//  Double+Extension.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/4.
//

import Foundation

public extension Double {

    /// Rounds the double to decimal places value

    func roundTo(places:Int) -> Double {

        let divisor = pow(10.0, Double(places))

        return (self * divisor).rounded() / divisor

    }

}
