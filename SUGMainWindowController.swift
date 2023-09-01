//
//  SUGMainWindowController.swift
//  CustomMenus
//
//  Created by John Brayton on 8/31/23.
//

import AppKit

class SUGMainWindowController : NSWindowController {
    
    let searchSuggestionGenerator = SUGSuggestionGenerator()
    
    /* Declare the skipNextSuggestion property in an anonymous category since it is a private property. See -controlTextDidChange: and -control:textView:doCommandBySelector: in this file for usage.
     */
    private var skipNextSuggestion = false
    private var searchField: NSTextField?

    private var suggestionsWindowController: SUGSuggestionsWindowController?

    override func windowDidLoad() {
        let toolbar = NSToolbar(identifier: "SUGMainWindowController.toolbar")
        toolbar.displayMode = .iconOnly
        toolbar.delegate = self
        self.window?.toolbar = toolbar
    }

    /* This is the action method for when the user changes the suggestion selection. Note, this action is called continuously as the suggestion selection changes while being tracked and does not denote user committal of the suggestion. For suggestion committal, the text field's action method is used (see above). This method is wired up programatically in the -controlTextDidBeginEditing: method below.
     */
    @IBAction func update(withSelectedSuggestion sender: Any) {
        if let entry = (sender as? SUGSuggestionsWindowController)?.selectedSuggestion() {
            if let fieldEditor = self.window?.fieldEditor(false, for: searchField) {
                updateFieldEditor(fieldEditor, withSuggestion: entry.name)
            }
        }
    }
    
    /* This method is invoked when the user presses return (or enter) on the search text field. We don't want to use the text from the search field as it is just the image filename without a path. Also, it may not be valid. Instead, use this user action to trigger setting the large image view in the main window to the currently suggested URL, if there is one.
     */
    @IBAction func takeImage(fromSuggestedURL sender: Any) {
        if !self.skipNextSuggestion {
            if let suggestionsWindowController = self.suggestionsWindowController, self.suggestionsWindowController?.window?.isVisible == true {
                let suggestion = suggestionsWindowController.selectedSuggestion()
                (self.contentViewController as? SUGMainWindowViewController)?.setImageUrl(imageUrl: suggestion?.url)
            } else {
                (self.contentViewController as? SUGMainWindowViewController)?.setImageUrl(imageUrl: nil)
            }
            self.suggestionsWindowController?.cancelSuggestions()
        } else {
            self.skipNextSuggestion = false
        }
    }
    
    /* Update the field editor with a suggested string. The additional suggested characters are auto selected.
     */
    private func updateFieldEditor(_ fieldEditor: NSText?, withSuggestion suggestion: String?) {
        let selection = NSRange(location: fieldEditor?.selectedRange.location ?? 0, length: suggestion?.count ?? 0)
        fieldEditor?.string = suggestion ?? ""
        fieldEditor?.selectedRange = selection
    }
    
    /* Determines the current list of suggestions, display the suggestions and update the field editor.
     */
    func updateSuggestions(from control: NSControl?) {
        if let fieldEditor = self.window?.fieldEditor(false, for: control) {
            // Only use the text up to the caret position
            let selection: NSRange? = fieldEditor.selectedRange
            let searchString = (selection != nil) ? (fieldEditor.string as NSString?)?.substring(to: selection!.location) : nil
            var suggestions: [SUGSuggestion]? = nil
            if let searchString, !searchString.isEmpty {
                suggestions = self.searchSuggestionGenerator.suggestions(forSearchString: searchString)
            }
            if let suggestions, !suggestions.isEmpty {
                // We have at least 1 suggestion. Update the field editor to the first suggestion and show the suggestions window.
                
                suggestionsWindowController?.setSuggestions(suggestions)
                if !(suggestionsWindowController?.window?.isVisible ?? false) {
                    suggestionsWindowController?.begin(for: (control as? NSTextField))
                }
                if self.searchSuggestionGenerator.automaticallySelectFirstSuggestion {
                    let suggestion = suggestions[0]
                    updateFieldEditor(fieldEditor, withSuggestion: suggestion.name)
                }
            } else {
                // No suggestions. Cancel the suggestion window and set the _suggestedURL to nil.
                suggestionsWindowController?.cancelSuggestions()
            }
        }
    }
    
}

