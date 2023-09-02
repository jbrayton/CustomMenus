//
//  NSSearchField+cellClass.swift
//  CustomMenus
//
//  Created by John Brayton on 9/1/23.
//

import AppKit

extension NSSearchField {
    
    // I worry that this has the potential to conflict with an NSSearchField.cellClass method
    // provided by the system.
    static public override var cellClass: AnyClass? {
        get {
            return SUGSearchFieldCell.self
        }
        set {
            
        }
    }

}
