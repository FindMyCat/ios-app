//
//  DeviceBottomDrawerController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/24/23.
//

import Foundation
import UIKit
import FittedSheets

class DeviceBottomDrawerController :
        UIViewController,
        UITableViewDelegate,
        UITableViewDataSource
{
    public let controller: UIViewController
    
    private var devices: [Device] = [Device(name: "Pumpkin Cat"), Device(name: "Butter"), Device(name: "Reggie")]
    
    // Parent View + Controller
    private var parentVc: UIViewController
    private var parentView: UIView
    
    // Views
    private var stackView = UIStackView()
    private var drawerLabel = UILabel()
    private var tableView = UITableView()
    

    // Constructor
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

        let sheeetOptions = SheetOptions(
            useInlineMode: true
        )
        
        let allowedSheetSizes = [SheetSize.percent(0.4), SheetSize.percent(0.7), SheetSize.percent(0.1)]

        let sheetController = SheetViewController(controller: self.controller, sizes: allowedSheetSizes, options: sheeetOptions)
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
        
        sheetController.contentBackgroundColor = .clear

        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.backgroundColor = UIColor.init(red: 243/255, green: 243/255, blue: 243/255, alpha: 0.7)

        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller.view.addSubview(blurEffectView)
    
        // animate in
        sheetController.animateIn(to: self.parentView, in: self.parentVc)

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        configureStackView()
        configureDrawerLabel()
        configureHairline()
        configureTableView()
        
    }
    
    func configureStackView() {
        
        controller.view.addSubview(stackView)
        
        stackView.axis = .horizontal
        stackView.backgroundColor = .clear
        // constraints
        stackView.translatesAutoresizingMaskIntoConstraints                                                  = false
        stackView.topAnchor.constraint(equalTo: controller.view.topAnchor, constant: 15).isActive            = true
        stackView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: 15).isActive    = true
        stackView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -15).isActive = true
        stackView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor, constant: 15).isActive      = true
    }
    
    func configureDrawerLabel() {
        stackView.addSubview(drawerLabel)
        
        drawerLabel.text = "Devices"
        drawerLabel.font =  UIFont.boldSystemFont(ofSize: 18)
        drawerLabel.topAnchor.constraint(equalTo: stackView.topAnchor).isActive            = true
        
        // constraints
        drawerLabel.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    func configureHairline() {
        let hairline = UIView()
        stackView.addSubview(hairline)
        hairline.translatesAutoresizingMaskIntoConstraints = false
        hairline.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor).isActive = true
        hairline.heightAnchor.constraint(equalToConstant: 0.3).isActive = true
        hairline.leftAnchor.constraint(equalTo: controller.view.leftAnchor).isActive = true
        hairline.topAnchor.constraint(equalTo: drawerLabel.bottomAnchor,constant: 15).isActive = true
        hairline.backgroundColor = UIColor(red: 60/255, green: 60/255, blue: 67/255, alpha: 0.3)
    }
    
    func configureTableView() {
        
        tableView.delegate = self
        tableView.dataSource = self
        stackView.addSubview(tableView)
        
        tableView.backgroundColor = .clear
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: drawerLabel.bottomAnchor, constant: 15).isActive            = true
        tableView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor).isActive    = true
        tableView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20).isActive      = true
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        var config = UIListContentConfiguration.cell()
        config.text = devices[indexPath.row].getName()
        
        cell.contentConfiguration = config
        
        cell.backgroundColor = .clear
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(red: 60/255, green: 60/255, blue: 67/255, alpha: 0.3)
        cell.selectedBackgroundView = bgColorView
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        tableView.frame = controller.view.bounds
    }
}
