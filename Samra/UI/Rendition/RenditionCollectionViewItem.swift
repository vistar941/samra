//
//  RenditionCollectionViewItem.swift
//  Samra
//
//  Created by Serena on 18/02/2023.
// 

import Cocoa
import AssetCatalogWrapper

class RenditionCollectionViewItem: NSCollectionViewItem {
    
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("RenditionCollectionViewItem")
    var nameLabel: NSTextField!
    var representationPreview: NSView!
    
    override func loadView() {
        view = NSView()
    }
    
    func configure(rendition: Rendition) {
        resetContent()

        nameLabel = NSTextField(labelWithString: rendition.name)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.maximumNumberOfLines = 0
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byCharWrapping
        
        switch rendition.representation {
        case .color(let cGColor):
            let circleView = NSView()
            circleView.translatesAutoresizingMaskIntoConstraints = false
            
            let layer = CALayer()
            layer.cornerRadius = 20
            layer.cornerCurve = .circular
            layer.backgroundColor = cGColor
            circleView.wantsLayer = false
            circleView.layer = layer
            
            view.addSubview(circleView)
            NSLayoutConstraint.activate([
                circleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                circleView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -10),
                circleView.heightAnchor.constraint(equalToConstant: 40),
                circleView.widthAnchor.constraint(equalToConstant: 40)
            ])
            
            representationPreview = circleView
        case .image(let cGImage):
            let imageView = NSImageView()
            imageView.image = NSImage(cgImage: cGImage, size: cGImage.size)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageView)
            
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.imageAlignment = .alignCenter
            
//            imageView.centerConstraints(to: view)
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -12.34),
            ])
            
            /*
            if #available(macOS 11, *) {
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor),
                    imageView.heightAnchor.constraint(equalTo: view.layoutMarginsGuide.heightAnchor)
                ])
            } else {*/
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -20),
                imageView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -34)
            ])
            /*}*/
            
            representationPreview = imageView

        case .rawData(let data):
            var visibleString = "No Preview Available"
            if let string = String(data:data, encoding:.utf8) {
                visibleString = string.count > 500 ? String(string.prefix(500)) : string
            }
            let textField = NSTextField(wrappingLabelWithString:visibleString)
            textField.isBordered = true
            textField.isEditable = false
            textField.isSelectable = false
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.maximumNumberOfLines = 5
            view.addSubview(textField)
            representationPreview = textField
            NSLayoutConstraint.activate([
                textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                textField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -12.34),
                textField.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -20),
                textField.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -34)
            ])

        case nil:
            if let gradient = rendition.namedGradient {
                let gradientView = NSView()
                gradientView.translatesAutoresizingMaskIntoConstraints = false
                gradientView.wantsLayer = true

                let gradientLayer = CAGradientLayer()
                gradientLayer.colors = gradient.stops.map(\.color)
                gradientLayer.locations = gradient.stops.map { NSNumber(value: Double($0.location)) }
                gradientLayer.startPoint = gradient.startPoint
                gradientLayer.endPoint = gradient.endPoint
                gradientView.layer = gradientLayer

                view.addSubview(gradientView)
                NSLayoutConstraint.activate([
                    gradientView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    gradientView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -12.34),
                    gradientView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -20),
                    gradientView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -34)
                ])

                representationPreview = gradientView
            } else if let iconStack = rendition.iconStack {
                let textField = NSTextField(labelWithString: "Icon Stack\n\(Int(iconStack.size.width)) x \(Int(iconStack.size.height))\n\(iconStack.layers.count) layers")
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.alignment = .center
                textField.maximumNumberOfLines = 3
                textField.lineBreakMode = .byTruncatingTail
                view.addSubview(textField)
                representationPreview = textField
                NSLayoutConstraint.activate([
                    textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    textField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -12.34),
                    textField.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -20),
                    textField.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -34)
                ])
            } else {
                representationPreview = .init()
            }
        }
        
        view.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
        
        let layer = CALayer()
        layer.borderWidth = 1.87
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        layer.borderColor = NSColor.systemGray.cgColor
        layer.backgroundColor = NSColor.systemGray.withAlphaComponent(0.25).cgColor
        view.wantsLayer = true
        view.layer = layer
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        resetContent()
    }

    private func resetContent() {
        view.subviews.forEach { $0.removeFromSuperview() }
        view.removeConstraints(view.constraints)
        representationPreview = nil
        nameLabel = nil
    }
}
