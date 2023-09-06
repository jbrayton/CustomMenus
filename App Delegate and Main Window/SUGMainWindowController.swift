//
//  SUGMainWindowController.swift
//  CustomMenus
//
//  Created by John Brayton on 8/31/23.
//

import AppKit

class SUGMainWindowController : NSWindowController {
    
    let searchSuggestionGenerator = SUGSuggestionGenerator()
    
    // This is set to true when the user _deletes_ characters from the search string. 
    // The app does not show searches while deleting characters from the search string.
    var skipNextSuggestion = false
    var searchField: NSTextField?

    var suggestionsWindowController: SUGSuggestionListWindowController?

    override func windowDidLoad() {
        let toolbar = NSToolbar(identifier: "SUGMainWindowController.toolbar")
        toolbar.displayMode = .iconOnly
        toolbar.delegate = self
        self.window?.toolbar = toolbar
    }

    // This is the action method for when the user changes the suggestion selection. Note, this
    // action is called continuously as the suggestion selection changes while being tracked
    // and does not denote user committal of the suggestion. For suggestion committal, the text
    // field's action method is used (see above). This method is wired up programatically in
    // the -controlTextDidBeginEditing: method below.

    @IBAction func update(withSelectedSuggestion sender: Any) {
        if let entry = (sender as? SUGSuggestionListWindowController)?.selectedSuggestion() {
            if let fieldEditor = self.window?.fieldEditor(false, for: searchField) {
                updateFieldEditor(fieldEditor, withSuggestion: entry.name)
            }
        }
    }
    
    // This method is invoked when the user presses return (or enter) on the search text field.
    // We don’t want to use the text from the search field as it is just the image filename
    // without a path. Also, it may not be valid. Instead, use this user action to trigger
    // setting the large image view in the main window to the currently suggested URL, if
    // there is one.
    
    @IBAction func takeImage(fromSuggestedURL sender: Any) {
        if !self.skipNextSuggestion {
            if let suggestionsWindowController = self.suggestionsWindowController, self.suggestionsWindowController?.window?.isVisible == true {
                let suggestion = suggestionsWindowController.selectedSuggestion()
                (self.contentViewController as? SUGMainWindowContentViewController)?.setImageUrl(imageUrl: suggestion?.url)
            } else {
                (self.contentViewController as? SUGMainWindowContentViewController)?.setImageUrl(imageUrl: nil)
            }
            self.suggestionsWindowController?.cancelSuggestions()
        } else {
            self.skipNextSuggestion = false
        }
    }
    
    // Update the field editor with a suggested string. The additional suggested characters are auto selected.

    private func updateFieldEditor(_ fieldEditor: NSText?, withSuggestion suggestion: String?) {
        let selection = NSRange(location: fieldEditor?.selectedRange.location ?? 0, length: suggestion?.count ?? 0)
        fieldEditor?.string = suggestion ?? ""
        fieldEditor?.selectedRange = selection
    }
    
    // Determines the current list of suggestions, display the suggestions and update the field editor.

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


