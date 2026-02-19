//
//  String+extensions.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 15/02/2026.
//


extension String {
    /// Returns `true` if the string is empty or contains only whitespaces.
    public var isVisuallyEmpty: Bool {
        self.isEmpty || self.allSatisfy { $0.isWhitespace }
    }
    
    public func toSnakeCase(splitCharacter: Character = "_") -> String {
        guard !self.isEmpty else { return self }
        
        var result = ""
        
        for (index, char) in self.enumerated() {
            if char.isUppercase && index > 0 {
                result.append(splitCharacter)
            }
            result += char.lowercased()
        }
        return result
    }
}
