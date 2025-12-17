import XCTest
@testable import PandyEditor

final class PandyEditorTests: XCTestCase {
    
    // MARK: - Theme Registry Tests
    
    func testThemeRegistry() {
        // Verify themes are registered correctly
        let darkTheme = CodeEditorTheme.theme(named: "modernDark")
        XCTAssertEqual(darkTheme.name, "Modern Dark")
        
        let lightTheme = CodeEditorTheme.theme(named: "githubLight")
        XCTAssertEqual(lightTheme.name, "GitHub Light")
    }
    
    func testAllThemesAccessible() {
        // Verify all themes in registry are accessible
        let allThemes = CodeEditorTheme.allThemes
        XCTAssertEqual(allThemes.count, 9, "Expected 9 themes: 5 dark + 4 light")
        
        // Verify each theme has required properties
        for theme in allThemes {
            XCTAssertFalse(theme.name.isEmpty, "Theme name should not be empty")
        }
    }
    
    func testCatppuccinMochaIsPublic() {
        // Verify Catppuccin Mocha theme is accessible (regression test for public modifier)
        let theme = CodeEditorTheme.catppuccinMocha
        XCTAssertEqual(theme.name, "Catppuccin Mocha")
    }
    
    // MARK: - Syntax Detection Tests
    
    func testSyntaxDetection() {
        // Verify file extension detection
        XCTAssertEqual(SupportedLanguage.detect(from: "test.swift"), .swift)
        XCTAssertEqual(SupportedLanguage.detect(from: "index.js"), .javascript)
        XCTAssertEqual(SupportedLanguage.detect(from: "main.rs"), .rust)
    }
    
    func testAllFileExtensions() {
        // Comprehensive file extension mapping
        XCTAssertEqual(SupportedLanguage.detect(from: "file.txt"), .plainText)
        XCTAssertEqual(SupportedLanguage.detect(from: "README.md"), .plainText)
        XCTAssertEqual(SupportedLanguage.detect(from: "app.ts"), .typescript)
        XCTAssertEqual(SupportedLanguage.detect(from: "app.tsx"), .typescript)
        XCTAssertEqual(SupportedLanguage.detect(from: "script.py"), .python)
        XCTAssertEqual(SupportedLanguage.detect(from: "main.go"), .go)
        XCTAssertEqual(SupportedLanguage.detect(from: "query.sql"), .sql)
        XCTAssertEqual(SupportedLanguage.detect(from: "styles.css"), .css)
        XCTAssertEqual(SupportedLanguage.detect(from: "styles.scss"), .css)
        XCTAssertEqual(SupportedLanguage.detect(from: "index.html"), .html)
        XCTAssertEqual(SupportedLanguage.detect(from: "data.json"), .json)
    }
    
    func testUnknownExtensionDefaultsToPlainText() {
        XCTAssertEqual(SupportedLanguage.detect(from: "file.xyz"), .plainText)
        XCTAssertEqual(SupportedLanguage.detect(from: "noextension"), .plainText)
    }
    
    // MARK: - CrashGuard Tests
    
    func testSafeArrayIndex() {
        let array = ["a", "b", "c"]
        
        // Valid indices
        XCTAssertEqual(CrashGuard.safeIndex(array, 0), "a")
        XCTAssertEqual(CrashGuard.safeIndex(array, 2), "c")
        
        // Out of bounds
        XCTAssertNil(CrashGuard.safeIndex(array, -1))
        XCTAssertNil(CrashGuard.safeIndex(array, 3))
        XCTAssertNil(CrashGuard.safeIndex(array, 100))
    }
    
    func testSafeCharacter() {
        let text = "Hello"
        
        // Valid indices
        XCTAssertEqual(CrashGuard.safeCharacter(text, 0), "H")
        XCTAssertEqual(CrashGuard.safeCharacter(text, 4), "o")
        
        // Out of bounds
        XCTAssertNil(CrashGuard.safeCharacter(text, -1))
        XCTAssertNil(CrashGuard.safeCharacter(text, 5))
        XCTAssertNil(CrashGuard.safeCharacter(text, 100))
    }
    
    func testSafeCharacterEmptyString() {
        let empty = ""
        XCTAssertNil(CrashGuard.safeCharacter(empty, 0))
    }
    
    func testValidateRange() {
        let text = "Hello, World!"
        
        // Valid range
        let validRange = NSRange(location: 0, length: 5)
        XCTAssertNotNil(CrashGuard.validateRange(validRange, in: text))
        
        // Invalid ranges
        let outOfBounds = NSRange(location: 0, length: 100)
        XCTAssertNil(CrashGuard.validateRange(outOfBounds, in: text))
        
        let negativeLocation = NSRange(location: -1, length: 5)
        XCTAssertNil(CrashGuard.validateRange(negativeLocation, in: text))
        
        let notFound = NSRange(location: NSNotFound, length: 5)
        XCTAssertNil(CrashGuard.validateRange(notFound, in: text))
    }
    
