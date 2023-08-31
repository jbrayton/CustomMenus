//
//  NSImage+SUGMask.swift
//  CustomMenus
//
//  Created by John Brayton on 8/31/23.
//

import AppKit

extension NSImage {
    
    /*
        Adapted from Sapozhnik Ivan’s answer at:
        https://stackoverflow.com/questions/32042385/nsvisualeffectview-with-rounded-corners
     */
    static func SUG_mask(withCornerRadius radius: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: radius * 2, height: radius * 2), flipped: false) {
            NSBezierPath(roundedRect: $0, xRadius: radius, yRadius: radius).fill()
            NSColor.black.set()
            return true
        }
        
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        
        return image
    }
    
}
