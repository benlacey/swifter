//
//  File.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

public enum FileError: ErrorType {
    case OpenFailed(String)
    case WriteFailed(String)
    case ReadFailed(String)
}

public class File {
    
    public static func openNewForWriting(path: String) throws -> File {
        return try openFileForMode(path, "wb")
    }
    
    public static func openForReading(path: String) throws -> File {
        return try openFileForMode(path, "rb")
    }
    
    public static func openForWritingAndReading(path: String) throws -> File {
        return try openFileForMode(path, "r+b")
    }
    
    public static func openFileForMode(path: String, _ mode: String) throws -> File {
        let file = fopen(path.withCString({ $0 }), mode.withCString({ $0 }))
        guard file != nil else {
            throw FileError.OpenFailed(descriptionOfLastError())
        }
        return File(file)
    }
    
    private let pointer: UnsafeMutablePointer<FILE>
    
    public init(_ pointer: UnsafeMutablePointer<FILE>) {
        self.pointer = pointer
    }
    
    public func close() -> Void {
        fclose(pointer)
    }
    
    public func read(inout data: [UInt8]) throws -> Int {
        if data.count <= 0 {
            return data.count
        }
        let count = fread(&data, 1, data.count, self.pointer)
        if count == data.count {
            return count
        }
        if feof(self.pointer) != 0 {
            return count
        }
        if ferror(self.pointer) != 0 {
            throw FileError.ReadFailed(File.descriptionOfLastError())
        }
        throw FileError.ReadFailed("Unknown file read error occured.")
    }

    public func write(data: [UInt8]) throws -> Void {
        if data.count <= 0 {
            return
        }
        try data.withUnsafeBufferPointer {
            if fwrite($0.baseAddress, 1, data.count, self.pointer) != data.count {
                throw FileError.WriteFailed(File.descriptionOfLastError())
            }
        }
    }
    
    private static func descriptionOfLastError() -> String {
        return String.fromCString(UnsafePointer(strerror(errno))) ?? "Error: \(errno)"
    }
}

extension File {
    
    public static func withNewFileOpenedForWriting<Result>(path: String, _ f: File throws -> Result) throws -> Result {
        return try withFileOpenedForMode(path, mode: "wb", f)
    }
    
    public static func withFileOpenedForReading<Result>(path: String, _ f: File throws -> Result) throws -> Result {
        return try withFileOpenedForMode(path, mode: "rb", f)
    }
    
    public static func withFileOpenedForWritingAndReading<Result>(path: String, _ f: File throws -> Result) throws -> Result {
        return try withFileOpenedForMode(path, mode: "r+b", f)
    }
    
    public static func withFileOpenedForMode<Result>(path: String, mode: String, _ f: File throws -> Result) throws -> Result {
        let file = try File.openFileForMode(path, mode)
        defer {
            file.close()
        }
        return try f(file)
    }
}