//
//  AvatarEmojiView.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/12/23.
//

import UIKit

class EmojiTextField: UITextField {

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

class AvatarEmojiView: UIView, UITextFieldDelegate {

    var textField: EmojiTextField!
    override init(frame: CGRect) {
        super.init(frame: frame)

        textField =  EmojiTextField(frame: frame)
        textField.text = "🤪"
        textField.font = UIFont.systemFont(ofSize: 70)
        textField.layer.cornerRadius = textField.frame.width / 2
        textField.layer.borderWidth = 2
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.backgroundColor = UIColor.init(white: 0.96, alpha: 1)
        textField.tintColor = textField.backgroundColor
        textField.clipsToBounds = true
        textField.autocorrectionType = .no
        textField.keyboardType = .default
        textField.returnKeyType = .done

        textField.textAlignment = .center

        textField.delegate = self

        textField.addTarget(self, action: #selector(clearTextFieldAndReplaceWithLastTyped), for: .editingChanged)

        addSubview(textField)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Action method to limit input to one character
    @objc private func clearTextFieldAndReplaceWithLastTyped(_ textField: UITextField) {
        if let text = textField.text {
            textField.text = String(text.suffix(1))
        }
    }
}
