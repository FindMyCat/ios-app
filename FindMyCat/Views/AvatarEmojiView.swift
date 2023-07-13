//
//  AvatarEmojiView.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/12/23.
//

import UIKit

class AvatarEmojiView: UIView {

    // required for iOS 13
    override var textInputContextIdentifier: String? { "" } // return non-nil to show the Emoji keyboard ¯\_(ツ)_/¯

    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return nil
    }
}