extension SUGMainWindowController : NSSearchFieldDelegate {
    
    /* In interface builder, we set this class object as the delegate for the search text field. When the user starts editing the text field, this method is called. This is an opportune time to display the initial suggestions.
     */
    func controlTextDidBeginEditing(_ notification: Notification) {
        if !skipNextSuggestion {
            // We keep the suggestionsController around, but lazely allocate it the first time it is needed.
            if suggestionsWindowController == nil {
                suggestionsWindowController = SUGSuggestionsWindowController(automaticallySelectFirstSuggestion: self.searchSuggestionGenerator.automaticallySelectFirstSuggestion)
                suggestionsWindowController?.target = self
                suggestionsWindowController?.action = #selector(SUGMainWindowController.update(withSelectedSuggestion:))
            }
            updateSuggestions(from: notification.object as? NSControl)
        }
    }

    /* The field editor's text may have changed for a number of reasons. Generally, we should update the suggestions window with the new suggestions. However, in some cases (the user deletes characters) we cancel the suggestions window.
     */
    func controlTextDidChange(_ notification: Notification) {
        if !skipNextSuggestion {
            updateSuggestions(from: notification.object as? NSControl)
        } else {
            // If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
            suggestionsWindowController?.cancelSuggestions()
            // This suggestion has been skipped, don't skip the next one.
            skipNextSuggestion = false
        }
    }

    /* The field editor has ended editing the text. This is not the same as the action from the NSTextField. In the MainMenu.xib, the search text field is setup to only send its action on return / enter. If the user tabs to or clicks on another control, text editing will end and this method is called. We don't consider this committal of the action. Instead, we realy on the text field's action (see -takeImageFromSuggestedURL: above) to commit the suggestion. However, since the action may not occur, we need to cancel the suggestions window here.
     */
    func controlTextDidEndEditing(_ obj: Notification) {
        /* If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
         */
        if obj.userInfo?["NSTextMovement"] as? Int != 16 {
            suggestionsWindowController?.cancelSuggestions()
        }
    }

    /* As the delegate for the NSTextField, this class is given a chance to respond to the key binding commands interpreted by the input manager when the field editor calls -interpretKeyEvents:. This is where we forward some of the keyboard commands to the suggestion window to facilitate keyboard navigation. Also, this is where we can determine when the user deletes and where we can prevent AppKit's auto completion.
     */
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
        if commandSelector == #selector(NSResponder.deleteForward(_:)) || commandSelector == #selector(NSResponder.deleteBackward(_:)) {
            /* The user is deleting the highlighted portion of the suggestion or more. Return NO so that the field editor performs the deletion. The field editor will then call -controlTextDidChange:. We don't want to provide a new set of suggestions as that will put back the characters the user just deleted. Instead, set skipNextSuggestion to YES which will cause -controlTextDidChange: to cancel the suggestions window. (see -controlTextDidChange: above)
             */
            let insertionRange = textView.selectedRanges[0].rangeValue
            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                skipNextSuggestion = (insertionRange.location != 0 || insertionRange.length > 0)
            } else {
                skipNextSuggestion = (insertionRange.location != textView.string.count || insertionRange.length > 0)
            }
            return false
        }
        if commandSelector == #selector(NSResponder.complete(_:)) {
            // The user has pressed the key combination for auto completion. AppKit has a built in auto completion. By overriding this command we prevent AppKit's auto completion and can respond to the user's intention by showing or cancelling our custom suggestions window.
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

extension NSToolbarItem.Identifier {
    
    static let SUG_search = NSToolbarItem.Identifier("SUG_search")

}

