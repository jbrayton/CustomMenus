//
//  SUGIndividualSuggestionViewController.swift
//  CustomMenus
//
//  Created by John Brayton on 8/31/23.
//

import AppKit

class SUGSuggestionViewController : NSViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = SUGSuggestionView()
    }
    
    override var representedObject: Any? {
        didSet {
            if let representedObject = self.representedObject as? SUGSuggestion, let view = self.view as? SUGSuggestionView {
                view.label.stringValue = representedObject.name
                view.imageView.image = NSImage(named: representedObject.imageName)
            }
        }
    }
    
}
