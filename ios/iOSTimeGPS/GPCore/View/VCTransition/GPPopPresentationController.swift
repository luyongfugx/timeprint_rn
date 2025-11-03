//
//  GPPopPresentationController.swift
//  XCamera
//
//  Created byBatMan on 2022/3/16.
//  Copyright © 2022 xhey. All rights reserved.
//

import UIKit

open class GPPopPresentationController: UIPresentationController {

    private var dimmingView: UIView?
    private var presentationWrapperView: UIView?
    private let defaultCornerRadius: CGFloat = 10

    public override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        presentedViewController.modalPresentationStyle = .custom
    }

    open override var presentedView: UIView? {
        presentationWrapperView
    }

    open override func presentationTransitionWillBegin() {

        /// shadowView <- shadow
        ///     -- roundCornerView <- rounded corners (masksToBounds)
        ///         -- presentedWrapperView
        ///             -- presentedView (presentedViewController.view)

        /// shadow
        let shadowView = UIView(frame: frameOfPresentedViewInContainerView)
        self.presentationWrapperView = shadowView

        /// 圆角
        var cornerRadius: CGFloat = defaultCornerRadius

        if let one = presentedViewController as? GPPresentationControllerTransitioning {
            cornerRadius = one.preferredCornerRadius?(for: self) ?? defaultCornerRadius
        }

        /// round corner
        let roundCornerView = UIView(frame: shadowView.bounds)
        roundCornerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        roundCornerView.layer.cornerRadius = cornerRadius
        roundCornerView.layer.masksToBounds = true

        /// presentedWrapper & presentedView
        let presentedWrapperView = UIView(frame: roundCornerView.bounds)
        presentedWrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if let presentedView = super.presentedView {
            presentedView.frame = presentedWrapperView.bounds
            presentedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            presentedWrapperView.addSubview(presentedView)
        }

        roundCornerView.addSubview(presentedWrapperView)
        shadowView.addSubview(roundCornerView)

        /// dimming
        if let _containerView = self.containerView {
            let _dimmingView = UIView(frame: _containerView.bounds)
            _dimmingView.backgroundColor = .black.withAlphaComponent(0.75)

            if let one = presentedViewController as? GPPresentationControllerTransitioning, let preferredBackgroundColor = one.preferredDimmingViewBackgroundColor?(for: self) {
                _dimmingView.backgroundColor = preferredBackgroundColor
            }
            
            _dimmingView.isOpaque = false
            _dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            _dimmingView.alpha = 0

            let tapR = UITapGestureRecognizer(target: self, action: #selector(dimmingViewDidTap))
            _dimmingView.addGestureRecognizer(tapR)

            self.dimmingView = _dimmingView
            _containerView.addSubview(_dimmingView)

            let transitionCoordinator = presentingViewController.transitionCoordinator

            transitionCoordinator?.animate(alongsideTransition: { _ in
                self.dimmingView?.alpha = 1
            }, completion: nil)
        }
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            presentationWrapperView?.removeFromSuperview()
            dimmingView?.removeFromSuperview()
            presentationWrapperView = nil
            dimmingView = nil
        }
    }

    open override func dismissalTransitionWillBegin() {

        let transitionCoordinator = presentingViewController.transitionCoordinator

        if transitionCoordinator?.isAnimated ?? false {
            transitionCoordinator?.animate(alongsideTransition: { _ in
                self.dimmingView?.alpha = 0.0
            }, completion: nil)
        } else {
            dimmingView?.alpha = 0
            presentationWrapperView?.alpha = 0
        }
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            presentationWrapperView?.removeFromSuperview()
            dimmingView?.removeFromSuperview()
            presentationWrapperView = nil
            dimmingView = nil
        }
    }

    open override var frameOfPresentedViewInContainerView: CGRect {
        let containerViewBounds = containerView?.bounds ?? UIScreen.main.bounds
        let presentedViewControllerContentSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerViewBounds.size)
        let targetFrame: CGRect = .init(x: containerViewBounds.width / 2 - presentedViewControllerContentSize.width / 2, y: containerViewBounds.height / 2 - presentedViewControllerContentSize.height / 2, width: presentedViewControllerContentSize.width, height: presentedViewControllerContentSize.height)
        return targetFrame
    }

    open override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView?.frame = containerView?.bounds ?? UIScreen.main.bounds
        presentationWrapperView?.frame = frameOfPresentedViewInContainerView
    }

    open override func containerViewDidLayoutSubviews() {
        
    }

    open override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {

        guard let _presentedViewController = container as? UIViewController, _presentedViewController == self.presentedViewController else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
        return _presentedViewController.preferredContentSize
    }
}

extension GPPopPresentationController: UIViewControllerTransitioningDelegate {

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let protocolViewController = presentedViewController as? GPPresentationControllerTransitioning,
           let animator = protocolViewController.presentAnimator?(for: presented) {
            return animator
        }
        return GPPopPresentationTranstionAnimator(isPresenting: true, duration: 0.25)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let protocolViewController = presentedViewController as? GPPresentationControllerTransitioning,
           let animator = protocolViewController.dismissAnimator?(for: dismissed) {
            return animator
        }
        return GPPopPresentationTranstionAnimator(isPresenting: false, duration: 0.2)
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard self.presentedViewController == presented else {
            return nil
        }
        return self
    }
}

@objc
private extension GPPopPresentationController {

    func dimmingViewDidTap() {

        var shouldManulDismiss: Bool = true

        if let protocolViewController = presentedViewController as? GPPresentationControllerTransitioning {
            shouldManulDismiss = protocolViewController.viewControllerShouldManualDismiss?(presentedViewController, for: self) ?? true
        }

        if !shouldManulDismiss {
            return
        }

        if let protocolViewController = presentedViewController as? GPPresentationControllerTransitioning {
            protocolViewController.viewControllerWillManualDismiss?(presentedViewController, by: self)
        }
        presentedViewController.dismiss(animated: true, completion: nil)
    }
}
