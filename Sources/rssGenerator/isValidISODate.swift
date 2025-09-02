//
//  isValidISODate.swift
//  rssGenerator
//
//  Created by Justin Purnell on 9/2/25.
//

import Foundation

func isValidISODate(_ dateString: String) -> Bool {
	// Create a DateFormatter instance
	let dateFormatter = DateFormatter()
	dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // Specify the expected format
	dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Set locale to POSIX for consistency
	
	// Replace 'Z' with '+0000' if needed for validation, so it conforms to the expected format
	let formattedDateString = dateString.replacingOccurrences(of: "Z", with: "+0000")

	// Attempt to parse the date
	return dateFormatter.date(from: formattedDateString) != nil
}
