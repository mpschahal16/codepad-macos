import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct CodePadApp: App {
    @StateObject private var store = EditorStore()

    var body: some Scene {
        WindowGroup {
            CodePadWindow()
                .environmentObject(store)
                .frame(minWidth: 760, minHeight: 500)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") { store.newDocument() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("Open…") { store.openFiles() }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    if let document = store.activeDocument { store.save(document) }
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(store.activeDocument == nil)
                Button("Save As…") {
                    if let document = store.activeDocument { store.saveAs(document) }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(store.activeDocument == nil)
            }
        }
    }
}

@MainActor
final class EditorDocument: ObservableObject, Identifiable {
    let id = UUID()
    @Published var text: String {
        didSet { isDirty = text != savedText }
    }
    @Published var isDirty = false
    var url: URL?
    private var savedText: String

    init(text: String = "", url: URL? = nil) {
        self.text = text
        self.savedText = text
        self.url = url
    }

    var title: String { url?.lastPathComponent ?? "Untitled" }
    var lineCount: Int { max(1, text.reduce(into: 1) { if $1 == "\n" { $0 += 1 } }) }
    var language: String {
        guard let ext = url?.pathExtension, !ext.isEmpty else { return "Plain Text" }
        let names = ["swift": "Swift", "m": "Objective-C", "mm": "Objective-C++", "c": "C", "h": "C / C++", "cpp": "C++", "cc": "C++", "html": "HTML", "css": "CSS", "js": "JavaScript", "ts": "TypeScript", "json": "JSON", "py": "Python", "rb": "Ruby", "go": "Go", "rs": "Rust", "md": "Markdown", "xml": "XML", "yaml": "YAML", "yml": "YAML", "sh": "Shell"]
        return names[ext.lowercased()] ?? ext.uppercased()
    }

    func markSaved(at newURL: URL? = nil) {
        if let newURL { url = newURL }
        savedText = text
        isDirty = false
    }
}

@MainActor
final class EditorStore: ObservableObject {
    @Published private(set) var documents: [EditorDocument]
    @Published var activeDocumentID: UUID?

    init() {
        let first = EditorDocument()
        documents = [first]
        activeDocumentID = first.id
    }

    var activeDocument: EditorDocument? {
        documents.first { $0.id == activeDocumentID }
    }

    func newDocument() {
        let document = EditorDocument()
        documents.append(document)
        activeDocumentID = document.id
    }

    func openFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.item]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }

        for url in panel.urls {
            if let existing = documents.first(where: { $0.url == url }) {
                activeDocumentID = existing.id
                continue
            }
            do {
                let contents = try String(contentsOf: url, encoding: .utf8)
                let document = EditorDocument(text: contents, url: url)
                documents.append(document)
                activeDocumentID = document.id
            } catch {
                showError("Could not open \(url.lastPathComponent)", detail: error.localizedDescription)
            }
        }
    }

    @discardableResult
    func save(_ document: EditorDocument) -> Bool {
        guard let url = document.url else { return saveAs(document) }
        return write(document, to: url)
    }

    @discardableResult
    func saveAs(_ document: EditorDocument) -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.item]
        panel.nameFieldStringValue = document.title == "Untitled" ? "Untitled.txt" : document.title
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        return write(document, to: url)
    }

    func close(_ document: EditorDocument) {
        if document.isDirty {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Save changes to \(document.title)?"
            alert.informativeText = "Your edits will be lost if you close this tab without saving."
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "Discard Changes")
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                guard save(document) else { return }
            case .alertThirdButtonReturn:
                break
            default:
                return
            }
        }

        documents.removeAll { $0.id == document.id }
        if documents.isEmpty { newDocument(); return }
        if activeDocumentID == document.id { activeDocumentID = documents.last?.id }
    }

    private func write(_ document: EditorDocument, to url: URL) -> Bool {
        do {
            try document.text.write(to: url, atomically: true, encoding: .utf8)
            document.markSaved(at: url)
            return true
        } catch {
            showError("Could not save \(url.lastPathComponent)", detail: error.localizedDescription)
            return false
        }
    }

    private func showError(_ title: String, detail: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = title
        alert.informativeText = detail
        alert.runModal()
    }
}

struct CodePadWindow: View {
    @EnvironmentObject private var store: EditorStore
    @StateObject private var windowState = WindowState()
    @StateObject private var editorController = EditorController()

