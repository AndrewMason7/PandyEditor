import Foundation
import UIKit
import FiveKit

//
//  SyntaxLanguages.swift
//  PandyEditor 🐼
//
//  Defines the SyntaxLanguage protocol and concrete implementations for each
//  supported programming language. Contains regex patterns for:
//  - Keywords (func, var, let, class, etc.)
//  - Strings (single, double, template literals)
//  - Comments (single-line, multi-line)
//  - Numbers (integers, floats, hex)
//  - Function calls
//
//  ADDING A NEW LANGUAGE:
//  1. Create a struct conforming to SyntaxLanguage
//  2. Add a case to SupportedLanguage enum
//  3. Add file extensions to detect() function
//


// MARK: - Syntax Language Protocol
public protocol SyntaxLanguage {
    var keywords: [String] { get }
    var builtins: [String] { get }
    var singleLineCommentPattern: String { get }
    var multiLineCommentPattern: String? { get }
    var stringPatterns: [String] { get }
    var numberPattern: String { get }
    var functionCallPattern: String { get }
}

// MARK: - JavaScript Syntax
internal struct JavaScriptSyntax: SyntaxLanguage {
    let keywords = [
        "async", "await", "break", "case", "catch", "class", "const", "continue",
        "debugger", "default", "delete", "do", "else", "export", "extends", "false",
        "finally", "for", "function", "if", "import", "in", "instanceof", "let",
        "new", "null", "return", "static", "super", "switch", "this", "throw",
        "true", "try", "typeof", "undefined", "var", "void", "while", "with", "yield"
    ]
    
    let builtins = [
        "console", "document", "window", "alert", "setTimeout", "setInterval",
        "clearTimeout", "clearInterval", "fetch", "JSON", "Math", "Array",
        "Object", "String", "Number", "Boolean", "Date", "RegExp", "Promise",
        "localStorage", "sessionStorage", "navigator", "location", "history"
    ]
    
    let singleLineCommentPattern = "//.*$"
    let multiLineCommentPattern: String? = "/\\*[\\s\\S]*?\\*/"
    let stringPatterns = [
        "\"(?:[^\"\\\\]|\\\\.)*\"", // Double quotes
        "'(?:[^'\\\\]|\\\\.)*'",     // Single quotes
        "`(?:[^`\\\\]|\\\\.)*`"      // Template literals
    ]
    let numberPattern = "\\b\\d+\\.?\\d*\\b"
    let functionCallPattern = "\\b([a-zA-Z_$][a-zA-Z0-9_$]*)\\s*\\("
}

// MARK: - TypeScript Syntax (New)
internal struct TypeScriptSyntax: SyntaxLanguage {
    // JS keywords + TS specifics
    let keywords = [
        "async", "await", "break", "case", "catch", "class", "const", "continue",
        "debugger", "default", "delete", "do", "else", "export", "extends", "false",
        "finally", "for", "function", "if", "import", "in", "instanceof", "let",
        "new", "null", "return", "static", "super", "switch", "this", "throw",
        "true", "try", "typeof", "undefined", "var", "void", "while", "with", "yield",
        // TypeScript Specific
        "interface", "type", "namespace", "enum", "implements", "declare", "abstract",
        "public", "private", "protected", "readonly", "as", "any", "number", "string",
        "boolean", "symbol", "never", "unknown", "keyof", "is"
    ]
    
    let builtins = [
        "console", "document", "window", "Promise", "Map", "Set", "Array", "Object",
        "JSON", "Math", "Require", "module", "exports", "Partial", "Readonly",
        "Record", "Pick", "Omit", "Exclude", "Extract", "NonNullable"
    ]
    
    let singleLineCommentPattern = "//.*$"
    let multiLineCommentPattern: String? = "/\\*[\\s\\S]*?\\*/"
    let stringPatterns = [
        "\"(?:[^\"\\\\]|\\\\.)*\"",
        "'(?:[^'\\\\]|\\\\.)*'",
        "`(?:[^`\\\\]|\\\\.)*`"
    ]
    let numberPattern = "\\b\\d+\\.?\\d*\\b"
    let functionCallPattern = "\\b([a-zA-Z_$][a-zA-Z0-9_$]*)\\s*\\("
}

