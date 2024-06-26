//
//  SUGMainWindowController+NSSearchFieldDelegate.swift
//  CustomMenus
//
//  Created by John Brayton on 9/5/23.
//

import AppKit

extension SUGMainWindowController : NSSearchFieldDelegate {
    
    // When the user starts editing the text field, this method is called. This is an opportune time to
    // display the initial suggestions.

    func controlTextDidBeginEditing(_ notification: Notification) {
        // We keep the suggestionsController around, but lazely allocate it the first time it is needed.
        if suggestionsWindowController == nil {
            suggestionsWindowController = SUGSuggestionListWindowController(automaticallySelectFirstSuggestion: self.searchSuggestionGenerator.automaticallySelectFirstSuggestion)
            suggestionsWindowController?.target = self
            suggestionsWindowController?.action = #selector(SUGMainWindowController.update(withSelectedSuggestion:))
        }
        updateSuggestions(from: notification.object as? NSControl)
    }

    // The field editor's text may have changed for a number of reasons. Generally, we should update the
    // suggestions window with the new suggestions.

    func controlTextDidChange(_ notification: Notification) {
        updateSuggestions(from: notification.object as? NSControl)
    }

    // The field editor has ended editing the text. This is not the same as the action from the NSTextField.
    // In the MainMenu.xib, the search text field is setup to only send its action on return / enter. If
    // the user tabs to or clicks on another control, text editing will end and this method is called. We
    // don't consider this committal of the action. Instead, we realy on the text field's action (see
    // -takeImageFromSuggestedURL: above) to commit the suggestion. However, since the action may not
    // occur, we need to cancel the suggestions window here.

    func controlTextDidEndEditing(_ obj: Notification) {
        /* If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
         */
        if obj.userInfo?["NSTextMovement"] as? Int != 16 {
            suggestionsWindowController?.cancelSuggestions()
        }
    }

    // As the delegate for the NSTextField, this class is given a chance to respond to the key binding commands
    // interpreted by the input manager when the field editor calls -interpretKeyEvents:. This is where we
    // forward some of the keyboard commands to the suggestion window to facilitate keyboard navigation.
    // Also, this is where we can determine when the user deletes and where we can prevent AppKit's auto completion.

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            // Move up in the suggested selections list
            suggestionsWindowController?.moveUp(textView)
            return true
        }
        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            // Move down in the suggested selections list
            suggestionsWindowController?.moveDown(textView)
            return true
        }
        
        // This is "autocomplete" functionality, invoked when the user presses option-escaped.
        // By overriding this command we prevent AppKit's auto completion and can respond to
        // the user's intention by showing or cancelling our custom suggestions window.
        if commandSelector == #selector(NSResponder.complete(_:)) {
            if suggestionsWindowController != nil && suggestionsWindowController!.window != nil && suggestionsWindowController!.window!.isVisible {
                suggestionsWindowController?.cancelSuggestions()
            } else {
                updateSuggestions(from: control)
            }
            return true
        }
        // This is a command that we don't specifically handle, let the field editor do the appropriate thing.
        return false
    }
    
}

