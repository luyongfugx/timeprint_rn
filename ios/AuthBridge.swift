//
//  AuthBridge.swift
//  timeprint_rn
//
//  Created by waynelu on 2025/11/2.
//

import Foundation
import React 
@objc(AuthBridge)
class AuthBridge: NSObject {
  
  @objc
  func saveSession(_ sessionJson: String) {
    let defaults = UserDefaults.standard
    defaults.set(sessionJson, forKey: "supabase_session")
  }

  @objc
  func getSession(_ resolve: RCTPromiseResolveBlock,
                  reject: RCTPromiseRejectBlock) {
    let defaults = UserDefaults.standard
    if let session = defaults.string(forKey: "supabase_session") {
      resolve(session)
    } else {
      resolve(nil)
    }
  }
}
