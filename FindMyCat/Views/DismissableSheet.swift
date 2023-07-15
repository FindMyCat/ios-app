//
//  DismissableSheet.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/12/23.
//

import UIKit

class DismissableSheet: UIView {

    let closeButton = UIButton()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 48
        translatesAutoresizingMaskIntoConstraints = false

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        addGestureRecognizer(panGesture)

        addCloseButton()

    }

    func addCloseButton() {
        addSubview(closeButton)

        var configuration = UIButton.Configuration.tinted()
        configuration.cornerStyle = .capsule

        closeButton.configuration = configuration

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: imageConfig), for: .normal)

        closeButton.tintColor = .gray

        closeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24),
            closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 24),
            closeButton.widthAnchor.constraint(equalToConstant: 25),
            closeButton.heightAnchor.constraint(equalToConstant: 25)
        ])
        closeButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
    }

    // MARK: - Animation

    func showInView(_ view: UIView, height: CGFloat) {
        view.addSubview(self)

        let bottomConstraint = bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: height)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: view.widthAnchor, constant: -10),
            heightAnchor.constraint(equalToConstant: height),
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomConstraint
        ])

        view.layoutIfNeeded()

        bottomConstraint.constant = -5

        UIView.animate(withDuration: 0.3) {
            view.layoutIfNeeded()
        }
    }

    @objc func dismissSelf() {

        guard let viewController = self.next?.next as? UIViewController else {
                return
            }

        guard let superview = superview else {
            return
        }

        UIView.animate(withDuration: 0.3, animations: {

            self.transform = CGAffineTransform(translationX: 0, y: self.superview?.frame.height ?? 0)

            superview.layoutIfNeeded()
        }) { _ in
            self.removeFromSuperview()

            // Dismiss the navigation controller
            if let navigationController = viewController.navigationController {
                let totalViews = navigationController.viewControllers.count

                if totalViews == 1 {
                    // Last view, dismiss the navigationController
                    navigationController.modalTransitionStyle = .crossDissolve
                    navigationController.dismiss(animated: true)
                } else {
                    navigationController.popViewController(animated: true)
                }

            } else {
                viewController.dismiss(animated: true, completion: nil)
            }
        }
    }

    // MARK: - Gesture Recognizer

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)

        switch gesture.state {
        case .changed:
            if translation.y > 0 || translation.y < 0 {
                transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended, .cancelled:
            if translation.y >= 300 {
                dismissSelf()
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.transform = .identity
                }
            }
        default:
            break
        }
    }

}
