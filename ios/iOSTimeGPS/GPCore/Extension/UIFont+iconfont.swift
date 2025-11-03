//
//  UIFont.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/19.
//

import Foundation
import UIKit

extension UIFont {
    
    class func iconfont(_ size: CGFloat) -> UIFont {
        return UIFont(name: "iconFont", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
}

enum IconFontType: String, GPCodable {
    case btn_refresh = "\u{e604}"
    case btn_album = "\u{e627}"
    case btn_ratio_full = "\u{e641}"
    case btn_ratio_1X1 = "\u{e693}"
    case btn_ratio_3X4 = "\u{e694}"
    case btn_ratio_9X16 = "\u{e695}"
    case btn_countdown = "\u{e663}"
    case btn_setting = "\u{e631}"
    case btn_flash_close = "\u{e786}"
    case btn_flash_auto = "\u{e714}"
    case btn_flash_open = "\u{e6da}"
    case btn_close = "\u{e614}"
    case btn_add_logo = "\u{e640}"
    case btn_next = "\u{e6a2}"
    case btn_back = "\u{e63e}"
    case btn_template = "\u{e666}"
    case btn_add_item = "\u{e62c}"
    case btn_delete_item = "\u{e63c}"
    case btn_quick_edit = "\u{e72b}"
    case btn_daojishi = "\u{e618}"

    // 手电筒
    case btn_flashlight = "\u{ea2b}"
    case btn_nighmode = "\u{e686}"
    case album_share = "\u{e608}"
    case album_delete = "\u{e66d}"
    case album_watermark = "\u{e723}"
    case album_edit = "\u{e616}"
    case album_more = "\u{e679}"
    case cam_focus = "\u{e605}"
    
    case icon_search = "\u{e623}"
    case icon_location = "\u{e612}"
    case icon_choose = "\u{e610}"
    case icon_camera1 = "\u{e624}"
    case icon_camera2 = "\u{e634}"
    case icon_camera3 = "\u{e63d}"
}

