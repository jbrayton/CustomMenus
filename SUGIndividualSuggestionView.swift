//
//  SUGIndividualSuggestionView.swift
//  CustomMenus
//
//  Created by John Brayton on 8/31/23.
//

import AppKit

class SUGIndividualSuggestionView : NSView {
    
    let highlightSideMargin: CGFloat = 7.0
    let sideMargin: CGFloat = 6.0
    let imageSize: CGFloat = 13.0
    let spaceBetweenLabelAndImage: CGFloat = 6.0

    var imageView: NSImageView!
    var backgroundView: NSVisualEffectView!
    var label: NSTextField!

    var highlighted: Bool = false {
        didSet {
            self.backgroundView.material = self.highlighted ? .selection : .menu
            self.backgroundView.isEmphasized = self.highlighted
            self.backgroundView.state = self.highlighted ? .active : .inactive
            self.label.cell?.backgroundStyle = self.highlighted ? .emphasized : .normal
            self.imageView.cell?.backgroundStyle = self.highlighted ? .emphasized : .normal
        }
    }
    
    init() {
        super.init(frame: .zero)

        self.backgroundView = NSVisualEffectView()
        self.backgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundView.maskImage = NSImage.SUG_mask(withCornerRadius: 4.0)
        self.addSubview(self.backgroundView)
        self.addConstraints([
            self.backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: self.highlightSideMargin),
            self.backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0.0 - self.highlightSideMargin),
            self.backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            self.backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        
        self.imageView = NSImageView()
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundView.addSubview(self.imageView)
        self.backgroundView.addConstraints([
            self.imageView.leadingAnchor.constraint(equalTo: self.backgroundView.leadingAnchor, constant: self.sideMargin),
            self.imageView.centerYAnchor.constraint(equalTo: self.backgroundView.centerYAnchor),
            self.imageView.widthAnchor.constraint(equalToConstant: self.imageSize),
            self.imageView.heightAnchor.constraint(equalToConstant: self.imageSize),
        ])
        self.imageView.contentTintColor = NSColor.labelColor

        self.label = NSTextField(labelWithString: "")
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundView.addSubview(self.label)
        self.backgroundView.addConstraints([
            self.label.leadingAnchor.constraint(equalTo: self.imageView.trailingAnchor, constant: self.spaceBetweenLabelAndImage),
            self.label.trailingAnchor.constraint(equalTo: self.backgroundView.trailingAnchor, constant: 0.0 - self.sideMargin),
            self.label.centerYAnchor.constraint(equalTo: self.backgroundView.centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func accessibilityChildren() -> [Any]? {
        return [Any]()
    }
    
    override func accessibilityLabel() -> String? {
        return self.label.stringValue
    }
    
}
