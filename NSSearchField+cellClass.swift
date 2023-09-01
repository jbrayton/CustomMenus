//
//  NSSearchField+cellClass.swift
//  CustomMenus
//
//  Created by John Brayton on 9/1/23.
//

import AppKit

extension NSSearchField {
    
    static public override var cellClass: AnyClass? {
        get {
            return SUGSearchFieldCell.self
        }
        set {
            
        }
    }

}
