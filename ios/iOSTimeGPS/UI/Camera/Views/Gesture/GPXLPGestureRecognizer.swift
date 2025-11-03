//
//  XLongPressGestureRecognizer.swift
//  XCamera
//

import UIKit

protocol XLongPressGestureRecognizerCallback: AnyObject {
    func recognizer(_ : GPXLPGestureRecognizer, changedState state: UIGestureRecognizer.State)
}
class GPXLPGestureRecognizer: UILongPressGestureRecognizer {
    weak var callback: XLongPressGestureRecognizerCallback?
    
    private var lastState: UIGestureRecognizer.State = .ended
    private var lastPoint = CGPoint(x: -1, y: -1)
    
    convenience init() {
        self.init(target: nil, action: nil)
    }
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        addTarget(self, action: #selector(handleAction))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        callbackIfChanged(state)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        callbackIfChanged(state)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        callbackIfChanged(state)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        callbackIfChanged(state)
    }
    
    override func reset() {
        super.reset()
        lastState = .ended
    }
    
    @objc func handleAction(_ gesture: GPXLPGestureRecognizer) {
        callbackIfChanged(gesture.state, fromAction: true)
    }
    
    private func callbackIfChanged(_ state: UIGestureRecognizer.State, fromAction: Bool = false) {
        if state != lastState {
            callback?.recognizer(self, changedState: state)
            lastState = state
        } else {
            if state == .changed && fromAction {
                callback?.recognizer(self, changedState: state)
            }
        }
    }
}