// MARK: - Swift Syntax
internal struct SwiftSyntax: SyntaxLanguage {
    let keywords = [
        "actor", "async", "await", "break", "case", "catch", "class", "continue",
        "default", "defer", "deinit", "do", "else", "enum", "extension", "fallthrough",
        "fileprivate", "for", "func", "guard", "if", "import", "in", "init", "inout",
        "internal", "is", "let", "nil", "operator", "private", "protocol", "public",
        "repeat", "rethrows", "return", "self", "static", "struct", "subscript", "super",
        "switch", "throw", "throws", "try", "typealias", "var", "where", "while"
    ]
    
    let builtins = [
        "print", "fatalError", "assert", "assertionFailure", "precondition",
        "String", "Int", "Double", "Float", "Bool", "Array", "Dictionary", "Set",
        "OptionSet", "Result", "Error", "Codable", "Decodable", "Encodable", "Task",
        "MainActor", "Published", "State", "Binding", "Environment"
    ]
    
    let singleLineCommentPattern = "//.*$"
    let multiLineCommentPattern: String? = "/\\*[\\s\\S]*?\\*/"
    let stringPatterns = [
        "\"(?:[^\"\\\\]|\\\\.)*\"",
        "\"\"\"[\\s\\S]*?\"\"\"" // Multiline
    ]
    let numberPattern = "\\b\\d+[\\d_]*(\\.?[\\d_]*)?\\b"
    let functionCallPattern = "\\b([a-zA-Z_$][a-zA-Z0-9_$]*)\\s*\\("
}

// MARK: - Python Syntax
internal struct PythonSyntax: SyntaxLanguage {
    let keywords = [
        "False", "None", "True", "and", "as", "assert", "async", "await", "break",
        "class", "continue", "def", "del", "elif", "else", "except", "finally",
        "for", "from", "global", "if", "import", "in", "is", "lambda", "nonlocal",
        "not", "or", "pass", "raise", "return", "try", "while", "with", "yield",
        "match", "case"
    ]
    
    let builtins = [
        "print", "len", "range", "str", "int", "float", "bool", "list", "dict",
        "set", "tuple", "type", "isinstance", "hasattr", "getattr", "setattr",
        "open", "input", "map", "filter", "reduce", "zip", "enumerate", "sorted",
        "reversed", "min", "max", "sum", "abs", "round", "pow", "divmod", "hex",
        "oct", "bin", "chr", "ord", "format", "repr", "eval", "exec", "compile",
        "super", "object", "staticmethod", "classmethod", "property"
    ]
    
    let singleLineCommentPattern = "#.*$"
    let multiLineCommentPattern: String? = "'''[\\s\\S]*?'''|\"\"\"[\\s\\S]*?\"\"\""
    let stringPatterns = [
        "\"(?:[^\"\\\\]|\\\\.)*\"",
        "'(?:[^'\\\\]|\\\\.)*'",
        "'''[\\s\\S]*?'''",
        "\"\"\"[\\s\\S]*?\"\"\""
    ]
    let numberPattern = "\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b"
    let functionCallPattern = "\\b([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\("
}

// MARK: - Go Syntax (New)
internal struct GoSyntax: SyntaxLanguage {
    let keywords = [
        "break", "case", "chan", "const", "continue", "default", "defer", "else",
        "fallthrough", "for", "func", "go", "goto", "if", "import", "interface",
        "map", "package", "range", "return", "select", "struct", "switch", "type",
        "var", "true", "false", "nil", "iota"
    ]
    
    let builtins = [
        "append", "cap", "close", "complex", "copy", "delete", "imag", "len",
        "make", "new", "panic", "print", "println", "real", "recover",
        "bool", "byte", "complex64", "complex128", "error", "float32", "float64",
        "int", "int8", "int16", "int32", "int64", "rune", "string",
        "uint", "uint8", "uint16", "uint32", "uint64", "uintptr"
    ]
    
    let singleLineCommentPattern = "//.*$"
    let multiLineCommentPattern: String? = "/\\*[\\s\\S]*?\\*/"
    let stringPatterns = [
        "\"(?:[^\"\\\\]|\\\\.)*\"", // Double quotes
        "`[^`]*`"                    // Raw string backticks
    ]
    let numberPattern = "\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b"
    let functionCallPattern = "\\b([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\("
}

// MARK: - Rust Syntax (New)
internal struct RustSyntax: SyntaxLanguage {
    let keywords = [
        "as", "break", "const", "continue", "crate", "else", "enum", "extern",
        "false", "fn", "for", "if", "impl", "in", "let", "loop", "match", "mod",
        "move", "mut", "pub", "ref", "return", "self", "Self", "static", "struct",
        "super", "trait", "true", "type", "unsafe", "use", "where", "while",
        "async", "await", "dyn", "box"
    ]
    
