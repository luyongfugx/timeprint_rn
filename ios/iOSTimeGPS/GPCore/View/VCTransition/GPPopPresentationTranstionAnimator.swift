//
//  GPPopPresentationTranstionAnimator.swift
//  XCamera
//
//  Created byBatMan on 2022/3/16.
//  Copyright © 2022 xhey. All rights reserved.
//

import UIKit

open class GPPopPresentationTranstionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

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

        guard let toViewController = transitionContext.viewController(forKey: .to) else { return }

        let fromView = transitionContext.view(forKey: .from)
        let toView = transitionContext.view(forKey: .to)

        let containerView = transitionContext.containerView

        let toFinalFrame = transitionContext.finalFrame(for: toViewController)

        if let _toView = toView {
            containerView.addSubview(_toView)
        }

        let isPresenting = self.isPresenting

        if isPresenting {
            toView?.alpha = 0
            toView?.frame = toFinalFrame
            toView?.transform = .identity.scaledBy(x: 0.8, y: 0.8)
        }

        animation(duration: duration) {
            if isPresenting {
                toView?.transform = .identity
                toView?.alpha = 1
            } else {
                fromView?.alpha = 0
                fromView?.transform = .identity.scaledBy(x: 0.8, y: 0.8)
            }
        } completion: { isFinished in
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

            let parameter = UICubicTimingParameters(controlPoint1: .init(x: 0.19, y: 1.0), controlPoint2: .init(x: 0.22, y: 1.0))
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
