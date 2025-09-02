//
//  formatDescription.swift
//  rssGenerator
//
//  Created by Justin Purnell on 9/2/25.
//

import Foundation
import Markdown

func formatDescription(_ description: String) -> String {
	// Convert Markdown to HTML
	let htmlDescription = Markdown.HTMLBlock(description).rawHTML// Assumes a MarkdownParser is available
	let unescapedHTML = unescapeHTML(htmlDescription)
	
	// Wrap in CDATA
	var wrappedDescription = "<![CDATA[\(unescapedHTML)]]>"
	
	// Handle byte limit
	let byteLimit = 4000
	if let utf8Data = wrappedDescription.data(using: .utf8) {
		if utf8Data.count > byteLimit {
			let contentLength = byteLimit - "<![CDATA[]]>".utf8.count
			if contentLength > 0 {
				var truncatedContent = unescapedHTML.prefix(contentLength)
				
				// Avoid breaking HTML tags
				if let lastTagStart = truncatedContent.lastIndex(of: "<"),
				   let lastTagEnd = truncatedContent.lastIndex(of: ">") {
					if lastTagStart > lastTagEnd {
						truncatedContent = truncatedContent.prefix(upTo: lastTagStart)
					}
				}
				
				wrappedDescription = "<![CDATA[\(truncatedContent)]]>"
			}
		}
	}

	return wrappedDescription
}

// Helper function to unescape HTML entities
func unescapeHTML(_ html: String) -> String {
	return html.replacingOccurrences(of: "&amp;", with: "&")
				.replacingOccurrences(of: "&lt;", with: "<")
				.replacingOccurrences(of: "&gt;", with: ">")
				.replacingOccurrences(of: "&quot;", with: "\"")
				.replacingOccurrences(of: "&apos;", with: "'")
}
