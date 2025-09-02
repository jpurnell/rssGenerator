//
//  escapeCDATA.swift
//  rssGenerator
//
//  Created by Justin Purnell on 9/2/25.
//

import Foundation

func escapeCDATA(_ text: String) -> String {
	// Escapes the '&' character in the text
	let escapedText = text.replacingOccurrences(of: "&", with: "&amp;")

	// Note: According to the XML specification, < and > should not be escaped in CDATA
	// Therefore, we leave < and > unchanged.

	return escapedText
}
