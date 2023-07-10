//
//  AddDeviceViewController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/9/23.
//

import Foundation
import UIKit
import FittedSheets

class AddNewDeviceViewController: UIViewController {

    override func viewDidLoad() {

        super.viewDidLoad()

        configureSheetController()
    }

    private func configureSheetController() {
        let sheeetOptions = SheetOptions(
            useInlineMode: true,
            isRubberBandEnabled: true
        )

        let allowedSheetSizes = [SheetSize.percent(0.4), SheetSize.percent(0.7), SheetSize.percent(0.1)]

        let sheetController = SheetViewController(controller: self, sizes: allowedSheetSizes, options: sheeetOptions)
        sheetController.allowGestureThroughOverlay = true

        sheetController.shouldDismiss = { _ in
        // This is called just before the sheet is dismissed. Return false to prevent the build in dismiss events
            return false
        }
        // The size of the grip in the pull bar
        sheetController.gripSize = CGSize(width: 50, height: 6)
        sheetController.gripColor = UIColor(red: 60/255, green: 60/255, blue: 67/255, alpha: 0.3)
        sheetController.overlayColor = UIColor.clear

        // The corner curve of the sheet (iOS 13 or later)
        sheetController.cornerCurve                 = .continuous

        // minimum distance above the pull bar, prevents bar from coming right up to the edge of the screen
        sheetController.minimumSpaceAbovePullBar    = 0

        // Determine if the rounding should happen on the pullbar or the presented controller only (should only be true when the pull bar's background color is .clear)
        sheetController.treatPullBarAsClear         = false

        // Disable the dismiss on background tap functionality
        sheetController.dismissOnOverlayTap         = false

        // Disable the ability to pull down to dismiss the modal
        sheetController.dismissOnPull               = false

        /// Allow pulling past the maximum height and bounce back. Defaults to true.
        sheetController.allowPullingPastMaxHeight   = false

        /// Automatically grow/move the sheet to accomidate the keyboard. Defaults to true.
        sheetController.autoAdjustToKeyboard        = true

        sheetController.contentBackgroundColor      = .clear

        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.backgroundColor = UIColor.init(red: 243/255, green: 243/255, blue: 243/255, alpha: 0.7)

        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)

//        // Disable panning on Sheet when interacting with the table.
//        sheetController.panGestureShouldBegin = {
//            _ in
//
//            return !self.tableView.isTracking
//        }
        // animate in
        sheetController.animateIn()
    }
}