    var body: some View {
        VStack(spacing: 0) {
            header
            tabStrip
            if windowState.showFind {
                findBar
            }
            if let document = store.activeDocument {
                EditorPane(document: document, controller: editorController)
                statusBar(document)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text").font(.system(size: 28)).foregroundStyle(.secondary)
                    Text("No document open").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 12) {
            CatLogoMark(size: 32)
            Text("CodePad")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Button { store.newDocument() } label: { Label("New", systemImage: "doc.badge.plus") }
                .keyboardShortcut("n", modifiers: .command)
            Button { store.openFiles() } label: { Label("Open", systemImage: "folder") }
                .keyboardShortcut("o", modifiers: .command)
            Button { if let document = store.activeDocument { store.save(document) } } label: { Label("Save", systemImage: "square.and.arrow.down") }
                .keyboardShortcut("s", modifiers: .command)
            Button { windowState.showFind.toggle() } label: { Label("Find", systemImage: "magnifyingglass") }
                .keyboardShortcut("f", modifiers: .command)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) { Divider() }
    }

    private var findBar: some View {
        HStack(spacing: 9) {
            TextField("Find in document", text: $windowState.findQuery)
                .textFieldStyle(.roundedBorder)
                .onSubmit { editorController.findNext(windowState.findQuery) }
            Button { editorController.findPrevious(windowState.findQuery) } label: {
                Image(systemName: "chevron.up")
            }
            .help("Previous match")
            Button { editorController.findNext(windowState.findQuery) } label: {
                Image(systemName: "chevron.down")
            }
            .help("Next match")
            Text("\(editorController.matchCount(windowState.findQuery, in: store.activeDocument?.text ?? "")) matches")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Button { windowState.showFind = false } label: {
                Image(systemName: "xmark")
            }
            .help("Close Find")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) { Divider() }
    }

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(store.documents) { document in
                    DocumentTab(document: document, isSelected: document.id == store.activeDocumentID) {
                        store.activeDocumentID = document.id
                    } onClose: {
                        store.close(document)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 38)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func statusBar(_ document: EditorDocument) -> some View {
        HStack(spacing: 14) {
            Text(document.language)
            Text("UTF-8")
            Text("\(document.lineCount) lines")
            Spacer()
            if document.isDirty { Text("Modified").foregroundStyle(.orange) }
            Text(document.url?.lastPathComponent ?? "Unsaved")
                .lineLimit(1)
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .top) { Divider() }
    }
}

struct DocumentTab: View {
    @ObservedObject var document: EditorDocument
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            if document.isDirty {
                Circle().fill(Color.accentColor).frame(width: 6, height: 6)
            }
            Button(action: onSelect) {
                Text(document.title).lineLimit(1).frame(maxWidth: 150)
            }
            .buttonStyle(.plain)
            Button(action: onClose) {
                Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                    .frame(width: 17, height: 17)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Close tab")
        }
        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
        .padding(.horizontal, 10)
        .frame(height: 37)
        .background(isSelected ? Color(nsColor: .textBackgroundColor) : Color.clear)
        .overlay(alignment: .bottom) {
            if isSelected { Rectangle().fill(Color.accentColor).frame(height: 2) }
        }
    }
}

struct EditorPane: View {
    @ObservedObject var document: EditorDocument
    @ObservedObject var controller: EditorController

    var body: some View {
        NativeTextEditor(text: $document.text, controller: controller)
            .accessibilityLabel("Text editor")
    }
}

@MainActor
final class WindowState: ObservableObject {
    @Published var showFind = false
    @Published var findQuery = ""
}

@MainActor
final class EditorController: ObservableObject {
    weak var textView: NSTextView?

    func findNext(_ query: String) {
        guard !query.isEmpty, let textView else { return }
        let contents = textView.string as NSString
        guard contents.length > 0 else { return }
        let selected = textView.selectedRange()
        let start = min(NSMaxRange(selected), contents.length)
        let remainder = NSRange(location: start, length: contents.length - start)
        var match = contents.range(of: query, options: [.caseInsensitive], range: remainder)
        if match.location == NSNotFound, start > 0 {
            match = contents.range(of: query, options: [.caseInsensitive], range: NSRange(location: 0, length: start))
        }
        select(match, in: textView)
    }

