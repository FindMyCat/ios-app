//
//  NavigationController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/12/23.
//

import Foundation
import UIKit

class ScanDevicesNavigationController: UINavigationController {
    override func viewDidLoad() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        super.viewDidLoad()

        let scanDevicesViewController = ScanDevicesViewController()

        // Set the view controllers in the navigation stack
        setViewControllers([scanDevicesViewController], animated: false)
    }
}
