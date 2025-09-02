//
//  convertISOToRFC2822.swift
//  rssGenerator
//
//  Created by Justin Purnell on 9/2/25.
//

import Foundation

func convertISOToRFC2822(_ isoDate: String) -> String? {
	// Create a DateFormatter instance for parsing the ISO date
	let isoFormatter = ISO8601DateFormatter()
	
	// Replace 'Z' with 'Z' as it will be handled correctly by ISO8601DateFormatter
	let compatibleISODate = isoDate.replacingOccurrences(of: "Z", with: "+0000")
	
	// Parse the date from the ISO string
	guard let date = isoFormatter.date(from: compatibleISODate) else {
		return nil // Return nil if parsing fails
	}
	
	// Create a DateFormatter for RFC 2822 format
	let rfcFormatter = DateFormatter()
	rfcFormatter.locale = Locale(identifier: "en_US_POSIX") // Set locale to ensure consistent parsing
	rfcFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z" // RFC 2822 format
	
	// Convert the date to RFC 2822 format
	return rfcFormatter.string(from: date)
}