    let builtins = [
        "println!", "format!", "panic!", "vec!", "Some", "None", "Ok", "Err",
        "String", "Vec", "Option", "Result", "Box", "Rc", "Arc", "u8", "u16",
        "u32", "u64", "i8", "i16", "i32", "i64", "f32", "f64", "bool", "usize", "isize"
    ]
    
    let singleLineCommentPattern = "//.*$"
    let multiLineCommentPattern: String? = "/\\*[\\s\\S]*?\\*/"
    let stringPatterns = [
        "\"(?:[^\"\\\\]|\\\\.)*\"",
        "'(?:[^'\\\\]|\\\\.)*'" // Lifetime or Char literal
    ]
    let numberPattern = "\\b\\d+[\\d_]*(\\.[\\d_]*)?\\b"
    let functionCallPattern = "\\b([a-zA-Z_][a-zA-Z0-9_]*!?)\\s*\\(" // Handles macros
}

// MARK: - SQL Syntax (New)
internal struct SQLSyntax: SyntaxLanguage {
    // Note: SQL is typically case-insensitive, but our regex engine targets these exact casings.
    let keywords = [
        "SELECT", "FROM", "WHERE", "INSERT", "INTO", "VALUES", "UPDATE", "SET",
        "DELETE", "CREATE", "TABLE", "DROP", "ALTER", "INDEX", "VIEW", "ORDER",
        "BY", "GROUP", "HAVING", "LIMIT", "OFFSET", "INNER", "LEFT", "RIGHT",
        "JOIN", "ON", "AS", "DISTINCT", "NULL", "TRUE", "FALSE", "AND", "OR",
        "NOT", "IN", "IS", "EXISTS", "BETWEEN", "LIKE", "UNION", "ALL",
        "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "DEFAULT", "CONSTRAINT",
        "BEGIN", "COMMIT", "ROLLBACK", "TRANSACTION", "GRANT", "REVOKE"
    ]
    
    let builtins = [
        "COUNT", "SUM", "AVG", "MIN", "MAX", "UPPER", "LOWER", "LENGTH",
        "NOW", "DATE", "COALESCE", "CAST", "ROUND", "CONCAT", "SUBSTRING",
        "REPLACE", "TRIM", "ABS", "CEILING", "FLOOR", "POWER", "SQRT"
    ]
    
    let singleLineCommentPattern = "--.*$"
    let multiLineCommentPattern: String? = "/\\*[\\s\\S]*?\\*/"
    let stringPatterns = [
        "'(?:[^'\\\\]|\\\\.)*'", // Standard SQL strings are single quotes
        "\"(?:[^\"\\\\]|\\\\.)*\"" // Identifiers in some dialects
    ]
    let numberPattern = "\\b\\d+(\\.\\d+)?\\b"
    let functionCallPattern = "\\b([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\("
}

// MARK: - CSS Syntax
internal struct CSSSyntax: SyntaxLanguage {
    let keywords = [
        "!important", "@import", "@media", "@keyframes", "@font-face", "@charset",
        "@supports", "@page", "@namespace", "@viewport", "@counter-style",
        "from", "to", "inherit", "initial", "unset", "revert", "auto", "none"
    ]
    
    let builtins = [
        "display", "position", "top", "right", "bottom", "left", "width", "height",
        "margin", "padding", "border", "background", "color", "font", "text",
        "flex", "grid", "align", "justify", "transform", "transition", "animation",
        "opacity", "visibility", "overflow", "z-index", "cursor", "box-shadow",
        "flex", "block", "inline", "grid", "absolute", "relative", "fixed", "sticky",
        "center", "space-between", "space-around", "stretch", "row", "column"
    ]
    
    let singleLineCommentPattern = "//.*$" // Non-standard but common in SCSS/Less
    let multiLineCommentPattern: String? = "/\\*[\\s\\S]*?\\*/"
    let stringPatterns = [
        "\"(?:[^\"\\\\]|\\\\.)*\"",
        "'(?:[^'\\\\]|\\\\.)*'"
    ]
    let numberPattern = "-?\\d+(\\.\\d+)?(px|em|rem|%|vh|vw|deg|s|ms)?\\b"
    let functionCallPattern = "([a-zA-Z-]+)\\s*\\("
}

