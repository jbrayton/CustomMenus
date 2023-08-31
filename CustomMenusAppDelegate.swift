//  Converted to Swift 4 by Swiftify v4.1.6654 - https://objectivec2swift.com/
/*
 File: CustomMenusAppDelegate.m
 Abstract: This class is responsible for two major activities. It sets up the images in the popup menu (via a custom view) and responds to the menu actions. Also, it supplies the suggestions for the search text field and responds to suggestion selection changes and text field editing.
 Version: 1.4
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 */
import Cocoa
import UniformTypeIdentifiers

let kDesktopPicturesPath = "/System/Library/Desktop Pictures"

@NSApplicationMain
class CustomMenusAppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var searchField: NSTextField!
    
    private var suggestionsController: SUGSuggestionsWindowController?
    private var baseURL: URL?
    private var imageURLS = [URL]()
    private var suggestedURL: URL?
    
    /* Declare the skipNextSuggestion property in an anonymous category since it is a private property. See -controlTextDidChange: and -control:textView:doCommandBySelector: in this file for usage.
     */
    private var skipNextSuggestion = false
    
    /* The popup menu allows selection from image files contained in the directory set here. The suggestion list recursively searches all the sub directories for matching image names starting at the directory set here.
     */
    func setBaseURL(_ url: URL?) {
        if !(url == baseURL) {
            baseURL = url
            imageURLS = []
        }
    }
    
    /* Start off by pointing to Desktop Pictures.
     */
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setBaseURL(URL(fileURLWithPath: kDesktopPicturesPath))
    }
    
    // MARK: -
    // MARK: Suggestions
    
    /* This method is invoked when the user presses return (or enter) on the search text field. We don't want to use the text from the search field as it is just the image filename without a path. Also, it may not be valid. Instead, use this user action to trigger setting the large image view in the main window to the currently suggested URL, if there is one.
     */
    @IBAction func takeImage(fromSuggestedURL sender: Any) {
        var image: NSImage? = nil
        if suggestedURL != nil {
            image = NSImage(contentsOf: suggestedURL!)
        }
        imageView.image = image
    }
    
    /* This is the action method for when the user changes the suggestion selection. Note, this action is called continuously as the suggestion selection changes while being tracked and does not denote user committal of the suggestion. For suggestion committal, the text field's action method is used (see above). This method is wired up programatically in the -controlTextDidBeginEditing: method below.
     */
    @IBAction func update(withSelectedSuggestion sender: Any) {
        if let entry = (sender as? SUGSuggestionsWindowController)?.selectedSuggestion() {
            let fieldEditor: NSText? = window.fieldEditor(false, for: searchField)
            if fieldEditor != nil {
                updateFieldEditor(fieldEditor, withSuggestion: entry.name)
                suggestedURL = entry.url
            }
        }
    }
    
    /* Recursively search through all the image files starting at the _baseURL for image file names that begin with the supplied string. It returns an array of NSDictionaries. Each dictionary contains a label, detailed label and an url with keys that match the binding used by each custom suggestion view defined in suggestionprototype.xib.
     */
    func suggestions(forText text: String?) -> [SUGSuggestion]? {
        // We don't want to hit the disk every time we need to re-calculate the the suggestion list. So we cache the result from disk. If we really wanted to be fancy, we could listen for changes to the file system at the _baseURL to know when the cache is out of date.
        if imageURLS.count == 0 {
            imageURLS = [URL]()
            imageURLS.reserveCapacity(1)
            let keyProperties: [URLResourceKey] = [.isDirectoryKey, .typeIdentifierKey, .localizedNameKey]
            let dirItr: FileManager.DirectoryEnumerator? = FileManager.default.enumerator(at: baseURL!, includingPropertiesForKeys: keyProperties, options: [.skipsPackageDescendants, .skipsHiddenFiles], errorHandler: nil)
            while let file = dirItr?.nextObject() as? URL {
                var isDirectory: NSNumber? = nil
                try? isDirectory = ((file.resourceValues(forKeys: [.isDirectoryKey]).allValues.first?.value ?? "") as? NSNumber)
                if isDirectory != nil && isDirectory! == 0 {
                    var fileType: String? = nil
                    try? fileType = ((file.resourceValues(forKeys: [.typeIdentifierKey]).allValues.first?.value ?? "") as? String)
                    if let fileType, UTType(fileType)?.conforms(to: UTType.image) == true {
                        imageURLS.append(file)
                    }
                }
            }
        }
        // Search the known image URLs array for matches.
        var suggestions = [SUGSuggestion]()
        suggestions.reserveCapacity(1)
        for hashableFile: AnyHashable in imageURLS {
            guard let file = hashableFile as? URL else {
                continue
            }
            var localizedName: String?
            try? localizedName = ((file.resourceValues(forKeys: [.localizedNameKey]).allValues.first?.value ?? "") as? String)
            if text != nil && text != "" && localizedName != nil
                && (localizedName!.hasPrefix(text ?? "")
                    || localizedName!.uppercased().hasPrefix(text?.uppercased() ?? "")) {
                let entry = SUGSuggestion(name: localizedName ?? "", url: file)
                suggestions.append(entry)
            }
        }
        return suggestions
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
        let fieldEditor: NSText? = window.fieldEditor(false, for: control)
        if fieldEditor != nil {
            // Only use the text up to the caret position
            let selection: NSRange? = fieldEditor?.selectedRange
            let text = (selection != nil) ? (fieldEditor?.string as NSString?)?.substring(to: selection!.location) : nil
            let suggestions = self.suggestions(forText: text)
            if suggestions != nil && suggestions!.count > 0 {
                // We have at least 1 suggestion. Update the field editor to the first suggestion and show the suggestions window.
                let suggestion = suggestions![0]
                suggestedURL = suggestion.url
                updateFieldEditor(fieldEditor, withSuggestion: suggestion.name)
                suggestionsController?.setSuggestions(suggestions!)
                if !(suggestionsController?.window?.isVisible ?? false) {
                    suggestionsController?.begin(for: (control as? NSTextField))
                }
            } else {
                // No suggestions. Cancel the suggestion window and set the _suggestedURL to nil.
                suggestedURL = nil
                suggestionsController?.cancelSuggestions()
            }
        }
    }
    
}

