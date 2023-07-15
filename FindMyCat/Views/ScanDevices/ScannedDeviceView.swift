//
//  ScannedDeviceView.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/14/23.
//

import UIKit

class ScannedDeviceView: UIView {

    let indexLabel: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 40)
        let image = UIImage(systemName: "plus.viewfinder", withConfiguration: configuration)
        let view = UIImageView(image: image)
        return view
    }()

    let numberLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemGray
        return label
    }()

    override func layoutSubviews() {
        super.layoutSubviews()

        // Set the view's background color and make it circular
        layer.borderWidth = 4
        layer.borderColor = UIColor.systemGray2.cgColor
        backgroundColor = UIColor.init(white: 0.96, alpha: 1)
        tintColor = backgroundColor
        layer.cornerRadius = bounds.width / 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 40

        layer.masksToBounds = false

        // Add the labels to the view and set their frames
        addSubview(indexLabel)
        addSubview(numberLabel)

        indexLabel.translatesAutoresizingMaskIntoConstraints = false
        indexLabel.tintColor = .black

        NSLayoutConstraint.activate([
            indexLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            indexLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10)
        ])
        numberLabel.frame = CGRect(x: 0, y: bounds.height / 2, width: bounds.width, height: bounds.height / 2)
    }
}
