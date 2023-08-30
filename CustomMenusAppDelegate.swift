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

let kDesktopPicturesPath = "/System/Library/Desktop Pictures"

@NSApplicationMain
class CustomMenusAppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!
    @IBOutlet var imagePicker: NSPopUpButton!
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var searchField: NSTextField!
    
    private var suggestionsController: SuggestionsWindowController?
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
        setupImagesMenu()
    }
    
    // MARK: -
    // MARK: Custom Menu Item View
    /* Set up the custom views in the popup button menu. This method should be called whenever the baseURL changes.
     In MainMenu.xib, the menu for the popup button is defined. There is one menu item with a tag of 1000 that is used as the prototype for the custom menu items. Each ImagePickerMenuItemView can contain 4 images. So we keep duplicating the prototype menu item until we have enough menu items for each image found in the directory specified by _baseURL. Duplicating the prototype menu allows us to reuse the target action wiring done in IB.
     We need to rebuild this menu each time the _baseURL changes. To accomplish this, we set the tag of each dupicated prototype to 1001. This way we can easily find and remove them to start over.
     */
    private func setupImagesMenu() {
        let menu: NSMenu? = imagePicker.menu
        // Look for existing ImagePickerMenuItemView menu items that are no longer valid and remove them.
        while let menuItem = menu?.item(withTag: 1001) {
            menu?.removeItem(menuItem)
        }
        // Find the prototype menu item. We want to keep it as the prototype for future rebuilds so we don't want to actually use it. Instead, make it hidden so the user never sees it.
        let masterImagesMenuItem: NSMenuItem? = imagePicker.menu?.item(withTag: 1000)
        masterImagesMenuItem?.isHidden = true
        // Find all the entires in the _baseURL directory.
        let fileURLS = try? FileManager.default.contentsOfDirectory(at: baseURL!, includingPropertiesForKeys: [.isDirectoryKey, .typeIdentifierKey], options: [])
        // Only 4 images per menu item are allowed by the view. Use this index to keep track of that
        var idx: Int = 0
        // ImagePickerMenuItemView uses an array of URLS. This is that array.
        var imageUrlArray = [URL]()
        // Loop over each entry looking for image files
        for file: URL in (fileURLS ?? []) {
            var isDirectory: NSNumber? = nil
            // directories are obviously not images.
            try? isDirectory = ((file.resourceValues(forKeys: [.isDirectoryKey]).allValues.first?.value ?? "") as? NSNumber)
            if isDirectory != nil && isDirectory! == 0 {
                var fileType: String? = nil
                // Is the file an image file? Use UTTypes to find out.
                try? fileType = ((file.resourceValues(forKeys: [.typeIdentifierKey]).allValues.first?.value ?? "") as? String)
                if fileType != nil && UTTypeConformsTo(fileType! as NSString, kUTTypeImage) {
                    if idx == 0 {
                        // Starting a new set of 4 images. Setup a new menu item and URL array
                        imageUrlArray = [URL]()
                        imageUrlArray.reserveCapacity(4)
                        // Duplicate the prototype menu item
                        let imagesMenuItem: NSMenuItem? = masterImagesMenuItem
                        // Load the custom view from its nib
                        let viewController = NSViewController(nibName: NSNib.Name("imagePickerMenuItem"), bundle: nil)
                        /* Setup a mutable dictionary as the view controller's represeted object so we can bind the custom view to it.
                         */
                        var pickerMenuData = [AnyHashable: Any](minimumCapacity: 2)
                        pickerMenuData["imageUrls"] = imageUrlArray
                        pickerMenuData["selectedUrl"] = nil
                        // need a blank entry to start with
                        viewController.representedObject = pickerMenuData
                        // Bind the custom view to the image URLs array.
                        viewController.view.bind(NSBindingName("imageUrls"), to: viewController, withKeyPath: "representedObject.imageUrls", options: nil)
                        /* selectedImageUrl from the view is read only, so bind the data dictinary to the selectedImageUrl instead of the other way around.
                         */
                        (viewController.representedObject as AnyObject).bind(NSBindingName("selectedUrl"), to: viewController.view, withKeyPath: "selectedImageUrl", options: nil)
                        // transform the duplicated menu item prototype to a proper custom instance
                        imagesMenuItem?.representedObject = viewController
                        imagesMenuItem?.view = viewController.view
                        imagesMenuItem?.tag = 1001
                        // set the tag to 1001 so we can remove this instance on rebuild (see above)
                        imagesMenuItem?.isHidden = false
                        // Insert the custom menu item
                        if let anItem = imagesMenuItem {
                            menu?.insertItem(anItem, at: (menu?.numberOfItems)! - 2)
                        }
                        // Cleanup memory
                    }
                    /* Add the image URL to the mutable array stored in the view controller's representedObject dictionary. Since imageUrlArray is mutable, we can just modify it in place.
                     */
                    imageUrlArray.append(file)
                    // Update our index. We can only put 4 images per custom menu item. Reset after every fourth image file.
                    idx += 1
                    if idx > 3 {
                        idx = 0
                    }
                    // with a 0 based index, when idx > 3 we'll have completed 4 passes.
                }
            }
        }
    }
    
    /* This is the action wired to the prototype custom menu item in IB. In -_setupImagesMenu above, we bound the selected URL to a mutable dictionary that was set as the viewController's representedObject. The viewController was set as the menu item's represented object and the sender is the menu item.
     */
    @IBAction func takeImage(from sender: Any) {
        let viewController = (sender as AnyObject).representedObject as? NSViewController
        let menuItemData = viewController?.representedObject as? [AnyHashable: Any]
        let imageURL = menuItemData?["selectedUrl"]
        if imageURL != nil {
            var image: NSImage? = nil
            if let anURL = imageURL as? URL {
                image = NSImage(contentsOf: anURL)
            }
            imageView.image = image
        } else {
            imageView.image = nil
        }
    }
    
    /* Action method for the "Select Image Folder..." menu item on the popup button. Show Open panel to allow use to select the _baseURL to search for images.
     */
    @IBAction func selectImageFolder(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.directoryURL = URL(fileURLWithPath: kDesktopPicturesPath)
        openPanel.beginSheetModal(for: window, completionHandler: {(_ result: NSApplication.ModalResponse) -> Void in
            if result.rawValue == NSFileHandlingPanelOKButton {
                self.setBaseURL(openPanel.url)
                self.setupImagesMenu()
            }
        })
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
        let entry = (sender as? SuggestionsWindowController)?.selectedSuggestion()
        if entry != nil && !entry!.isEmpty {
            let fieldEditor: NSText? = window.fieldEditor(false, for: searchField)
            if fieldEditor != nil {
                updateFieldEditor(fieldEditor, withSuggestion: entry![kSuggestionLabel] as? String)
                suggestedURL = entry![kSuggestionImageURL] as? URL
            }
        }
    }
    
    /* Recursively search through all the image files starting at the _baseURL for image file names that begin with the supplied string. It returns an array of NSDictionaries. Each dictionary contains a label, detailed label and an url with keys that match the binding used by each custom suggestion view defined in suggestionprototype.xib.
     */
    func suggestions(forText text: String?) -> [[String: Any]]? {
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
                    if fileType != nil && UTTypeConformsTo(fileType! as NSString, kUTTypeImage) {
                        imageURLS.append(file)
                    }
                }
            }
        }
        // Search the known image URLs array for matches.
        var suggestions = [[String: Any]]()
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
                let entry: [String: Any] = [
                    kSuggestionLabel: localizedName!,
                    kSuggestionDetailedLabel: file.path,
                    kSuggestionImageURL: file
                ]
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
                suggestedURL = suggestion[kSuggestionImageURL] as? URL
                updateFieldEditor(fieldEditor, withSuggestion: suggestion[kSuggestionLabel] as? String)
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
                suggestionsController = SuggestionsWindowController()
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
