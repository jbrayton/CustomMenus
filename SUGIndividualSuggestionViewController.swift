//
//  SUGIndividualSuggestionViewController.swift
//  CustomMenus
//
//  Created by John Brayton on 8/31/23.
//

import AppKit

class SUGIndividualSuggestionViewController : NSViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = SUGIndividualSuggestionView()
    }
    
    override var representedObject: Any? {
        didSet {
            if let representedObject = self.representedObject as? [String:Any] {
                (self.view as! SUGIndividualSuggestionView).label.stringValue = representedObject[kSuggestionLabel] as! String
            }
        }
    }
    
}
