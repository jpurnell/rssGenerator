//
//  isValidEmail.swift
//  rssGenerator
//
//  Created by Justin Purnell on 9/2/25.
//

import Foundation
import OSLog

func isValidEmail(_ email: String) -> Bool {
	let logger = Logger(subsystem: #function, category: Subsystems.app)
	// Define the regular expression pattern for a valid email
	let emailPattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"

	// Create an instance of NSRegularExpression
	guard let regex = try? NSRegularExpression(pattern: emailPattern) else {
		logger.error("Invalid regex pattern")
		return false // The regex pattern is invalid
	}

	// Check if the email matches the regex pattern
	let range = NSRange(location: 0, length: email.utf16.count)
	return regex.firstMatch(in: email, options: [], range: range) != nil
}
