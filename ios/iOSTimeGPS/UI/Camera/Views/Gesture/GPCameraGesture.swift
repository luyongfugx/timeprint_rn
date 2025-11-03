//
//  CameraGestureView.swift
//  XCamera
//

import UIKit

protocol CameraGestureControllerDelegate: AnyObject {
    
    func CameraGestureSwichCamera(_ sender: GPCameraGesture)
    func CameraGestureZoom(_ scale: CGFloat, sender: GPCameraGesture)
    func CameraGestureZoomBegin(_ scale: CGFloat, sender: GPCameraGesture)
    func CameraGestureZoomEnd(_ scale: CGFloat, sender: GPCameraGesture)
    /// V2.9.190版本对焦优化时添加, batman
    func CameraGestureLongPress(_ point: CGPoint, gesture: UILongPressGestureRecognizer)
    func CameraGesturePanStart(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer)
    func CameraGesturePanValueChange(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer)
    func CameraGesturePanEnd(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer)
}

class GPCameraGesture: XGestureControllerDelegate {
    
    weak var delegate: CameraGestureControllerDelegate?
    
    weak var contentView: UIView?
    var gestureController: GPXGesture
    
    init(contentView view: UIView) {
        contentView = view
        let info: [String: Any] = [
            GestureControllerInfoTypes: [GestureType.doubleTap,
                                         GestureType.pinch,
                                         GestureType.pan,
                                         GestureType.longPress],
            
            GestureControllerInfoLongPressSimultaneouslyWithTap: true,
            GestureControllerInfoLongPressSimultaneouslyWithPinch: true
        ]
        gestureController = GPXGesture(contentView: view, info: info)
        gestureController.delegate = self
    }
    
    func XGestureDoubleTap(_ point: CGPoint, gesture: UITapGestureRecognizer) {
        delegate?.CameraGestureSwichCamera(self)
    }
    
    func XGesturePinch(_ scale: CGFloat, gesture: UIPinchGestureRecognizer) {
        
        let newScale: CGFloat = scale * 0.32

        if(gesture.state == .began){
            delegate?.CameraGestureZoomBegin(newScale, sender: self)
        }else if(gesture.state == .changed){
            delegate?.CameraGestureZoom(newScale, sender: self)
        }else {
            delegate?.CameraGestureZoomEnd(newScale, sender: self)
        }
        
    }
    
    func XGestureLongPress(_ point: CGPoint, gesture: UILongPressGestureRecognizer) {
        delegate?.CameraGestureLongPress(point, gesture: gesture)
    }
    
    func XGesturePanStart(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer) {
        
        delegate?.CameraGesturePanStart(direction, offset: offset, gesture: gesture)
    }
    
    func XGesturePanValueChange(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer) {
        
        delegate?.CameraGesturePanValueChange(direction, offset: offset, gesture: gesture)
    }
    
    func XGesturePanEnd(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer) {
        delegate?.CameraGesturePanEnd(direction, offset: offset, gesture: gesture)
    }
    
}

