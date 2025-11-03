//
//  GPPresentationController.swift
//  XCamera
//
//  Created byBatMan on 2021/11/30.
//  Copyright © 2021 xhey. All rights reserved.
//

import UIKit

@objc protocol GPPresentationControllerTransitioning: NSObjectProtocol {

    @objc optional func preferredDimmingViewBackgroundColor(for presentationController: UIPresentationController) -> UIColor?

    @objc optional func preferredCornerRadius(for presentationController: UIPresentationController) -> CGFloat

    @objc optional func presentAnimator(for presentedViewController: UIViewController) -> UIViewControllerAnimatedTransitioning?

    @objc optional func dismissAnimator(for dismissedViewController: UIViewController) -> UIViewControllerAnimatedTransitioning?

    /// 判断`presentedViewController`是否可以手动点击`dimiss`
    /// - Returns: `true` or `false`
    @objc optional func viewControllerShouldManualDismiss(_ presentedViewController: UIViewController, for presentationController: UIPresentationController) -> Bool

    /// `presentedViewController`即将通过手动方式消失
    @objc optional func viewControllerWillManualDismiss(_ presentedViewController: UIViewController, by presentationController: UIPresentationController)
}

open class GPPresentationController: UIPresentationController, UIViewControllerTransitioningDelegate {

    private var dimmingView: UIView?
    private var presentationWrapperView: UIView?

    private let defaultCornerRadius: CGFloat = 10

    public override init(presentedViewController: UIViewController, presenting: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presenting)
        presentedViewController.modalPresentationStyle = .custom
    }

    open override var presentedView: UIView? {
        presentationWrapperView
    }

    open override var shouldPresentInFullscreen: Bool {
        true
    }

    open override func presentationTransitionWillBegin() {

        /// shadowView <- shadow
        ///     -- roundCornerView <- rounded corners (masksToBounds)
        ///         -- presentedWrapperView
        ///             -- presentedView (presentedViewController.view)

        /// shadow
        let shadowView = UIView(frame: frameOfPresentedViewInContainerView)
        shadowView.layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.shadowRadius = 20
        shadowView.layer.shadowOffset = .init(width: 0.0, height: -6.0)
        self.presentationWrapperView = shadowView

        /// 圆角
        var cornerRadius: CGFloat = defaultCornerRadius

        if let one = presentedViewController as? GPPresentationControllerTransitioning {
            cornerRadius = one.preferredCornerRadius?(for: self) ?? defaultCornerRadius
        }

        /// round corner
        let roundCornerView = UIView(frame: shadowView.bounds.inset(by: .init(top: 0, left: 0, bottom: -cornerRadius, right: 0)))
        roundCornerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        roundCornerView.layer.cornerRadius = cornerRadius
        roundCornerView.layer.masksToBounds = true

        /// presentedWrapper & presentedView
        let presentedWrapperView = UIView(frame: roundCornerView.bounds.inset(by: .init(top: 0, left: 0, bottom: cornerRadius, right: 0)))
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
            _dimmingView.backgroundColor = .black.withAlphaComponent(0.5)

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

            transitionCoordinator?.animate { _ in
                self.dimmingView?.alpha = 1
            }
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

        guard let transitionCoordinator = presentingViewController.transitionCoordinator else {
            return
        }

        if transitionCoordinator.isAnimated {
            transitionCoordinator.animate { _ in
                self.dimmingView?.alpha = 0.0
            }
        } else {
             dimmingView?.alpha = 0.0
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

    open override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        if let _presentedViewController = container as? UIViewController,
           _presentedViewController == self.presentedViewController {
            containerView?.setNeedsLayout()
        }
    }

    open override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {

        guard let _presentedViewController = container as? UIViewController,
              _presentedViewController == self.presentedViewController
        else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }

        return _presentedViewController.preferredContentSize
    }

    open override var frameOfPresentedViewInContainerView: CGRect {

        let containerViewBounds = containerView?.bounds ?? UIScreen.main.bounds

        let presentedViewControllerContentSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerViewBounds.size)

        var presentedViewControllerFrame = containerViewBounds
        presentedViewControllerFrame.size.height = presentedViewControllerContentSize.height
        presentedViewControllerFrame.origin.y = containerViewBounds.maxY - presentedViewControllerContentSize.height
        return presentedViewControllerFrame
    }

    open override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView?.frame = containerView?.bounds ?? UIScreen.main.bounds
        presentationWrapperView?.frame = frameOfPresentedViewInContainerView
    }

    // MARK: UIViewControllerTransitioningDelegate

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard self.presentedViewController == presented else {
            return nil
        }
        return self
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let protocolViewController = presentedViewController as? GPPresentationControllerTransitioning,
           let animator = protocolViewController.presentAnimator?(for: presented) {
            return animator
        }
        return GPPresentationTransitionAnimator(isPresenting: true, duration: 0.35)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let protocolViewController = presentedViewController as? GPPresentationControllerTransitioning,
           let animator = protocolViewController.dismissAnimator?(for: dismissed) {
            return animator
        }
        return GPPresentationTransitionAnimator(isPresenting: false, duration: 0.3)
    }
}

@objc
private extension GPPresentationController {

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
