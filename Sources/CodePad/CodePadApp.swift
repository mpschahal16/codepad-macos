import AppKit
import SwiftUI
import UniformTypeIdentifiers
import ScintillaNative

struct LanguageMode: Identifiable, Hashable {
    let id: String
    let name: String
    let lexer: String
    let extensions: [String]
    let keywords: [String]

    static let all: [LanguageMode] = [
        .init(id: "plain", name: "Plain Text", lexer: "", extensions: ["txt", "text"], keywords: []),
        .init(id: "c", name: "C", lexer: "cpp", extensions: ["c", "h"], keywords: ["auto break case char const continue default do double else enum extern float for goto if inline int long register restrict return short signed sizeof static struct switch typedef union unsigned void volatile while", "size_t FILE NULL true false"]),
        .init(id: "cpp", name: "C++", lexer: "cpp", extensions: ["cc", "cpp", "cxx", "hpp", "hh", "hxx"], keywords: ["alignas alignof and and_eq asm auto bitand bitor bool break case catch char class compl concept const constexpr const_cast continue co_await co_return co_yield decltype default delete do double dynamic_cast else enum explicit export extern false float for friend goto if inline int long mutable namespace new noexcept not not_eq nullptr operator or or_eq private protected public register reinterpret_cast requires return short signed sizeof static static_assert static_cast struct switch template this thread_local throw true try typedef typeid typename union unsigned using virtual void volatile wchar_t while xor", "std string vector map set unordered_map unique_ptr shared_ptr"]),
        .init(id: "csharp", name: "C#", lexer: "cpp", extensions: ["cs"], keywords: ["abstract as base bool break byte case catch char checked class const continue decimal default delegate do double else enum event explicit extern false finally fixed float for foreach goto if implicit in int interface internal is lock long namespace new null object operator out override params private protected public readonly ref return sbyte sealed short sizeof stackalloc static string struct switch this throw true try typeof uint ulong unchecked unsafe ushort using virtual void volatile while async await var get set"]),
        .init(id: "java", name: "Java", lexer: "cpp", extensions: ["java"], keywords: ["abstract assert boolean break byte case catch char class const continue default do double else enum extends final finally float for if implements import instanceof int interface long native new package private protected public return short static strictfp super switch synchronized this throw throws transient try void volatile while true false null var record sealed permits yield", "String Object System Integer List Map Set"]),
        .init(id: "javascript", name: "JavaScript", lexer: "cpp", extensions: ["js", "mjs", "cjs", "jsx"], keywords: ["async await break case catch class const continue debugger default delete do else export extends false finally for function if import in instanceof let new null return static super switch this throw true try typeof var void while with yield", "Array Boolean Date Error Function JSON Math Number Object Promise RegExp String Map Set"]),
        .init(id: "typescript", name: "TypeScript", lexer: "cpp", extensions: ["ts", "tsx"], keywords: ["abstract any as asserts async await bigint boolean break case catch class const constructor continue declare default delete do else enum export extends false finally for from function get if implements import in infer instanceof interface is keyof let module namespace never new null number object package private protected public readonly require global return set static string super switch symbol this throw true try type typeof undefined unique unknown var void while with yield", "Array Date Error Function Map Object Promise Record Set String"]),
        .init(id: "python", name: "Python", lexer: "python", extensions: ["py", "pyw", "pyi"], keywords: ["and as assert async await break class continue def del elif else except False finally for from global if import in is lambda nonlocal not or pass raise return True try while with yield None", "ArithmeticError Exception IndexError KeyError RuntimeError self super print len range"]),
        .init(id: "swift", name: "Swift", lexer: "cpp", extensions: ["swift"], keywords: ["associatedtype async await break case catch class continue defer defer else enum extension fallthrough false fileprivate for func guard if import in init inout internal let nil open operator private protocol public repeat rethrows return self Self static struct subscript super switch throw throws true try typealias var where while", "Array Bool Dictionary Double Error Float Int Optional Result Set String UInt Void"]),
        .init(id: "html", name: "HTML", lexer: "hypertext", extensions: ["html", "htm", "xhtml", "shtml"], keywords: ["a abbr address article aside audio b body br button canvas caption code div em footer form h1 h2 h3 head header html img input label li link main meta nav ol option p script section select span style table tbody td textarea th thead title tr ul video", "class id href src alt type name value role aria-label"]),
        .init(id: "css", name: "CSS", lexer: "css", extensions: ["css", "scss", "less"], keywords: ["important inherit initial unset auto none block flex grid inline inline-block absolute relative fixed sticky center cover contain"]),
        .init(id: "json", name: "JSON", lexer: "json", extensions: ["json", "jsonc", "jsonl"], keywords: []),
        .init(id: "xml", name: "XML", lexer: "xml", extensions: ["xml", "xsd", "xsl", "plist", "svg"], keywords: ["xml version encoding xmlns xmlns:xsi xsi:schemaLocation"]),
        .init(id: "sql", name: "SQL", lexer: "sql", extensions: ["sql"], keywords: ["add all alter and any as asc backup between by case check column constraint create database default delete desc distinct drop exec exists foreign from full join group index inner insert into is join key left like limit not null on or order outer primary procedure references right row select set table top truncate union unique update values view where", "bigint binary bit char date datetime decimal int integer money nchar numeric nvarchar real smallint text time timestamp tinyint uniqueidentifier varchar"])
    ]

