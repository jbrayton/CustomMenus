//  Converted to Swift 4 by Swiftify v4.1.6654 - https://objectivec2swift.com/
/*
 File: SuggestionsWindowController.m
 Abstract: The controller for the suggestions popup window. This class handles creating, displaying, and event tracking of the suggestion popup window.
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

let kTrackerKey = "whichImageView"
let kThumbnailWidth: CGFloat = 24.0

let kSuggestionImage = "image"
let kSuggestionImageURL = "imageUrl"
let kSuggestionLabel = "label"
let kSuggestionDetailedLabel = "detailedLabel"

class SUGSuggestionsWindowController: NSWindowController {
    var action: Selector?
    var target: Any?
    private var parentTextField: NSTextField?
    private var suggestions = [[String: Any]]()
    private var viewControllers = [NSViewController]()
    private var trackingAreas = [AnyHashable]()
    private var needsLayoutUpdate = false
    private var localMouseDownEventMonitor: Any?
    private var lostFocusObserver: Any?

    init() {
        let contentRec = NSRect(x: 0, y: 0, width: 20, height: 20)
        let window = SUGSuggestionsWindow(contentRect: contentRec, defer: true)
        super.init(window: window)

        // SuggestionsWindow is a transparent window, create RoundedCornersView and set it as the content view to draw a menu like window.
        let contentView = SUGSuggestionsContentView(frame: contentRec)
        window.contentView = contentView
        contentView.autoresizesSubviews = false
        needsLayoutUpdate = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /* Custom selectedView property setter so that we can set the highlighted property of the old and new selected views.
     */
    private var selectedView: NSView? {
        didSet {
            
            if let oldValue = oldValue as? NSVisualEffectView {
                oldValue.material = .menu
                oldValue.isEmphasized = false
                oldValue.state = .inactive
                self.updateTextFields(row: oldValue, selected: false)
            }
            if let newValue = self.selectedView as? NSVisualEffectView {
                newValue.material = .selection
                newValue.isEmphasized = true
                newValue.state = .active
                self.updateTextFields(row: newValue, selected: true)
            }
        }
    }
    
    func updateTextFields( row: NSVisualEffectView, selected: Bool ) {
        for subview in row.subviews {
            if let textField = subview as? NSTextField {
                textField.cell?.backgroundStyle = selected ? .emphasized : .normal
            }
        }
    }

    /* Set selected view and send action
     */
    func userSetSelectedView(_ view: NSView?) {
        selectedView = view
        NSApp.sendAction(action!, to: target, from: self)
    }

    /* Position and lay out the suggestions window, set up auto cancelling tracking, and wires up the logical relationship for accessibility.
     */
    func begin(for parentTextField: NSTextField?) {
        let suggestionWindow: NSWindow? = window
        let parentWindow: NSWindow? = parentTextField?.window
        let parentFrame: NSRect? = parentTextField?.frame
        var frame: NSRect? = suggestionWindow?.frame
        frame?.size.width = (parentFrame?.size.width)!
        // Place the suggestion window just underneath the text field and make it the same width as th text field.
        var location = parentTextField?.superview?.convert(parentFrame?.origin ?? NSPoint.zero, to: nil)
        location = parentWindow?.convertToScreen(NSRect(x: location!.x, y: location!.y, width: 0, height: 0)).origin
        location?.y -= 2.0
        // nudge the suggestion window down so it doesn't overlapp the parent view
        suggestionWindow?.setFrame(frame ?? NSRect.zero, display: false)
        suggestionWindow?.setFrameTopLeftPoint(location ?? NSPoint.zero)
        layoutSuggestions()
        // The height of the window will be adjusted in -layoutSuggestions.
        // add the suggestion window as a child window so that it plays nice with Expose
        if let aWindow = suggestionWindow {
            parentWindow?.addChildWindow(aWindow, ordered: .above)
        }
        // keep track of the parent text field in case we need to commit or abort editing.
        self.parentTextField = parentTextField
        // The window must know its accessibility parent, the control must know the window one of its accessibility children
        // Note that views (controls especially) are often ignored, so we want the unignored descendant - usually a cell
        // Finally, post that we have created the unignored decendant of the suggestions window
        let unignoredAccessibilityDescendant = NSAccessibility.unignoredDescendant(of: parentTextField!)
        (suggestionWindow as? SUGSuggestionsWindow)?.parentElement = unignoredAccessibilityDescendant
        (unignoredAccessibilityDescendant as? SUGSearchFieldCell)?.suggestionsWindow = suggestionWindow
        if let win = suggestionWindow, let winD = NSAccessibility.unignoredDescendant(of: win) {
            NSAccessibility.post(element: winD, notification: .created)
        }
        // setup auto cancellation if the user clicks outside the suggestion window and parent text field. Note: this is a local event monitor and will only catch clicks in windows that belong to this application. We use another technique below to catch clicks in other application windows.
        localMouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [NSEvent.EventTypeMask.leftMouseDown, NSEvent.EventTypeMask.rightMouseDown, NSEvent.EventTypeMask.otherMouseDown], handler: {(_ event: NSEvent) -> NSEvent? in
            // If the mouse event is in the suggestion window, then there is nothing to do.
            var event: NSEvent! = event
            if event.window != suggestionWindow {
                if event.window == parentWindow {
                    /* Clicks in the parent window should either be in the parent text field or dismiss the suggestions window. We want clicks to occur in the parent text field so that the user can move the caret or select the search text.
                     
                     Use hit testing to determine if the click is in the parent text field. Note: when editing an NSTextField, there is a field editor that covers the text field that is performing the actual editing. Therefore, we need to check for the field editor when doing hit testing.
                     */
                    let contentView: NSView? = parentWindow?.contentView
                    let locationTest: NSPoint? = contentView?.convert(event.locationInWindow, from: nil)
                    let hitView: NSView? = contentView?.hitTest(locationTest ?? NSPoint.zero)
                    let fieldEditor: NSText? = parentTextField?.currentEditor()
                    if hitView != parentTextField && ((fieldEditor != nil) && hitView != fieldEditor) {
                        // Since the click is not in the parent text field, return nil, so the parent window does not try to process it, and cancel the suggestion window.
                        event = nil
                        self.cancelSuggestions()
                    }
                } else {
                    // Not in the suggestion window, and not in the parent window. This must be another window or palette for this application.
                    self.cancelSuggestions()
                }
            }
            return event
        })
        // as per the documentation, do not retain event monitors.
        // We also need to auto cancel when the window loses key status. This may be done via a mouse click in another window, or via the keyboard (cmd-~ or cmd-tab), or a notificaiton. Observing NSWindowDidResignKeyNotification catches all of these cases and the mouse down event monitor catches the other cases.
        lostFocusObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: parentWindow, queue: nil, using: {(_ arg1: Notification) -> Void in
            // lost key status, cancel the suggestion window
            self.cancelSuggestions()
        })
    }

    /* Order out the suggestion window, disconnect the accessibility logical relationship and dismantle any observers for auto cancel.
     Note: It is safe to call this method even if the suggestions window is not currently visible.
     */
    func cancelSuggestions() {
        let suggestionWindow: NSWindow? = window
        if suggestionWindow?.isVisible ?? false {
            // Remove the suggestion window from parent window's child window collection before ordering out or the parent window will get ordered out with the suggestion window.
            if let aWindow = suggestionWindow {
                suggestionWindow?.parent?.removeChildWindow(aWindow)
            }
            suggestionWindow?.orderOut(nil)
            // Disconnect the accessibility parent/child relationship
            ((suggestionWindow as? SUGSuggestionsWindow)?.parentElement as? SUGSearchFieldCell)?.suggestionsWindow = nil
            (suggestionWindow as? SUGSuggestionsWindow)?.parentElement = nil
        }
        // dismantle any observers for auto cancel
        if lostFocusObserver != nil {
            NotificationCenter.default.removeObserver(lostFocusObserver!)
            lostFocusObserver = nil
        }
        if localMouseDownEventMonitor != nil {
            NSEvent.removeMonitor(localMouseDownEventMonitor!)
            localMouseDownEventMonitor = nil
        }
    }

    /* Update the array of suggestions. The array should consist of NSDictionaries each containing the following keys:
     kSuggestionImageURL - The URL to an image file
     kSuggestionLabel - The main suggestion string
     kSuggestionDetailedLabel - A longer string that provides more detail about the suggestion
     kSuggestionImage - [optional] The image to show in the suggestion thumbnail. If this key is not provided, a thumbnail image will be created in a background que.
     */
    func setSuggestions(_ suggestions: [[String: Any]]?) {
        self.suggestions = suggestions!
        // We only need to update the layout if the window is currently visible.
        if (window?.isVisible)! {
            layoutSuggestions()
        }
    }

    /* Returns the dictionary of the currently selected suggestion.
     */
    func selectedSuggestion() -> [String: Any]? {
        var suggestion: Any? = nil
        // Find the currently selected view's controller (if there is one) and return the representedObject which is the NSMutableDictionary that was passed in via -setSuggestions:
        let selectedView: NSView? = self.selectedView
        for viewController: NSViewController in viewControllers where selectedView == viewController.view {
            suggestion = viewController.representedObject
            break
        }
        return suggestion as? [String: Any]
    }

    // MARK: -
    // MARK: Mouse Tracking
    /* Mouse tracking is easily accomplished via tracking areas. We setup a tracking area for suggestion view and watch as the mouse moves in and out of those tracking areas.
     */
    /* Properly creates a tracking area for an image view.
     */
    func trackingArea(for view: NSView?) -> Any? {
        // make tracking data (to be stored in NSTrackingArea's userInfo) so we can later determine the imageView without hit testing
        var trackerData: [AnyHashable: Any]? = nil
        if let aView = view {
            trackerData = [
                kTrackerKey: aView
            ]
        }
        let trackingRect: NSRect = window!.contentView!.convert(view?.bounds ?? CGRect.zero, from: view)
        let trackingOptions: NSTrackingArea.Options = [.enabledDuringMouseDrag, .mouseEnteredAndExited, .activeInActiveApp]
        let trackingArea = NSTrackingArea(rect: trackingRect, options: trackingOptions, owner: self, userInfo: trackerData)
        return trackingArea
    }

    // Creates suggestion views from suggestionprototype.xib for every suggestion and resize the suggestion window accordingly. Also creates a thumbnail image on a background queue.
    private func layoutSuggestions() {
        let window: NSWindow? = self.window
        let contentView = window?.contentView as? SUGSuggestionsContentView
        // Remove any existing suggestion view and associated tracking area and set the selection to nil
        selectedView = nil
        for viewController in viewControllers {
            viewController.view.removeFromSuperview()
        }
        viewControllers.removeAll()
        for trackingArea in trackingAreas {
            if let nsTrackingArea = trackingArea as? NSTrackingArea {
                contentView?.removeTrackingArea(nsTrackingArea)
            }
        }
        trackingAreas.removeAll()

        /* Iterate througn each suggestion creating a view for each entry.
         */
        /* The width of each suggestion view should match the width of the window. The height is determined by the view's height set in IB.
         */
        var contentFrame: NSRect? = contentView?.frame
        var frame = NSRect(x: 0, y: (contentView?.cornerRadius)!, width: contentFrame!.width, height: 0.0)
        // offset the Y posistion so that the suggetion view does not try to draw past the rounded corners.
        for entry: [String: Any] in suggestions {
            frame.origin.y += frame.size.height
            let viewController = NSViewController(nibName: NSNib.Name("suggestionprototype"), bundle: nil)
            let view = viewController.view as? NSVisualEffectView
            // Make the selectedView the samee as the 0th.
            if viewControllers.count == 0 {
                selectedView = view
            }
            // Use the height of set in IB of the prototype view as the heigt for the suggestion view.
            frame.size.height = (view?.frame.size.height)!
            view?.frame = frame
            if let aView = view {
                contentView?.addSubview(aView)
            }
            // don't forget to create the tracking are.
            let trackingArea = self.trackingArea(for: view) as? NSTrackingArea
            if let anArea = trackingArea {
                contentView?.addTrackingArea(anArea)
            }
            // convert the suggestion enty to a mutable dictionary. This dictionary is bound to the view controller's representedObject. The represented object is what all the subviews are bound to in IB. We must use a mutable dictionary because we may change one of its key values.
            var mutableEntry = entry
            viewController.representedObject = mutableEntry
            viewControllers.append(viewController)
            if let anArea = trackingArea {
                trackingAreas.append(anArea)
            }
            /* If the suggestion entry does not contain an NSImage (and never does in this sample code), then create a thumbnail from the fileURL on a background que
             */
            if mutableEntry[kSuggestionImage] == nil {
                // Load the image in an operation block so that the window pops up immediatly
                ITESharedOperationQueue()?.addOperation({
                    if let fileURL = mutableEntry[kSuggestionImageURL] as? URL,
                        let thumbnailImage = NSImage.iteThumbnailImage(withContentsOf: fileURL, width: kThumbnailWidth) {
                        OperationQueue.main.addOperation({
                            mutableEntry[kSuggestionImage] = thumbnailImage
                        })
                    }
                })
            }
        }
        /* We have added all of the suggestion to the window. Now set the size of the window.
         */
        // Don't forget to account for the extra room needed the rounded corners.
        contentFrame?.size.height = frame.maxY + (contentView?.cornerRadius)!
        var winFrame: NSRect = NSRect(origin: window!.frame.origin, size: window!.frame.size)
        winFrame.origin.y = winFrame.maxY - contentFrame!.height
        winFrame.size.height = contentFrame!.height
        window?.setFrame(winFrame, display: true)
    }

    /* The mouse is now over one of our child image views. Update selection and send action.
     */
    override func mouseEntered(with event: NSEvent) {
        let view: NSView?
        if let userData = event.trackingArea?.userInfo as? [String: NSView] {
            view = userData[kTrackerKey]!
        } else {
            view = nil
        }
        userSetSelectedView(view)
    }

    /* The mouse has left one of our child image views. Set the selection to no selection and send action
     */
    override func mouseExited(with event: NSEvent) {
        userSetSelectedView(nil)
    }

    /* The user released the mouse button. Force the parent text field to send its return action. Notice that there is no mouseDown: implementation. That is because the user may hold the mouse down and drag into another view.
     */
    override func mouseUp(with theEvent: NSEvent) {
        parentTextField?.validateEditing()
        parentTextField?.abortEditing()
        parentTextField?.sendAction(parentTextField?.action, to: parentTextField?.target)
        cancelSuggestions()
    }

    // MARK: -
    // MARK: Keyboard Tracking
    /* In addition to tracking the mouse, we want to allow changing our selection via the keyboard. However, the suggestion window never gets key focus as the key focus remains on te text field. Therefore we need to route move up and move down action commands from the text field and this controller. See CustomMenuAppDelegate.m -control:textView:doCommandBySelector: to see how that is done.
     */
    /* move the selection up and send action.
     */
    override func moveUp(_ sender: Any?) {
        let selectedView: NSView? = self.selectedView
        var previousView: NSView? = nil
        for viewController: NSViewController in viewControllers {
            let view: NSView? = viewController.view
            if view == selectedView {
                break
            }
            previousView = view
        }
        if previousView != nil {
            userSetSelectedView(previousView)
        }
    }
    /* move the selection down and send action.
     */
    override func moveDown(_ sender: Any?) {
        let selectedView: NSView? = self.selectedView
        var previousView: NSView? = nil
        for viewController: NSViewController in viewControllers.reversed() {
            let view: NSView? = viewController.view
            if view == selectedView {
                break
            }
            previousView = view
        }
        if previousView != nil {
            userSetSelectedView(previousView)
        }
    }
}
