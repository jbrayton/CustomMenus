//
//  SUGIndividualSuggestionView.swift
//  CustomMenus
//
//  Created by John Brayton on 8/31/23.
//

import AppKit

class SUGIndividualSuggestionView : NSView {
    
    let highlightSideMargin: CGFloat = 7.0
    let labelSideMargin: CGFloat = 7.0

    var backgroundView: NSVisualEffectView!
    var label: NSTextField!

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

        self.label = NSTextField(labelWithString: "")
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundView.addSubview(self.label)
        self.backgroundView.addConstraints([
            self.label.leadingAnchor.constraint(equalTo: self.backgroundView.leadingAnchor, constant: self.labelSideMargin),
            self.label.trailingAnchor.constraint(equalTo: self.backgroundView.trailingAnchor, constant: 0.0 - self.labelSideMargin),
            self.label.centerYAnchor.constraint(equalTo: self.backgroundView.centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showHighlighted( highlighted: Bool ) {
        self.backgroundView.material = highlighted ? .selection : .menu
        self.backgroundView.isEmphasized = highlighted
        self.backgroundView.state = highlighted ? .active : .inactive
        self.label.cell?.backgroundStyle = highlighted ? .emphasized : .normal
    }
    
}
