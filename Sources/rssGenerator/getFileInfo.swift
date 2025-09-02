//
//  getFileInfo.swift
//  rssGenerator
//
//  Created by Justin Purnell on 9/2/25.
//

import Foundation
import OSLog

// Define a struct to hold file information
struct FileInfo {
	var contentLength: String?
	var contentType: String?
	var duration: Int?
	var contentHash: String?
}

func makeHTTPHeadRequest(url: String) async throws -> URLResponse {
	guard let requestURL = URL(string: url) else {
		throw NSError(domain: "InvalidURL", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
	}
	
	var request = URLRequest(url: requestURL)
	request.httpMethod = "HEAD"
	
	return try await URLSession.shared.data(for: request).1
}

func getFFPRobeLocation() throws -> String? {
	let logger = Logger(subsystem: #function, category: Subsystems.app)
	let process = Process()
	let outputPipe = Pipe()
	
	process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
	process.arguments = ["ffprobe"]
	process.standardOutput = outputPipe
	var ffprobeLocation = ""
	do {
		try process.run()
		process.waitUntilExit()
		
		let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
		ffprobeLocation = String(data: data, encoding: .utf8) ?? ""
		logger.info("found path for ffprobe at \(ffprobeLocation, privacy: .public)")
	} catch {
		logger.error("ffprobe not found on system")
		print("FFProbe not installed on your system. Can be installed via Homebrew: 'brew install ffprobe'")
	}
	return ffprobeLocation
}

func runFFProbe(url: String) throws -> String {
	let logger = Logger(subsystem: #function, category: Subsystems.app)
	let process = Process()
	let outputPipe = Pipe()
	
	// MARK: - Note that this requires ffprobe to be installed in your system. If you install via homebrew, this is the likely path, but you can substitute the output of $(which ffprobe) to find it on your machine
	process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin//ffprobe") // Make sure this path is correct
	process.arguments = [
		"-hide_banner",
		"-v", "quiet",
		"-show_streams",
		"-print_format", "flat",
		url
	]
	process.standardOutput = outputPipe

	do {
		try process.run()
		process.waitUntilExit()
		
		let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
		return String(data: data, encoding: .utf8) ?? ""
	} catch {
		logger.error("Failed to run ffprobe: \(error.localizedDescription)")
		throw error
	}
}

func getFileInfo(url: String) async throws -> FileInfo {
	// Make the HTTP HEAD request
	let response = try await makeHTTPHeadRequest(url: url)

	// Get the file information using ffprobe
	let probeOutput = try runFFProbe(url: url)

	// Parse ffprobe output
	var duration: Int? = nil
	let lines = probeOutput.split(separator: "\n")
	for line in lines {
		if line.starts(with: "streams.stream.0.duration=") {
			if let value = line.split(separator: "=").last?
				.trimmingCharacters(in: .whitespacesAndNewlines)
				.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) {
				duration = Int(Double(value) ?? 0.0)
			}
			break
		}
	}

	// Extract content hash from headers
	var contentHash: String? = nil
	let httpResponse = response as? HTTPURLResponse
	let headers = httpResponse?.allHeaderFields
	
	if let sha256Hash = headers?["x-amz-checksum-sha256"] as? String {
		contentHash = "sha256:\(sha256Hash)"
	} else if let gcsHash = headers?["x-goog-hash"] as? String {
		if let match = gcsHash.range(of: "md5=([^,]+)", options: .regularExpression) {
			let md5Value = gcsHash[match]
			contentHash = "md5:\(md5Value)"
		}
	} else if let etag = headers?["ETag"] as? String {
		contentHash = "etag:\(etag.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\"")))"
	}

	return FileInfo(
		contentLength: httpResponse?.value(forHTTPHeaderField: "Content-Length"),
		contentType: httpResponse?.value(forHTTPHeaderField: "Content-Type"),
		duration: duration,
		contentHash: contentHash
	)
}
