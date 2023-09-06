//
//  SUGMainWindowController+NSToolbarDelegate.swift
//  CustomMenus
//
//  Created by John Brayton on 9/5/23.
//

import AppKit

extension SUGMainWindowController : NSToolbarDelegate {
    
    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [NSToolbarItem.Identifier.flexibleSpace, NSToolbarItem.Identifier.SUG_search]
    }
    
    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarDefaultItemIdentifiers(toolbar)
    }
    
    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == NSToolbarItem.Identifier.SUG_search {
            let searchItem = NSSearchToolbarItem(itemIdentifier: itemIdentifier)
            self.searchField = searchItem.searchField
            searchItem.searchField.sendsWholeSearchString = true
            searchItem.searchField.delegate = self
            searchItem.searchField.target = self
            searchItem.searchField.action = #selector(SUGMainWindowController.takeImage(fromSuggestedURL:))
            return searchItem
        }
        return nil
    }

}

