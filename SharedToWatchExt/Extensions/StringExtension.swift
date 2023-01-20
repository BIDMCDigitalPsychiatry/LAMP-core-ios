//
//  String+Extension.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 13/01/20.
//

import Foundation

extension String {
    
    func toData() -> Data {

        return self.data(using: String.Encoding.utf8) ?? Data()
    }
    
    func startsWith(_ string: String) -> Bool {
        guard let range = range(of: string, options: [.caseInsensitive, .anchored], range: nil, locale: nil) else {
            return false
        }
        return range.lowerBound == startIndex
    }
    
    func substringFromIndex(_ index: Int) -> String {
        let indexStartOfText = self.index(self.startIndex, offsetBy: index)
        return String(self[indexStartOfText...])
    }
    
    func makeTwoPiecesUsing(seperator: Character) -> (String?, String?) {
        
        guard let firstIndex = self.firstIndex(of: seperator) else {
            return (nil, nil)
        }
        let firstPart = String(self[..<firstIndex])
        let startIndex = self.index(after: firstIndex)
        let secondPart = String(self[startIndex..<self.endIndex])
        return (firstPart, secondPart)
    }
        
    /**
     * Remove "http://" and "https://" if the protocol is included in the "host" name.
     */
    func cleanHostName() -> String {
        
        var newString = self
        if let range = newString.range(of: "https://") {
            newString.removeSubrange(range)
        }
        if let range = newString.range(of: "http://") {
            newString.removeSubrange(range)
        }
        return newString
    }
    
    func makeURLString() -> String? {

        if self.isEmpty == false, self.startsWith("http") == false {
            return "https://\(self)"
        }
        return self
    }
}
