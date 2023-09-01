//
//  SUGSuggestionGenerator.swift
//  CustomMenus
//
//  Created by John Brayton on 8/31/23.
//

import Foundation
import UniformTypeIdentifiers

class SUGSuggestionGenerator {
    
    private let kDesktopPicturesPath = "/System/Library/Desktop Pictures"

    var imageUrls = [URL]()
    
    // If true and if there is at least one applicable suggestion, the first suggestion will be immediately selected.
    // The search field will be populated with the name of that suggestion. Pressing return will execute that suggestion.
    // If false, the user must select a suggestion with the arrow keys or mouse in order to execute a selection.
    let automaticallySelectFirstSuggestion = false
    
    func suggestions( forSearchString searchString: String ) -> [SUGSuggestion] {
        
        guard !searchString.isEmpty else {
            return [SUGSuggestion]()
        }
        
        // We don't want to hit the disk every time we need to re-calculate the the suggestion list. So we cache the result from disk. If we really wanted to be fancy, we could listen for changes to the file system at the baseURL to know when the cache is out of date.
        if imageUrls.count == 0 {
            imageUrls = [URL]()
            imageUrls.reserveCapacity(1)
            let baseURL = URL(filePath: kDesktopPicturesPath)
            let keyProperties: [URLResourceKey] = [.isDirectoryKey, .typeIdentifierKey, .localizedNameKey]
            let dirItr: FileManager.DirectoryEnumerator? = FileManager.default.enumerator(at: baseURL, includingPropertiesForKeys: keyProperties, options: [.skipsPackageDescendants, .skipsHiddenFiles], errorHandler: nil)
            while let file = dirItr?.nextObject() as? URL {
                var isDirectory: NSNumber? = nil
                try? isDirectory = ((file.resourceValues(forKeys: [.isDirectoryKey]).allValues.first?.value ?? "") as? NSNumber)
                if isDirectory != nil && isDirectory! == 0 {
                    var fileType: String? = nil
                    try? fileType = ((file.resourceValues(forKeys: [.typeIdentifierKey]).allValues.first?.value ?? "") as? String)
                    if let fileType, UTType(fileType)?.conforms(to: UTType.image) == true {
                        imageUrls.append(file)
                    }
                }
            }
        }
        // Search the known image URLs array for matches.
        var suggestions = [SUGSuggestion]()
        suggestions.reserveCapacity(1)
        let upperSearchString = searchString.uppercased()
        for hashableFile: AnyHashable in imageUrls {
            guard let file = hashableFile as? URL else {
                continue
            }
            if let localizedName = try? ((file.resourceValues(forKeys: [.localizedNameKey]).allValues.first?.value ?? "") as? String) {
                if (localizedName.hasPrefix(searchString) || localizedName.uppercased().hasPrefix(upperSearchString)) {
                    let entry = SUGSuggestion(name: localizedName, url: file)
                    suggestions.append(entry)
                }
            }
        }
        return suggestions
    }
    
}
