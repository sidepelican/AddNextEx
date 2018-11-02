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

        var index = lastSelection.end.line
        var column = lastSelection.end.column
        let linesCount = buffer.lines.count
        while index < linesCount {
            let line = buffer.lines.object(at: index) as! NSString
            let found = line.range(of: selected, options: [.caseInsensitive], range: NSRange(location: column, length: line.length - column))
            if found.location != NSNotFound {
                let next = XCSourceTextRange()
                next.start = XCSourceTextPosition(line: index, column: found.lowerBound)
                next.end = XCSourceTextPosition(line: index, column: found.upperBound)
                buffer.selections.insert(next, at: buffer.selections.count - 1)

                completionHandler(nil)
                return
            }

            column = 0
            index += 1
        }

        completionHandler(nil)
    }
}