extension CustomMenusAppDelegate : NSTextFieldDelegate {
    
    /* In interface builder, we set this class object as the delegate for the search text field. When the user starts editing the text field, this method is called. This is an opportune time to display the initial suggestions.
     */
    func controlTextDidBeginEditing(_ notification: Notification) {
        if !skipNextSuggestion {
            // We keep the suggestionsController around, but lazely allocate it the first time it is needed.
            if suggestionsController == nil {
                suggestionsController = SUGSuggestionsWindowController()
                suggestionsController?.target = self
                suggestionsController?.action = #selector(CustomMenusAppDelegate.update(withSelectedSuggestion:))
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
            // If we are skipping this suggestion, the set the _suggestedURL to nil and cancel the suggestions window.
            suggestedURL = nil
            // If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
            suggestionsController?.cancelSuggestions()
            // This suggestion has been skipped, don't skip the next one.
            skipNextSuggestion = false
        }
    }

    /* The field editor has ended editing the text. This is not the same as the action from the NSTextField. In the MainMenu.xib, the search text field is setup to only send its action on return / enter. If the user tabs to or clicks on another control, text editing will end and this method is called. We don't consider this committal of the action. Instead, we realy on the text field's action (see -takeImageFromSuggestedURL: above) to commit the suggestion. However, since the action may not occur, we need to cancel the suggestions window here.
     */
    func controlTextDidEndEditing(_ obj: Notification) {
        /* If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
         */
        suggestionsController?.cancelSuggestions()
    }

    /* As the delegate for the NSTextField, this class is given a chance to respond to the key binding commands interpreted by the input manager when the field editor calls -interpretKeyEvents:. This is where we forward some of the keyboard commands to the suggestion window to facilitate keyboard navigation. Also, this is where we can determine when the user deletes and where we can prevent AppKit's auto completion.
     */
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            // Move up in the suggested selections list
            suggestionsController?.moveUp(textView)
            return true
        }
        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            // Move down in the suggested selections list
            suggestionsController?.moveDown(textView)
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
            if suggestionsController != nil && suggestionsController!.window != nil && suggestionsController!.window!.isVisible {
                suggestionsController?.cancelSuggestions()
            } else {
                updateSuggestions(from: control)
            }
            return true
        }
        // This is a command that we don't specifically handle, let the field editor do the appropriate thing.
        return false
    }
    
}
