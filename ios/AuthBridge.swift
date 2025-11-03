//
//  AuthBridge.swift
//  timeprint_rn
//
//  Created by waynelu on 2025/11/2.
//

import Foundation
import React
import UIKit

@objc(AuthBridge)
class AuthBridge: NSObject {

  @objc
  func saveSession(_ sessionJson: String) {
    let defaults = UserDefaults.standard
    defaults.set(sessionJson, forKey: "supabase_session")
  }

  @objc
  func getSession(
    _ resolve: RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    let defaults = UserDefaults.standard
    if let session = defaults.string(forKey: "supabase_session") {
      resolve(session)
    } else {
      resolve(nil)
    }
  }

  @objc
  func saveTeamInfo(_ teamInfo: String) {
    let defaults = UserDefaults.standard
    defaults.set(teamInfo, forKey: "teamInfo")
  }

  @objc
  func getTeamInfo(
    _ resolve: RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    let defaults = UserDefaults.standard
    if let session = defaults.string(forKey: "teamInfo") {
      resolve(session)
    } else {
      resolve(nil)
    }
  }

  @objc
  func dismissReactNative() {
    // 打印日志以确认此方法是否被调用
    print("[AuthBridge] dismissReactNative called")
    NSLog("[AuthBridge] dismissReactNative called")
//    DispatchQueue.main.async {
//          guard let window = UIApplication.shared.windows.first else { return }
//
//          // ✅ 改成你原生的首页或你想返回的 VC
//          let nativeVC = HomeViewController()
//
//          window.rootViewController = nativeVC
//          window.makeKeyAndVisible()
//      }
    DispatchQueue.main.async {
        let app = UIApplication.shared.delegate as! AppDelegate
        guard let window = UIApplication.shared.windows.first else { return }
        
        if let oldVC = app.savedNativeVC {
            window.rootViewController = oldVC
            window.makeKeyAndVisible()
        }
    }
    
//    DispatchQueue.main.async {
//      if let keyWindow = UIApplication.shared.keyWindow,
//        let rootViewController = keyWindow.rootViewController
//      {
//        NSLog("[AuthBridge] will dismiss rootViewController")
//        rootViewController.dismiss(animated: true, completion: nil)
//      } else {
//        NSLog("[AuthBridge] no keyWindow or rootViewController found")
//      }
//    }
  }
}