// MARK: - HTML Syntax
internal struct HTMLSyntax: SyntaxLanguage {
    let keywords = [
        "DOCTYPE", "html", "head", "body", "title", "meta", "link", "script", "style",
        "div", "span", "p", "a", "img", "ul", "ol", "li", "table", "tr", "td", "th",
        "form", "input", "button", "select", "option", "textarea", "label",
        "header", "footer", "nav", "main", "section", "article", "aside",
        "h1", "h2", "h3", "h4", "h5", "h6", "br", "hr", "pre", "code",
        "strong", "em", "b", "i", "u", "sub", "sup", "blockquote", "iframe", "svg"
    ]
    
    let builtins = [
        "id", "class", "style", "href", "src", "alt", "title", "type", "name",
        "value", "placeholder", "disabled", "readonly", "required", "checked",
        "data", "aria", "role", "tabindex", "target", "rel", "action", "method",
        "width", "height", "colspan", "rowspan"
    ]
    
    let singleLineCommentPattern = "(?!x)x" // HTML uses multiline format only
    let multiLineCommentPattern: String? = "<!--[\\s\\S]*?-->"
    let stringPatterns = [
        "\"(?:[^\"\\\\]|\\\\.)*\"",
        "'(?:[^'\\\\]|\\\\.)*'"
    ]
    let numberPattern = "\\b\\d+(\\.\\d+)?\\b"
    let functionCallPattern = "</?([ a-zA-Z][a-zA-Z0-9]*)" // Tags
}

// MARK: - JSON Syntax
internal struct JSONSyntax: SyntaxLanguage {
    let keywords = ["true", "false", "null"]
    let builtins: [String] = []
    let singleLineCommentPattern = "(?!x)x"
    let multiLineCommentPattern: String? = nil
    let stringPatterns = [
        "\"(?:[^\"\\\\]|\\\\.)*\""
    ]
    let numberPattern = "-?\\d+(\\.\\d+)?([eE][+-]?\\d+)?"
    let functionCallPattern = "\"([^\"]+)\"\\s*:" // Keys
}

// MARK: - Plain Text Syntax
internal struct PlainTextSyntax: SyntaxLanguage {
    let keywords: [String] = []
    let builtins: [String] = []
    let singleLineCommentPattern = "(?!x)x"
    let multiLineCommentPattern: String? = nil
    let stringPatterns: [String] = []
    let numberPattern = "(?!x)x"
    let functionCallPattern = "(?!x)x"
}

// MARK: - Supported Language Enum
public enum SupportedLanguage: String, CaseIterable {
    case plainText = "Plain Text" // New Default
    case javascript = "JavaScript"
    case typescript = "TypeScript"
    case swift = "Swift"
    case python = "Python"
    case go = "Go"
    case rust = "Rust"
    case sql = "SQL"
    case css = "CSS"
    case html = "HTML"
    case json = "JSON"
    
    var syntax: SyntaxLanguage {
        switch self {
        case .plainText: return PlainTextSyntax()
        case .javascript: return JavaScriptSyntax()
        case .typescript: return TypeScriptSyntax()
        case .swift: return SwiftSyntax()
        case .python: return PythonSyntax()
        case .go: return GoSyntax()
        case .rust: return RustSyntax()
        case .sql: return SQLSyntax()
        case .css: return CSSSyntax()
        case .html: return HTMLSyntax()
        case .json: return JSONSyntax()
        }
    }
    
    var icon: String {
        switch self {
        case .plainText: return "doc.text"
        case .javascript: return "doc.text.fill"
        case .typescript: return "t.square.fill"
        case .swift: return "swift"
        case .python: return "terminal.fill"
        case .go: return "g.circle.fill"
        case .rust: return "gearshape.fill"
        case .sql: return "cylinder.split.1x2.fill"
        case .css: return "paintbrush.fill"
        case .html: return "chevron.left.forwardslash.chevron.right"
        case .json: return "curlybraces"
        }
    }
    
    /// Auto-detect language from file extension
    public static func detect(from filename: String) -> SupportedLanguage {
        // Use FoundationPlus path extension logic
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "txt", "text", "md": return .plainText
        case "js", "jsx", "mjs", "cjs": return .javascript
        case "ts", "tsx": return .typescript
        case "swift": return .swift
        case "py", "pyw": return .python
        case "go": return .go
        case "rs", "rlib": return .rust
        case "sql": return .sql
        case "css", "scss", "sass", "less": return .css
        case "html", "htm", "xhtml": return .html
        case "json": return .json
        default: return .plainText // Default to Plain Text
        }
    }
}