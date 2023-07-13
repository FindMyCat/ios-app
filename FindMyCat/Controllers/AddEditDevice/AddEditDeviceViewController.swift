//
//  AddEditDeviceController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/12/23.
//

import Foundation
import UIKit

class AddEditDeviceViewController: UIViewController {

    let sheetView = DismissableSheet()

    let emojiView = AvatarEmojiView()

    override func viewDidLoad() {

        navigationItem.setHidesBackButton(true, animated: false)
        view.backgroundColor = .clear
        view.addSubview(sheetView)

        sheetView.showInView(view, height: 500)
    }
}