    func testSafeSubstring() {
        let text = "Hello, World!"
        
        // Valid extraction
        let result = CrashGuard.safeSubstring(from: text, range: NSRange(location: 0, length: 5))
        XCTAssertEqual(result, "Hello")
        
        // Invalid extraction returns nil
        let invalid = CrashGuard.safeSubstring(from: text, range: NSRange(location: 0, length: 100))
        XCTAssertNil(invalid)
    }
    
    func testSafelyWithFallback() {
        // Successful execution
        let success = CrashGuard.safely({ return 42 }, fallback: 0)
        XCTAssertEqual(success, 42)
        
        // Fallback on error
        let failure = CrashGuard.safely({ throw NSError(domain: "test", code: 1) }, fallback: -1)
        XCTAssertEqual(failure, -1)
    }
    
    // MARK: - Validator Tests
    
    func testValidPath() {
        XCTAssertTrue(Validator.isValidPath("/Users/test/file.txt"))
        XCTAssertTrue(Validator.isValidPath("/tmp/safe/path"))
        
        // Dangerous paths
        XCTAssertFalse(Validator.isValidPath("../../../etc/passwd"))
        XCTAssertFalse(Validator.isValidPath("~/Documents"))
        XCTAssertFalse(Validator.isValidPath("/System/Library"))
        XCTAssertFalse(Validator.isValidPath(""))
    }
    
    func testValidFileName() {
        XCTAssertTrue(Validator.isValidFileName("document.txt"))
        XCTAssertTrue(Validator.isValidFileName("my-file_2023.swift"))
        
        // Invalid names
        XCTAssertFalse(Validator.isValidFileName(""))
        XCTAssertFalse(Validator.isValidFileName("file/name.txt"))
        XCTAssertFalse(Validator.isValidFileName("file:name.txt"))
        XCTAssertFalse(Validator.isValidFileName("file*name.txt"))
        
        // Too long
        let longName = String(repeating: "a", count: 256)
        XCTAssertFalse(Validator.isValidFileName(longName))
    }
    
    func testValidRange() {
        let text = "Hello"
        
        XCTAssertTrue(Validator.isValidRange(NSRange(location: 0, length: 5), in: text))
        XCTAssertTrue(Validator.isValidRange(NSRange(location: 2, length: 3), in: text))
        
        XCTAssertFalse(Validator.isValidRange(NSRange(location: NSNotFound, length: 0), in: text))
        XCTAssertFalse(Validator.isValidRange(NSRange(location: -1, length: 1), in: text))
        XCTAssertFalse(Validator.isValidRange(NSRange(location: 0, length: 10), in: text))
    }
    
    // MARK: - Safe Extension Tests
    
    func testArraySafeSubscript() {
        let array = [1, 2, 3]
        
        XCTAssertEqual(array[safe: 0], 1)
        XCTAssertEqual(array[safe: 2], 3)
        XCTAssertNil(array[safe: -1])
        XCTAssertNil(array[safe: 5])
    }
    
    func testStringSafeSubscript() {
        let text = "Swift"
        
        XCTAssertEqual(text[safe: 0], "S")
        XCTAssertEqual(text[safe: 4], "t")
        XCTAssertNil(text[safe: -1])
        XCTAssertNil(text[safe: 10])
    }
    
    func testArraySafePrefix() {
        let array = [1, 2, 3, 4, 5]
        
        XCTAssertEqual(array.safePrefix(3), [1, 2, 3])
        XCTAssertEqual(array.safePrefix(10), [1, 2, 3, 4, 5])
        XCTAssertEqual(array.safePrefix(0), [])
        XCTAssertEqual(array.safePrefix(-5), [])
    }
    
    // MARK: - SupportedLanguage Tests
    
    func testAllLanguagesHaveSyntax() {
        for language in SupportedLanguage.allCases {
            let syntax = language.syntax
            // Verify syntax protocol is properly implemented
            XCTAssertNotNil(syntax.singleLineCommentPattern)
            XCTAssertNotNil(syntax.numberPattern)
            XCTAssertNotNil(syntax.functionCallPattern)
        }
    }
    
    func testAllLanguagesHaveIcons() {
        for language in SupportedLanguage.allCases {
            XCTAssertFalse(language.icon.isEmpty, "\(language.rawValue) should have an icon")
        }
    }
}
