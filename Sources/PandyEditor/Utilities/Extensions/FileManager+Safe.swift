import Foundation
import FiveKit

// MARK: - Safe FileManager Operations
/// Safe file system operations with crash prevention.
extension FileManager {
    
    /// Safely check if file exists.
    func safeFileExists(atPath path: String) -> Bool {
        return CrashGuard.safely({ fileExists(atPath: path) }, fallback: false)
    }
    
    /// Safely get file size.
    func safeFileSize(at url: URL) -> Int64 {
        return CrashGuard.safely({
            let attrs = try attributesOfItem(atPath: url.path)
            return attrs[.size] as? Int64 ?? 0
        }, fallback: 0)
    }
    
    /// Safely create directory.
    func safeCreateDirectory(at url: URL) -> Bool {
        return CrashGuard.safely({
            try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return true
        }, fallback: false)
    }
    
    /// Safely copy file.
    func safeCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        return CrashGuard.safely({
            try copyItem(at: srcURL, to: dstURL)
            return true
        }, fallback: false)
    }
    
    /// Safely move file.
    func safeMoveItem(at srcURL: URL, to dstURL: URL) -> Bool {
        return CrashGuard.safely({
            try moveItem(at: srcURL, to: dstURL)
            return true
        }, fallback: false)
    }
    
    /// Safely delete file.
    func safeRemoveItem(at url: URL) -> Bool {
        return CrashGuard.safely({
            try removeItem(at: url)
            return true
        }, fallback: false)
    }
    
    /// Safely list directory contents.
    func safeContentsOfDirectory(at url: URL) -> [URL] {
        return CrashGuard.safely({
            try contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        }, fallback: [])
    }
}