    func findPrevious(_ query: String) {
        guard !query.isEmpty, let textView else { return }
        let contents = textView.string as NSString
        let end = min(textView.selectedRange().location, contents.length)
        let match = contents.range(of: query, options: [.caseInsensitive, .backwards], range: NSRange(location: 0, length: end))
        select(match, in: textView)
    }

    func matchCount(_ query: String, in text: String) -> Int {
        guard !query.isEmpty else { return 0 }
        let contents = text as NSString
        var cursor = 0
        var count = 0
        while cursor < contents.length {
            let match = contents.range(of: query, options: [.caseInsensitive], range: NSRange(location: cursor, length: contents.length - cursor))
            guard match.location != NSNotFound else { break }
            count += 1
            cursor = NSMaxRange(match)
        }
        return count
    }

    private func select(_ range: NSRange, in textView: NSTextView) {
        guard range.location != NSNotFound else { return }
        textView.setSelectedRange(range)
        textView.scrollRangeToVisible(range)
        textView.window?.makeFirstResponder(textView)
    }
}

struct NativeTextEditor: NSViewRepresentable {
    @Binding var text: String
    @ObservedObject var controller: EditorController

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.drawsBackground = true

        let textView = NSTextView()
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textContainerInset = NSSize(width: 10, height: 12)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.delegate = context.coordinator
        textView.string = text
        scrollView.documentView = textView
        controller.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView else { return }
        controller.textView = textView
        if textView.string != text {
            textView.string = text
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NativeTextEditor
        init(_ parent: NativeTextEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            if parent.text != textView.string { parent.text = textView.string }
        }
    }
}

struct CatLogoMark: View {
    var size: CGFloat
    private let ink = Color(red: 20 / 255, green: 34 / 255, blue: 56 / 255)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(LinearGradient(colors: [Color(red: 27 / 255, green: 43 / 255, blue: 66 / 255), Color(red: 12 / 255, green: 20 / 255, blue: 34 / 255)], startPoint: .topLeading, endPoint: .bottomTrailing))
            CatHeadShape()
                .fill(LinearGradient(colors: [Color(red: 167 / 255, green: 242 / 255, blue: 221 / 255), Color(red: 98 / 255, green: 207 / 255, blue: 177 / 255)], startPoint: .topLeading, endPoint: .bottomTrailing))
            HStack(spacing: size * 0.20) {
                Capsule().fill(ink).frame(width: size * 0.075, height: size * 0.14)
                Capsule().fill(ink).frame(width: size * 0.075, height: size * 0.14)
            }
            .offset(y: size * 0.10)
            CatNoseShape()
                .fill(Color(red: 255 / 255, green: 140 / 255, blue: 121 / 255))
                .frame(width: size * 0.12, height: size * 0.065)
                .offset(y: size * 0.21)
            CatMouthShape()
                .stroke(ink.opacity(0.78), style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.21, height: size * 0.105)
                .offset(y: size * 0.285)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct CatHeadShape: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height) }
        var path = Path()
        path.move(to: p(0.24, 0.44))
        path.addLine(to: p(0.19, 0.22))
        path.addLine(to: p(0.43, 0.34))
        path.addQuadCurve(to: p(0.57, 0.34), control: p(0.50, 0.31))
        path.addLine(to: p(0.81, 0.22))
        path.addLine(to: p(0.76, 0.44))
        path.addCurve(to: p(0.78, 0.78), control1: p(0.91, 0.53), control2: p(0.91, 0.68))
        path.addCurve(to: p(0.50, 0.91), control1: p(0.71, 0.91), control2: p(0.60, 0.93))
        path.addCurve(to: p(0.22, 0.78), control1: p(0.40, 0.93), control2: p(0.29, 0.91))
        path.addCurve(to: p(0.24, 0.44), control1: p(0.09, 0.68), control2: p(0.09, 0.53))
        path.closeSubpath()
        return path
    }
}

struct CatNoseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct CatMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.height * 0.32))
        path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.32))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.15, y: rect.height * 0.72), control: CGPoint(x: rect.width * 0.30, y: rect.maxY))
        path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.32))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.85, y: rect.height * 0.72), control: CGPoint(x: rect.width * 0.70, y: rect.maxY))
        return path
    }
}
