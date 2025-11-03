//
//  GestureController.swift
//  GestureController
//

import UIKit

//GestureControllerInfoKey
let GestureControllerInfoTypes: String = "gesture_controller_info_types"
let GestureControllerInfoSwipeDirectionType: String = "gesture_controller_info_swipe_direction_type"
let GestureControllerInfoSwipeDirectionParam_up: String = "gesture_controller_info_swipe_direction_up"
let GestureControllerInfoSwipeDirectionParam_down: String = "gesture_controller_info_swipe_direction_down"
let GestureControllerInfoSwipeDirectionParam_left: String = "gesture_controller_info_swipe_direction_left"
let GestureControllerInfoSwipeDirectionParam_right: String = "gesture_controller_info_swipe_direction_right"

//This is key, value is bool. default is false.
let GestureControllerInfoLongPressSimultaneouslyWithTap: String = "gesture_controller_info_long_press_simultaneously_with_tap"
let GestureControllerInfoLongPressSimultaneouslyWithPinch: String = "gesture_controller_info_long_press_simultaneously_with_pinch"

//GestureControllerInfoValue
enum GestureType {
    case tap
    case doubleTap
    case pinch
    case pan
    case XlongPress
    case longPress
    case swipe
}

protocol GestureControllerDelegate: AnyObject {
    func GestureControllerTapAction(_ gesture: UITapGestureRecognizer, sender: GPGesture)
    func GestureControllerDoubleTapAction(_ gesture: UITapGestureRecognizer, sender: GPGesture)
    func GestureControllerPinchAction(_ gesture: UIPinchGestureRecognizer, sender: GPGesture)
    func GestureControllerPanAction(_ gesture: UIPanGestureRecognizer, sender: GPGesture)
    func GestureControllerLongPressAction(_ gesture: UILongPressGestureRecognizer, sender: GPGesture)
    func GestureControllerSwipeAction(_ gesture: UISwipeGestureRecognizer, sender: GPGesture)
}

extension GestureControllerDelegate {
    func GestureControllerTapAction(_ gesture: UITapGestureRecognizer, sender: GPGesture) {}
    func GestureControllerDoubleTapAction(_ gesture: UITapGestureRecognizer, sender: GPGesture) {}
    func GestureControllerPinchAction(_ gesture: UIPinchGestureRecognizer, sender: GPGesture) {}
    func GestureControllerPanAction(_ gesture: UIPanGestureRecognizer, sender: GPGesture) {}
    func GestureControllerLongPressAction(_ gesture: UILongPressGestureRecognizer, sender: GPGesture) {}
    func GestureControllerSwipeAction(_ gesture: UISwipeGestureRecognizer, sender: GPGesture) {}
}

class GPGesture: NSObject {
    
    weak var delegate: GestureControllerDelegate?
    
    weak var contentView: UIView?
    private var tapGesture: UITapGestureRecognizer?
    private var doubleTapGesture: UITapGestureRecognizer?
    private var panGesture: UIPanGestureRecognizer?
    private var swipeGesture: UISwipeGestureRecognizer?
    private var pinchGesture: UIPinchGestureRecognizer?
    private var longPressGesture: UILongPressGestureRecognizer?
    private var info: [String: Any] = [:]
    
    init(contentView view: UIView, info: [String: Any]) {
        super.init()
        
        contentView = view
        self.info = info
        
        createGestureFromInfo(info)
        processGestureParam(info)
        addGestureToContentView()
    }
    
    private func createGestureFromInfo(_ info: [String: Any]) {
        if let types = info[GestureControllerInfoTypes] as? [GestureType] {
            for type in types {
                
                switch type {
                case .tap:
                    tapGesture = UITapGestureRecognizer()
                    break
                case .doubleTap:
                    doubleTapGesture = UITapGestureRecognizer()
                    break
                case .pinch:
                    pinchGesture = UIPinchGestureRecognizer()
                    break
                case .pan:
                    panGesture = UIPanGestureRecognizer()
                    break
                case .longPress:
                    longPressGesture = UILongPressGestureRecognizer()
                    longPressGesture?.minimumPressDuration = 0
                    break
                case .XlongPress:
                    longPressGesture = GPXLPGestureRecognizer()
                    break
                case .swipe:
                    swipeGesture = UISwipeGestureRecognizer()
                    break
                }
            }
        }
    }
    
