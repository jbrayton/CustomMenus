//  Converted to Swift 4 by Swiftify v4.1.6654 - https://objectivec2swift.com/
/*
 File: ImagePickerMenuItemView.m
 Abstract: A custom view that is used as an NSMenuItem. This view contains up to 4 images and the logic to track the selection of one of those images.
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

class ImagePickerMenuItemView: NSView {
    // key for dictionary in NSTrackingAreas's userInfo
    let kTrackerKey = "whichImageView"
    let kNoSelection = -1

    @IBOutlet var imageView1: NSImageView!
    @IBOutlet var imageView2: NSImageView!
    @IBOutlet var imageView3: NSImageView!
    @IBOutlet var imageView4: NSImageView!
    @IBOutlet var spinner1: NSProgressIndicator!
    @IBOutlet var spinner2: NSProgressIndicator!
    @IBOutlet var spinner3: NSProgressIndicator!
    @IBOutlet var spinner4: NSProgressIndicator!
    private var imageViews = [NSImageView]()
    private var spinners = [NSProgressIndicator]()
    internal var trackingAreasList = [NSTrackingArea]()
    private var thumbnailsNeedUpdate = false

    /* Make sure that any key value observer of selectedImageUrl is notified when change our internal selected index.
     Note: Internally, keep track of a selected index so that we can eaasily refer to the imageView spinner and URL associated with index. Externally, supply only a selected URL.
     */
    class func keyPathsForValuesAffectingSelectedImageUrl() -> Set<AnyHashable>? {
        return Set<AnyHashable>(["selectedIndex"])
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        selectedIndex = kNoSelection
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* Place all the image views and spinners (circular progress indicators) that are wired up in the nib into NSArrays. This dramtically reduces code allowing us to easily link image view, spinners and URL sets.
     */
    override func awakeFromNib() {
        imageViews = [imageView1, imageView2, imageView3, imageView4]
        spinners = [spinner1, spinner2, spinner3, spinner4]
    }

    deinit {
        // tracking areas are removed from the view during deinit
    }

    /* Custom selectedIndex property setter so that we can be sure to redraw when the selection index changes.
     */
    private var selectedIndex: Int = 0 {
        didSet {
            needsDisplay = true
        }
    }

    /* These two properties are used to detemine which images to use and the current selection, if any. They me be set and interrogated manually, but in this sample code, they are bound to an NSDictionary in CustomMenusAppDelegate.m -setupImagesMenu.
     */

    /* Custom imageUrls property setter so that we can be sure to redraw when the image URLs change. Actually, we need to rebuild our thumbnail images, but we don't do that here because we may not even be visible at the moment. Instead, we mark an internal variable noting that the thumbnails need to be updated. see -viewWillDraw.
     */
    @objc public var imageUrls: [URL]! {
        didSet {
            thumbnailsNeedUpdate = true
            needsDisplay = true
        }
    }

    /* We must create our own selectedImageUrl property getter as there is no underlying member variable to synthesize to. Simply, return URL from _imageUrls at the selected index.
     */
    @objc public var selectedImageUrl: URL? {
        var selectedURL: URL? = nil
        let index: Int = selectedIndex
        if index >= 0 && index < Int(imageUrls.count) {
            selectedURL = imageUrls[index]
        }
        return selectedURL
    }

    /* Do any last minute layout changes such as updating thumnails because we are about to draw. While we are waiting for the thumbnails to be generated, display animated spinners (circular progress indicators).
     */
    override func viewWillDraw() {
        if thumbnailsNeedUpdate {
            // We may have less images than we had last time. Set all image views to a nil image.
            for imageView in imageViews {
                imageView.image = nil
            }
            // animating progress indicators in menus can be tricky. We must wait until the menu window becomes key before starting the animation.
            let windowIsKey: Bool = window!.isKeyWindow
            // Generate the thumbnail for each image in the background
            let imageUrls = self.imageUrls!
            for index in 0..<imageUrls.count {
                let imageView = imageViews[index]
                let imageUrl = imageUrls[index]
                let spinner = spinners[index]
                ITESharedOperationQueue()?.addOperation({
                    let thumbnailImage = NSImage.iteThumbnailImage(withContentsOf: imageUrl, width: imageView.bounds.width)
                    // Thumbnail generation is complete. Now we need to stop the associated animated spinner, hide it, and set the image view to the thumbnail image. Note: we need to do this on the main thread. This is easily done by adding a block to the main NSOperationQueue
                    OperationQueue.main.addOperation({
                        spinner.stopAnimation(nil)
                        spinner.isHidden = true
                        imageView.image = thumbnailImage as? NSImage
                    })
                })
                // show the spinner while thumbnail generation occurs in the background, but only start the animation if the popup menu window is key.
                spinner.isHidden = false
                if windowIsKey {
                    spinner.startAnimation(nil)
                }
            }
            // If the popup menu window is not yet key, then we need to listen for the notification of when it does become key. At that point, we can start animating the spinners.
            if !windowIsKey {
                // Use a block variable to hold the notificationObserver token so that we can refer to it inside the notification block.
                var notificationObserver: Any? = nil
                notificationObserver = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: nil, using: {(_ arg1: Notification) -> Void in
                    for spinner: NSProgressIndicator in self.spinners where !spinner.isHidden {
                        /* Only animate spinners that are visible. This solves two potential problems. First, it only starts spinners for the images that are going to display an image (we may have been given fewer URLs than we have image views). Second, if the thumbnail creation ever completes before the window becomes key we don't want to animate the associated spinner. The code above thumbnail generation code will hide the spinner, so we can rely on that here.
                         */
                        spinner.startAnimation(nil)
                    }
                    // Once we get this notification, we can stop listening for more.
                    if let anObserver = notificationObserver {
                        NotificationCenter.default.removeObserver(anObserver)
                    }
                })
            }
            thumbnailsNeedUpdate = false
        }
        // It is very import to call up to super!
        super.viewWillDraw()
    }

    /* If there is a selection, fill a rect behind the selected image view. Since the image view is a subview of this view, it will look like a border around the image.
     */
    override func draw(_ dirtyRect: NSRect) {
        let index: Int = selectedIndex
        if index >= 0 && index < imageUrls.count {
            let selectedImageView = imageViews[index]
            let frame: NSRect = convert(selectedImageView.bounds, from: selectedImageView).insetBy(dx: -4.0, dy: -4.0)
            NSColor.selectedMenuItemColor.set()
            frame.fill()
        }
    }

    /* As the window that contains the popup menu is created, the view associated with the menu item (this view) is added to the window. When the window is destroyed the view is removed from the window, but still retained by the menu item. A new window is created and destroyed each time a menu is displayed. This makes this method the ideal place to start and stop animations.
     */
    override func viewDidMoveToWindow() {
        if window != nil {
            // In IB, this view is set to stretch to the width of the menu window. However, we cannot set the springs and struts of our containing image and spinner views to auto center themeselves. We get around this by placing the the image and spinner views inside another, non-resizeable NSView in IB. Now, all we need to do here, is center that one non-resizeable container view.
            let containerView = subviews[0]
            let parentFrame: NSRect = frame
            var centeredFrame: NSRect = containerView.frame
            centeredFrame.origin.x = CGFloat(floorf(Float((parentFrame.size.width - centeredFrame.size.width) / 2.0))) + parentFrame.origin.x
            centeredFrame.origin.y = CGFloat(floorf(Float((parentFrame.size.height - centeredFrame.size.height) / 2.0))) + parentFrame.origin.y
            containerView.frame = centeredFrame
            // Start any animations here
            // The spinner animation is only done when we need to generate new thumbnail images. See the -viewWillDraw method implementation in this file.
        } else {
            // Make sure that all the spinners stop animating
            for spinner: NSProgressIndicator in spinners {
                spinner.stopAnimation(nil)
                spinner.isHidden = true
            }
        }
    }

    /* Do everything associated with sending the action from user selection such as terminating menu tracking.
     */
    func sendAction() {
        let actualMenuItem: NSMenuItem? = enclosingMenuItem
        // Send the action set on the actualMenuItem to the target set on the actualMenuItem, and make come from the actualMenuItem.
        if let anAction = actualMenuItem?.action {
            NSApp.sendAction(anAction, to: actualMenuItem?.target, from: actualMenuItem)
        }
        // dismiss the menu being tracked
        let menu: NSMenu? = actualMenuItem?.menu
        menu?.cancelTracking()
        needsDisplay = true
    }

    // MARK: -
    // MARK: Mouse Tracking
    /* Mouse tracking is easily accomplished via tracking areas. We setup a tracking area for each image view and watch as the mouse moves in and out of those tracking areas. When a mouse up occurs, we can send our action and close the menu.
     */

    /* Properly create a tracking area for an image view.
     */
    func trackingArea(for index: Int) -> NSTrackingArea {
        // make tracking data (to be stored in NSTrackingArea's userInfo) so we can later determine the imageView without hit testing
        let trackerData = [
            kTrackerKey: index
        ]
        let view: NSView? = imageViews[index]
        // Since the tracking area is going to be added to self, we need to convert image view's bounds to self's coordinate system. We use bounds, instead of frame because the view's frame is in the view's superview's coordinate system and that superview may not be (and in this case is not) self. Therefore, converting bounds to self will work regardless of the view hierarchy relationship.
        let trackingRect: NSRect = convert(view?.bounds ?? CGRect.zero, from: view)
        let trackingOptions: NSTrackingArea.Options = [.enabledDuringMouseDrag, .mouseEnteredAndExited, .activeInActiveApp]
        let trackingArea = NSTrackingArea(rect: trackingRect, options: trackingOptions, owner: self, userInfo: trackerData)
        return trackingArea
    }

    /* The view is automatically asked to update the tracking areas at the appropriate time via this overridable methos. 
     */
    override func updateTrackingAreas() {
        // Remove any existing tracking areas
        for trackingArea: NSTrackingArea in trackingAreasList {
            removeTrackingArea(trackingArea)
        }
        var trackingArea: NSTrackingArea?
        trackingAreasList.removeAll()
        // keep all tracking areas in an array
        /* Add a tracking area for each image view. We use an integer for-loop instead of fast enumeration because we need to link the tracking area to the index.
         */
        for index in 0..<imageViews.count {
            trackingArea = self.trackingArea(for: index)
            if let anArea = trackingArea {
                trackingAreasList.append(anArea)
            }
            if let anArea = trackingArea {
                addTrackingArea(anArea)
            }
        }
    }

    /* The mouse is now over one of our child image views. Update selection.
     */
    override func mouseEntered(with event: NSEvent) {
        // The index of the image view is stored in the user data.
        if let userData = event.trackingArea?.userInfo as? [String: Int] {
            selectedIndex = userData[kTrackerKey]!
        } else {
            selectedIndex = 0
        }
    }

    /* The mouse has left one of our child image views. Set the selection to no selection.
     */
    override func mouseExited(with event: NSEvent) {
        selectedIndex = kNoSelection
    }

    /* The user released the mouse button. Send the action and let the target ask for the selection. Notice that there is no mouseDown: implementation. This is because the user may have held the mouse down as the menu popped up. Or the user may click on this view, but drag into another menu item. That menu item needs to be able to start tracking the mouse. Therefore, we only keep track of our selection via the tracking areas and send our action to our target when the user releases the mouse button inside this view.
     */
    override func mouseUp(with event: NSEvent) {
        sendAction()
    }

    // MARK: -
    // MARK: Keyboard Tracking
    /* In addition to tracking the mouse, we want to allow changing our selection via the keyboard.
     */

    /* Must return YES from -acceptsFirstResponder or we will not get key events. By default NSView return NO.
     */
    func acceptsFirstResponder() -> Bool {
        return true
    }

    /* Set the selected index to the first image view if there is no current selection. We check for a current selection because a mouse down inside a child image view will cause this method to be called and we don't want to change the user's mouse selection.
     */
    override func becomeFirstResponder() -> Bool {
        if selectedIndex == kNoSelection {
            selectedIndex = 0
        }
        return true
    }

    /* We will lose first responder status when the user arrows up or down, or when the menu window is destroyed. If the user keyboard navigates to another NSMenuItem then remove any selection, and if the menu window is destroyed, then the selection no longer matters.
     */
    override func resignFirstResponder() -> Bool {
        selectedIndex = kNoSelection
        return true
    }

    /* Do the normal AppKit behavior of calling interpretKeyEvents: to allow the input manager to determine the correct keybinding. It is important to call up to super so that user can navigate to other menu items
     */
    override func keyDown(with event: NSEvent?) {
        interpretKeyEvents([event!])
        if let anEvent = event {
            super.keyDown(with: anEvent)
        }
    }

    /* Catch the commands interpreted by interpretKeyEvents:. Normally, if we don't implement (or any other view in the hierarchy implements) the selector, the system beeps. Menu navigation generally doesn't beep, so stop doCommandBySelector: from calling up the hierarchy just to stop the beep.
     */
    override func doCommand(by selector: Selector) {
        if selector == #selector(NSResponder.moveRight(_:)) || selector == #selector(NSResponder.moveLeft(_:)) || selector == #selector(NSResponder.moveToBeginningOfLine(_:)) || selector == #selector(NSResponder.moveToEndOfLine(_:)) || selector == #selector(NSResponder.insertNewline(_:)) {
            super.doCommand(by: selector)
        }
        // do nothing, let the menu handle it (see call to super in -keyDown:)
        // But don't call super to prevent the system beep
    }

    /* move the selection to the right
     */
    @objc override func moveRight(_ sender: Any?) {
        var index: Int = selectedIndex + 1
        index = min(index, Int(imageUrls.count) - 1)
        selectedIndex = index
    }

    /* move the selection to the left
     */
    @objc override func moveLeft(_ sender: Any?) {
        var index: Int = selectedIndex - 1
        index = max(0, index)
        selectedIndex = index
    }

    /* move the selection to index 0
     */
    @objc func moveToBeginningOfLine(sender: Any?) {
        selectedIndex = 0
    }

    /* move the selection to the greatest valid index
     */
    @objc func moveToEndOfLine(sender: Any?) {
        selectedIndex = imageUrls.count - 1
    }

    /* The user pressed return or equivilent, send the action
     */
    @objc override func insertNewline(_ sender: Any?) {
        sendAction()
    }

    /* The key event was not interpreted as a command, so interpretKeyEvents: calls this method. In tis case, we want to check for space, because space is also used to select a menu item.
     */
    override func insertText(_ insertString: Any) {
        if (insertString as? String) == " " {
            sendAction()
        }
    }
}
