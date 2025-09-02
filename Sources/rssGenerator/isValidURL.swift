//
//  isValidURL.swift
//  rssGenerator
//
//  Created by Justin Purnell on 9/2/25.
//

import Foundation
import OSLog

func isValidURL(_ url: String) -> Bool {
	let logger = Logger(subsystem: #function, category: Subsystems.app)
	// Attempt to create a URL object from the string
	guard let urlComponents = URLComponents(string: url) else {
		logger.error("Failed to create URL from string: \(url)")
		return false // The string didn't result in a valid URL
	}

	// Check if the scheme and host are not nil, which indicates it's a valid URL
	return urlComponents.scheme != nil && urlComponents.host != nil
}
