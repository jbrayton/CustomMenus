//  Converted to Swift 4 by Swiftify v4.1.6654 - https://objectivec2swift.com/
/*
 File: HighlightingView.m
 Abstract: A simple view that draws menu-like highlighting and exposes its containing views as a suggestion for accessibility.
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

class HighlightingView: NSView {
    var isHighlighted = false

    // Draw with or without a highlight style
    override func draw(_ dirtyRect: NSRect) {
        let rect = NSIntersectionRect(dirtyRect, self.bounds)
        if isHighlighted {
            NSColor.alternateSelectedControlColor.set()
            __NSRectFillUsingOperation(rect, .sourceOver)
        } else {
            NSColor.clear.set()
            __NSRectFillUsingOperation(rect, .sourceOver)
        }
    }
    /* Custom highlighted property setter because when the property changes we need to redraw and update the containing text fields.
     */
    func setHighlighted(_ highlighted: Bool) {
        if self.isHighlighted != highlighted {
            self.isHighlighted = highlighted
            // Inform each contained text field what type of background they will be displayed on. This is how the txt field knows when to draw white text instead of black text.
            for subview in subviews where subview is NSTextField {
                (subview as? NSTextField)?.cell?.backgroundStyle = highlighted ? .dark : .light
            }
            needsDisplay = true
            // make sure we redraw with the correct highlight style.
        }
    }
    // MARK: -
    // MARK: Accessibility
    /* This view groups the contents of one suggestion.  It should be exposed to accessibility, and should report itself with the role 'AXGroup'.  Because this is an NSView subclass, most of the basic accessibility behavior (accessibility parent, children, size, position, window, and more) is inherited from NSView.  Note that even the role description attribute will update accordingly and its behavior does not need to be overridden.
     */
    // Make sure we are reported by accessibility.
    override func accessibilityIsIgnored() -> Bool {
        return false
    }

    override func accessibilityRole() -> NSAccessibility.Role? {
        return .group
    }
    
}
