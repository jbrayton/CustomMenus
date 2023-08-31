//
//  SUGMainWindowViewController.swift
//  CustomMenus
//
//  Created by John Brayton on 8/31/23.
//

import AppKit

class SUGMainWindowViewController : NSViewController {
    
    var suggestedURL: URL?
    
    @IBOutlet var imageView: NSImageView!

    /* This method is invoked when the user presses return (or enter) on the search text field. We don't want to use the text from the search field as it is just the image filename without a path. Also, it may not be valid. Instead, use this user action to trigger setting the large image view in the main window to the currently suggested URL, if there is one.
     */
    @IBAction func takeImage(fromSuggestedURL sender: Any) {
        var image: NSImage? = nil
        if suggestedURL != nil {
            image = NSImage(contentsOf: suggestedURL!)
        }
        imageView.image = image
    }
    
}

