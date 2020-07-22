//
//  Logging.swift
//  mindLAMP Consortium
//
//  Created by ZCO Engineer on 07/04/16.
//

import Foundation

class Logging {
    static var isLogToFile: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isLogToFile")
        }
        set(newValue) {
            //save
            UserDefaults.standard.set(newValue, forKey: "isLogToFile")
            UserDefaults.standard.synchronize()
        }
    }
}

// MARK: - Global functions for logging

func print(_ items: Any ..., separator: String = " ", terminator: String = "\n") {
    //#if DEBUG
        var idx = items.startIndex
        let endIdx = items.endIndex
        repeat {
            Swift.print(items[idx], separator: separator, terminator: idx == endIdx ? terminator : separator)
            idx += 1
        }
            while idx < endIdx
    //#endif
}
/**
 Prints the filename, function name, line number and textual representation of `object` and a newline character into
 the standard output if the build setting for "Other Swift Flags" defines `-D DEBUG`.
 The current thread is a prefix on the output. <UI> for the main thread, <BG> for anything else.
 Only the first parameter needs to be passed to this funtion.
 The textual representation is obtained from the `object` using its protocol conformances, in the following
 order of preference: `CustomDebugStringConvertible` and `CustomStringConvertible`. Do not overload this function for
 your type. Instead, adopt one of the protocols mentioned above.
 :param: object   The object whose textual representation will be printed. If this is an expression, it is lazily evaluated.
 :param: file     The name of the file, defaults to the current file without the ".swift" extension.
 :param: function The name of the function, defaults to the function within which the call is made.
 :param: line     The line number, defaults to the line number within the file that the call is made.
 */

func printDebug(_ items: Any ..., separator: String = " ", terminator: String = "\n", file: String = #file, function: String = #function, line: Int = #line) {
    //#if DEBUG
        var idx = items.startIndex
        let endIdx = items.endIndex
        var fileName = (file as NSString).pathComponents.last ?? "(unknown)"
        fileName = (fileName as NSString).deletingPathExtension
        let queue = Thread.isMainThread ? "UI" : "BG"
        repeat {
            Swift.print("\n<\(queue)><\(fileName)> \(function)[\(line)]: \(items[idx])", separator: separator, terminator: idx == endIdx ? terminator : separator)
            idx += 1
        }
            while idx < endIdx
    //#endif
}

func printError(_ items: Any ..., separator: String = " ", terminator: String = "\n", file: String = #file, function: String = #function, line: Int = #line, isWriteToFile: Bool = true) {
    if Logging.isLogToFile {
        printToFile(items, file: file, function: function, line: line)
        return
    }
    var idx = items.startIndex
    let endIdx = items.endIndex
    var fileName = (file as NSString).pathComponents.last ?? "(unknown)"
    fileName = (fileName as NSString).deletingPathExtension
    repeat {
        Swift.print("\n<\(fileName)> \(function)[\(line)]: \(items[idx])", separator: separator, terminator: idx == endIdx ? terminator : separator)
        idx += 1
    }
        while idx < endIdx
}
func printToFile(_ items: Any ..., separator: String = " ", terminator: String = "\n", file: String = #file, function: String = #function, line: Int = #line, forceToWrite: Bool = false) {
    if !Logging.isLogToFile && !forceToWrite {
        printDebug(items, file: file, function: function, line: line)
        return
    }
    #if DEBUG
        if forceToWrite {
            printError(items, file: file, function: function, line: line, isWriteToFile: false)
            return
        }
    #endif
    var idx = items.startIndex
    let endIdx = items.endIndex
    var fileName = (file as NSString).pathComponents.last ?? "(unknown)"
    fileName = (fileName as NSString).deletingPathExtension
    var mtext: String = ""
    repeat {
        mtext += "\n\(Date().toGMTString())<\(fileName)> \(function)[\(line)]: \(items[idx])"
        //Swift.print("\n<\(fileName)> \(function)[\(line)]: \(items[idx])")
        idx += 1
    } while idx < endIdx
    do {
        let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let path = documents.appendingPathComponent("log.txt").path
        if let outputStream = OutputStream(toFileAtPath: path, append: true) {
            outputStream.open()
            if let data = mtext.data(using: String.Encoding.utf8) {
                _ = data.withUnsafeBytes { outputStream.write($0, maxLength: data.count) }
            }
            outputStream.close()
        } else {
            print("Unable to open file")
        }
    } catch let err {
        print("file catch")
        print(err.localizedDescription)
    }
}
