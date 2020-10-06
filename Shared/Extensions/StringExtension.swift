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

    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
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
    
        
    /**
     * Remove "http://" and "https://" if the protocol is included in the "host" name.
     */
    mutating func cleanHostName() -> String {
        
        if let range = self.range(of: "https://") {
            self.removeSubrange(range)
        }
        if let range = self.range(of: "http://") {
            self.removeSubrange(range)
        }
        return self
    }
    
    func makeURLString() -> String? {

        if self.isEmpty == false, self.startsWith("http") == false {
            return "https://\(self)"
        }
        return self
    }
}
