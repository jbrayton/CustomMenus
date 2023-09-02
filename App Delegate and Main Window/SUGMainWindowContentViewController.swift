//
//  SUGMainWindowContentViewController.swift
//  CustomMenus
//
//  Created by John Brayton on 8/31/23.
//

import AppKit

class SUGMainWindowContentViewController : NSViewController {
    
    @IBOutlet var imageView: NSImageView!

    func setImageUrl( imageUrl: URL? ) {
        var image: NSImage? = nil
        if let imageUrl {
            image = NSImage(contentsOf: imageUrl)
        }
        imageView.image = image
    }
    
}

