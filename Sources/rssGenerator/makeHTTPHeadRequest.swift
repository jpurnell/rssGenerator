//
//  makeHttpRequest.swift
//  rssGenerator
//
//  Created by Justin Purnell on 9/2/25.
//

import Foundation
import OSLog

enum HTTPRequestError: Error {
	case requestFailed
}

func makeHTTPHeadRequest(url: String, retries: Int = 5, delay: TimeInterval = 2) async throws -> URLResponse {
	let logger = Logger(subsystem: #function, category: Subsystems.app)
	guard let requestURL = URL(string: url) else {
		logger.error("Invalid URL")
		throw HTTPRequestError.requestFailed // Invalid URL
	}

	var attempts = 0

	let request = URLRequest(url: requestURL)
	var response: URLResponse?
	
	while attempts < retries {
		do {
			let (_, urlResponse) = try await URLSession.shared.data(for: request)
			response = urlResponse // Successful request
			return response! // Return the response
		} catch {
			attempts += 1
			if attempts >= retries {
				throw HTTPRequestError.requestFailed // All retries failed
			}
			logger.error("Request failed (attempt \(attempts)/\(retries)), retrying in \(delay) seconds...")
			print("Request failed (attempt \(attempts)/\(retries)), retrying in \(delay) seconds...")
			try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) // Sleep for the specified delay
		}
	}

	throw HTTPRequestError.requestFailed // Should not reach here
}
