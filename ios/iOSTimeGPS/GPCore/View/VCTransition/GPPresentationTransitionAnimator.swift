//
//  GPPresentationTransitionAnimator.swift
//  XCamera
//
//  Created by BatMan on 2021/11/30.
//  Copyright © 2021 xhey. All rights reserved.
//

import UIKit
import SwiftUI

open class GPPresentationTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    /// indicate `present` or `dismiss`
    public let isPresenting: Bool

    /// Description
    /// - Parameter isPresenting: isPresenting description
    init(isPresenting: Bool, duration: TimeInterval) {
        self.isPresenting = isPresenting
        self.duration = duration
        super.init()
    }

    /// time interval for transition
    /// default is `0.35`
    open var duration: TimeInterval = 0.35

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        (transitionContext?.isAnimated ?? false) ? duration : 0
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to) else { return }

        let fromView = transitionContext.view(forKey: .from)
        let toView = transitionContext.view(forKey: .to)

        let containerView = transitionContext.containerView

//        var fromInitialFrame = transitionContext.initialFrame(for: fromViewController)
        var fromFinalFrame = transitionContext.finalFrame(for: fromViewController)

        var toInitialFrame = transitionContext.initialFrame(for: toViewController)
        let toFinalFrame = transitionContext.finalFrame(for: toViewController)

        if let _toView = toView {
            containerView.addSubview(_toView)
        }

        let isPresenting = self.isPresenting

        if isPresenting {
            toInitialFrame.origin = .init(x: containerView.bounds.minX, y: containerView.bounds.maxY)
            toInitialFrame.size = toFinalFrame.size
            toView?.frame = toInitialFrame
        } else {
            if let _fromView = fromView {
                fromFinalFrame = _fromView.frame.offsetBy(dx: 0, dy: _fromView.frame.height)
            }
        }

        if transitionContext.isAnimated {
            animation(duration: duration) {
                if isPresenting {
                    toView?.frame = toFinalFrame
                } else {
                    fromView?.frame = fromFinalFrame
                }
            } completion: { isFinished in
                let wasCancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!wasCancelled)
            }
        } else {
            if isPresenting {
                toView?.frame = toFinalFrame
            } else {
                fromView?.frame = fromFinalFrame
            }
            let wasCancelled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!wasCancelled)
        }
    }

    private enum Animation {
        case view
        case property
    }

    private func animation(duration: TimeInterval, animation: @escaping () -> Void, completion: @escaping (Bool) -> Void) {
        _dynamicAnimation(animationType: .property, duration: duration, animation: animation, completion: completion)
    }

    private func _dynamicAnimation(animationType: Animation, duration: TimeInterval, animation: @escaping () -> Void, completion: @escaping (Bool) -> Void) {

        switch animationType {
            case .view:

                UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: animation, completion: completion)

            case .property:

//                let parameter = UISpringTimingParameters(damping: 0.85, response: 0.35, initialVelocity: .zero)
            let parameter = UISpringTimingParameters(dampingRatio: 0.85, initialVelocity: .zero)

                let animator = UIViewPropertyAnimator(duration: duration, timingParameters: parameter)
                animator.addAnimations {
                    animation()
                }

                animator.addCompletion { position in
                    if position == .end {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
                animator.startAnimation()
        }
    }
}
