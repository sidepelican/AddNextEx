import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        let buffer: XCSourceTextBuffer = invocation.buffer
        guard let firstSelection = buffer.selections.firstObject as? XCSourceTextRange else {
            completionHandler(nil)
            return
        }
        guard let lastSelection = buffer.selections.lastObject as? XCSourceTextRange else {
            completionHandler(nil)
            return
        }

        if firstSelection.start.line != firstSelection.end.line {
            completionHandler(NSError(domain: "com.side.junktown.AddNextEt", code: 1, userInfo: [NSLocalizedDescriptionKey: "Multiple lines are not supported"]))
            return
        }

        let selected = (buffer.lines[firstSelection.start.line] as! NSString).substring(with: NSRange(location: firstSelection.start.column, length: firstSelection.end.column - firstSelection.start.column))
        if selected.isEmpty {
            completionHandler(nil)
            return
        }

        let lastIndex = buffer.lines.count - 1

        // search in bottom term
        if let found = find(buffer: buffer,
                            range: .init(start: lastSelection.end,
                                         end: .init(line: lastIndex, column: buffer.lineLength(at: lastIndex) - 1)),
                            searchText: selected) {
            buffer.selections.insert(found, at: buffer.selections.count - 1)
            completionHandler(nil)
            return
        }

        // search in top term
        if let found = find(buffer: buffer,
                            range: .init(start: .init(line: 0, column: 0),
                                         end: lastSelection.start),
                            searchText: selected) {
            buffer.selections.insert(found, at: buffer.selections.count - 1)
            completionHandler(nil)
            return
        }

        completionHandler(nil)
    }

    private func find(buffer: XCSourceTextBuffer, range: XCSourceTextRange, searchText: String) -> XCSourceTextRange? {
        var index = range.start.line
        var column = range.start.column
        while index <= range.end.line {
            let line = buffer.lines.object(at: index) as! NSString
            let lineRange: NSRange
            if index == range.end.line {
                lineRange = NSRange(location: column, length: range.end.column - column)
            } else {
                lineRange = NSRange(location: column, length: line.length - column)
            }

            let found = line.range(of: searchText,
                                   options: [.caseInsensitive],
                                   range: lineRange)
            if found.location != NSNotFound {
                let next = XCSourceTextRange()
                next.start = XCSourceTextPosition(line: index, column: found.lowerBound)
                next.end = XCSourceTextPosition(line: index, column: found.upperBound)

                if !buffer.selections.contains(next) {
                    return next
                }
            }

            column = 0
            index += 1
        }

        return nil
    }
}

private extension XCSourceTextBuffer {
    func lineLength(at index: Int) -> Int {
        let line = lines.object(at: index) as! NSString
        return line.length
    }
}