    static func detect(url: URL?) -> LanguageMode {
        guard let ext = url?.pathExtension.lowercased(), !ext.isEmpty else { return all[0] }
        return all.first { $0.extensions.contains(ext) } ?? all[0]
    }
}

@main
struct CodePadApp: App {
    @StateObject private var store = EditorStore()
    @NSApplicationDelegateAdaptor(CodePadAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup(id: "main") {
            CodePadWindow(appDelegate: appDelegate)
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
final class CodePadAppDelegate: NSObject, NSApplicationDelegate {
    var reopenWindow: (() -> Void)?

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        guard !hasVisibleWindows, let reopenWindow else { return true }
        sender.activate(ignoringOtherApps: true)
        reopenWindow()
        return false
    }
}

@MainActor
final class EditorDocument: ObservableObject, Identifiable {
    let id = UUID()
    @Published var text: String {
        didSet { isDirty = text != savedText }
    }
    @Published var isDirty = false
    @Published var languageMode: LanguageMode
    var url: URL?
    private var savedText: String

    init(text: String = "", url: URL? = nil) {
        self.text = text
        self.savedText = text
        self.url = url
        self.languageMode = LanguageMode.detect(url: url)
    }

    var title: String { url?.lastPathComponent ?? "Untitled" }
    var lineCount: Int { max(1, text.reduce(into: 1) { if $1 == "\n" { $0 += 1 } }) }
    func markSaved(at newURL: URL? = nil) {
        if let newURL, url != newURL {
            url = newURL
            languageMode = LanguageMode.detect(url: newURL)
        }
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
    let appDelegate: CodePadAppDelegate
    @EnvironmentObject private var store: EditorStore
    @Environment(\.openWindow) private var openWindow
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
        .onAppear {
            appDelegate.reopenWindow = { openWindow(id: "main") }
        }
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
            Menu {
                ForEach(LanguageMode.all) { mode in
                    Button {
                        document.languageMode = mode
                    } label: {
                        if document.languageMode.id == mode.id {
                            Label(mode.name, systemImage: "checkmark")
                        } else {
                            Text(mode.name)
                        }
                    }
                }
            } label: {
                Label(document.languageMode.name, systemImage: "chevron.up.chevron.down")
            }
            .menuStyle(.borderlessButton)
            Text("UTF-8")
            Text("\(document.lineCount) lines")
            Spacer()
            if document.isDirty { Text("Modified").foregroundStyle(.orange) }
            Text(document.url?.lastPathComponent ?? "Unsaved")
                .lineLimit(1)
            Label("Ln \(editorController.cursorLine), Col \(editorController.cursorColumn)", systemImage: "textformat.123")
                .monospacedDigit()
                .help("Current line and column")
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
        NativeTextEditor(text: $document.text, mode: document.languageMode, controller: controller)
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
    weak var scintillaView: CodePadScintillaView?
    @Published private(set) var cursorLine = 1
    @Published private(set) var cursorColumn = 1

    func updateCursorPosition(line: Int, column: Int) {
        cursorLine = max(1, line)
        cursorColumn = max(1, column)
    }

    func findNext(_ query: String) { scintillaView?.find(query, backwards: false) }
    func findPrevious(_ query: String) { scintillaView?.find(query, backwards: true) }

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
}

struct NativeTextEditor: NSViewRepresentable {
    @Binding var text: String
    let mode: LanguageMode
    @ObservedObject var controller: EditorController

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> CodePadScintillaView {
        let editor = CodePadScintillaView(frame: .zero)
        editor.lexerName = mode.lexer
        editor.keywordSets = mode.keywords
        editor.text = text
        editor.onChange = { [weak coordinator = context.coordinator] editedText, line, column, _ in
            coordinator?.editorDidChange(text: editedText, line: line, column: column)
        }
        controller.scintillaView = editor
        return editor
    }

    func updateNSView(_ editor: CodePadScintillaView, context: Context) {
        let coordinator = context.coordinator
        // The view is reused when the active tab changes, so the callback must follow
        // the current binding instead of the document that created the view.
        coordinator.parent = self
        coordinator.isUpdatingFromView = true
        defer { coordinator.isUpdatingFromView = false }
        controller.scintillaView = editor
        if editor.text != text { editor.text = text }
        if editor.lexerName != mode.lexer { editor.lexerName = mode.lexer }
        if editor.keywordSets != mode.keywords { editor.keywordSets = mode.keywords }
    }

    final class Coordinator: NSObject {
        var parent: NativeTextEditor
        var isUpdatingFromView = false

        init(_ parent: NativeTextEditor) { self.parent = parent }

        func editorDidChange(text editedText: String, line: Int, column: Int) {
            // Notifications fired while loading a document (text or lexer assignment)
            // describe the old contents and must not overwrite the incoming document.
            guard !isUpdatingFromView else { return }
            if parent.text != editedText {
                parent.text = editedText
            }
            let controller = parent.controller
            DispatchQueue.main.async {
                controller.updateCursorPosition(line: line, column: column)
            }
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