    private func processGestureParam(_ info: [String: Any]) {
        tapGesture?.numberOfTapsRequired = 1
        tapGesture?.addTarget(self, action: #selector(tapGestureAction(_:)))
        
        doubleTapGesture?.numberOfTapsRequired = 2
        doubleTapGesture?.addTarget(self, action: #selector(doubleTapGestureAction(_:)))
        
        if let xlongPressGesture = longPressGesture as? GPXLPGestureRecognizer {
            xlongPressGesture.callback = self
        } else {
            longPressGesture?.addTarget(self, action: #selector(longPressGestureAction(_:)))
        }
        longPressGesture?.delegate = self
        
        panGesture?.addTarget(self, action: #selector(panPressGestureAction(_:)))
        
        pinchGesture?.addTarget(self, action: #selector(pinchGestureAction(_:)))
        
        if let swipeType = info[GestureControllerInfoSwipeDirectionType] as? String {
            switch swipeType {
            case GestureControllerInfoSwipeDirectionParam_up:
                swipeGesture?.direction = .up
            case GestureControllerInfoSwipeDirectionParam_down:
                swipeGesture?.direction = .down
            case GestureControllerInfoSwipeDirectionParam_left:
                swipeGesture?.direction = .left
            case GestureControllerInfoSwipeDirectionParam_right:
                swipeGesture?.direction = .right
            default:
                break
            }
        }
        swipeGesture?.addTarget(self, action: #selector(swipeGestureAction(_:)))
    }
    
    private func addGestureToContentView() {
        
        if tapGesture != nil {
            contentView?.addGestureRecognizer(tapGesture!)
        }
        
        if doubleTapGesture != nil {
            contentView?.addGestureRecognizer(doubleTapGesture!)
        }
        
        if longPressGesture != nil {
            contentView?.addGestureRecognizer(longPressGesture!)
        }
        
        if panGesture != nil {
            contentView?.addGestureRecognizer(panGesture!)
        }
        
        if pinchGesture != nil {
            contentView?.addGestureRecognizer(pinchGesture!)
        }
        
        if swipeGesture != nil {
            contentView?.addGestureRecognizer(swipeGesture!)
        }
    }
    
    @objc func tapGestureAction(_ gesture: UITapGestureRecognizer) {
        delegate?.GestureControllerTapAction(gesture, sender: self)
    }
    
    @objc func doubleTapGestureAction(_ gesture: UITapGestureRecognizer) {
        delegate?.GestureControllerDoubleTapAction(gesture, sender: self)
    }
    
    @objc func pinchGestureAction(_ gesture: UIPinchGestureRecognizer) {
        delegate?.GestureControllerPinchAction(gesture, sender: self)
    }
    
    @objc func panPressGestureAction(_ gesture: UIPanGestureRecognizer) {
        delegate?.GestureControllerPanAction(gesture, sender: self)
    }
    
    @objc func longPressGestureAction(_ gesture: UILongPressGestureRecognizer) {
        delegate?.GestureControllerLongPressAction(gesture, sender: self)
    }
    
    @objc func swipeGestureAction(_ gesture: UISwipeGestureRecognizer) {
        delegate?.GestureControllerSwipeAction(gesture, sender: self)
    }
}

extension GPGesture: XLongPressGestureRecognizerCallback {
    func recognizer(_ gesture: GPXLPGestureRecognizer, changedState state: UIGestureRecognizer.State) {
        if gesture.state == .began {
            pinchGesture?.isEnabled = false
            pinchGesture?.isEnabled = true
            tapGesture?.isEnabled = false
            tapGesture?.isEnabled = true
        }
        delegate?.GestureControllerLongPressAction(gesture, sender: self)
    }
}

extension GPGesture: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true;
        if gestureRecognizer.isKind(of: UILongPressGestureRecognizer.self) {
            
            if let isLongPressSimulataneouslyWithTap = info[GestureControllerInfoLongPressSimultaneouslyWithTap] as? Bool {
                
                if let _ = otherGestureRecognizer as? UITapGestureRecognizer {
                    return isLongPressSimulataneouslyWithTap
                }
            }
            
            if let isLongPressSimulataneouslyWithPinch = info[GestureControllerInfoLongPressSimultaneouslyWithPinch] as? Bool {
                
                if let _ = otherGestureRecognizer as? UIPinchGestureRecognizer {
                    return isLongPressSimulataneouslyWithPinch
                }
            }
          
        }
        
        return false
    }
}

