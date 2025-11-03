//
//  XCameraController.swift
//  GestureController
//

import UIKit

protocol XGestureControllerDelegate: AnyObject {
    func XGestureSingleTap(_ point: CGPoint, gesture: UITapGestureRecognizer)
    func XGestureDoubleTap(_ point: CGPoint, gesture: UITapGestureRecognizer)
    func XGesturePinch(_ scale: CGFloat, gesture: UIPinchGestureRecognizer)
    func XGestureLongPress(_ point: CGPoint, gesture: UILongPressGestureRecognizer)
    func XGesturePanStart(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer)
    func XGesturePanValueChange(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer)
    func XGesturePanEnd(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer)
    func XGestureSwipe(gesture: UISwipeGestureRecognizer)
}

extension XGestureControllerDelegate {
    func XGestureSingleTap(_ point: CGPoint, gesture: UITapGestureRecognizer) {}
    func XGestureDoubleTap(_ point: CGPoint, gesture: UITapGestureRecognizer) {}
    func XGesturePinch(_ scale: CGFloat, gesture: UIPinchGestureRecognizer) {}
    func XGestureLongPress(_ point: CGPoint, gesture: UILongPressGestureRecognizer) {}
    func XGesturePanStart(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer) {}
    func XGesturePanValueChange(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer) {}
    func XGesturePanEnd(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer) {}
    func XGestureSwipe(gesture: UISwipeGestureRecognizer) {}
}

class GPXGesture: GestureControllerDelegate {
    
    enum DirectionType {
        case horizontal
        case vertical
        case unknow
    }
    
    enum Direction: String {
        case up = "↑"
        case left = "←"
        case down = "↓"
        case right = "→"
        case unknow = "unkown"
    }
    
    weak var delegate: XGestureControllerDelegate?
    
    var gestureControl: GPGesture
    var panDirectionType: DirectionType = .unknow
    
    init(contentView: UIView, info: [String: Any]) {
        gestureControl = GPGesture(contentView: contentView, info: info)
        gestureControl.delegate = self
    }
    
    func GestureControllerPanAction(_ gesture: UIPanGestureRecognizer, sender: GPGesture) {
        guard let contentView = gesture.view else {
            return
        }
        
        let transOffset = gesture.translation(in: contentView)
        
        var direction: Direction = determinDirection(directionType: panDirectionType, transOffset: transOffset)
        
        switch gesture.state {
            
        case .changed:
            
            if panDirectionType == .unknow {
                //determine direction
                panDirectionType = determinDirectionType(transOffset)
                direction = determinDirection(directionType: panDirectionType, transOffset: transOffset)
                
                let offset = getOffsetFrom(transOffset: transOffset, directionType: panDirectionType)
                delegate?.XGesturePanStart(direction, offset: offset, gesture: gesture)
                
            } else {
                
                let offset = getOffsetFrom(transOffset: transOffset, directionType: panDirectionType)
                delegate?.XGesturePanValueChange(direction, offset: offset, gesture: gesture)
            }
            
        case .ended, .failed, .cancelled:
            
            let offset = getOffsetFrom(transOffset: transOffset, directionType: panDirectionType)
            delegate?.XGesturePanEnd(direction, offset: offset, gesture: gesture)
            
            panDirectionType = .unknow
        default:
            break
        }
    }
    
    func GestureControllerLongPressAction(_ gesture: UILongPressGestureRecognizer, sender: GPGesture) {
        let point = gesture.location(in: gesture.view)
        delegate?.XGestureLongPress(point, gesture: gesture)
    }
    
    func GestureControllerPinchAction(_ gesture: UIPinchGestureRecognizer, sender: GPGesture) {
        delegate?.XGesturePinch(gesture.scale, gesture: gesture)
    }
    
    func GestureControllerDoubleTapAction(_ gesture: UITapGestureRecognizer, sender: GPGesture) {
        let point = gesture.location(in: gesture.view)
        delegate?.XGestureDoubleTap(point, gesture: gesture)
    }
    
    func GestureControllerTapAction(_ gesture: UITapGestureRecognizer, sender: GPGesture) {
        let point = gesture.location(in: gesture.view)
        delegate?.XGestureSingleTap(point, gesture: gesture)
    }
    
    func GestureControllerSwipeAction(_ gesture: UISwipeGestureRecognizer, sender: GPGesture) {
        delegate?.XGestureSwipe(gesture: gesture)
    }
    
    private func getOffsetFrom(transOffset: CGPoint, directionType: DirectionType) -> CGFloat {
        var offset: CGFloat = 0
        switch directionType {
        case .horizontal:
            offset = transOffset.x
        case .vertical:
            offset = transOffset.y
        default:
            break
        }
        return offset
    }
    
    private func determinDirectionType(_ transOffset: CGPoint) -> DirectionType {
        
        let directionType: DirectionType
        
        if fabs(transOffset.x) >= fabs(transOffset.y) {
            directionType = .horizontal
        } else {
            directionType = .vertical
        }
        
        return directionType
    }
    
    private func determinDirection(directionType: DirectionType, transOffset: CGPoint) -> Direction {
        
        let direction: Direction
        
        switch directionType {
            
        case .horizontal:
            if transOffset.x >= 0 {
                direction = .right
            } else {
                direction = .left
            }
            
        case .vertical:
            if transOffset.y >= 0 {
                direction = .down
            } else {
                direction = .up
            }
            
        default:
            direction = .unknow
        }
        
        return direction
    }
}

