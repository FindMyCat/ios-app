//
//  DeviceBottomDrawerController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/24/23.
//

import Foundation
import UIKit
import FittedSheets

class DeviceBottomDrawerController : UIViewController {
    
    private var parentVc: UIViewController
    private var parentView: UIView
    
    public let controller: UIViewController
    
    private var stackView = UIStackView()
    private var drawerLabel = UILabel()
    
    init(parentView: UIView, parentVc: UIViewController) {
        self.parentVc = parentVc
        self.parentView = parentView
        
        controller = UIViewController()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        view.isUserInteractionEnabled = false

        let options = SheetOptions(
            useInlineMode: true
        )

        let sheetController = SheetViewController(controller: self.controller, sizes: [.percent(0.3), .percent(0.6)], options: options)
        sheetController.allowGestureThroughOverlay = true
        

        sheetController.shouldDismiss = { _ in
        // This is called just before the sheet is dismissed. Return false to prevent the build in dismiss events
            return false
        }
        // The size of the grip in the pull bar
        sheetController.gripSize = CGSize(width: 50, height: 6)
        sheetController.overlayColor = UIColor.clear


        // The corner curve of the sheet (iOS 13 or later)
        sheetController.cornerCurve = .continuous


        // minimum distance above the pull bar, prevents bar from coming right up to the edge of the screen
        sheetController.minimumSpaceAbovePullBar = 0


        // Determine if the rounding should happen on the pullbar or the presented controller only (should only be true when the pull bar's background color is .clear)
        sheetController.treatPullBarAsClear = false

        // Disable the dismiss on background tap functionality
        sheetController.dismissOnOverlayTap = false

        // Disable the ability to pull down to dismiss the modal
        sheetController.dismissOnPull = false

        /// Allow pulling past the maximum height and bounce back. Defaults to true.
        sheetController.allowPullingPastMaxHeight = false

        /// Automatically grow/move the sheet to accomidate the keyboard. Defaults to true.
        sheetController.autoAdjustToKeyboard = true

    
        // animate in
        sheetController.animateIn(to: self.parentView, in: self.parentVc)

        configureStackView()
        configureDrawerLabel()
    }
    
    func configureStackView() {
        
        controller.view.addSubview(stackView)
        
        stackView.axis = .horizontal
        // constraints
        stackView.translatesAutoresizingMaskIntoConstraints                                                  = false
        stackView.topAnchor.constraint(equalTo: controller.view.topAnchor, constant: 20).isActive            = true
        stackView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: 20).isActive    = true
        stackView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -20).isActive = true
        stackView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor, constant: 20).isActive      = true
    }
    
    func configureDrawerLabel() {
        stackView.addSubview(drawerLabel)
        
        drawerLabel.text = "Devices"
        drawerLabel.font =  UIFont.boldSystemFont(ofSize: 20)
        
        // constraints
        drawerLabel.translatesAutoresizingMaskIntoConstraints = false
    }
}
