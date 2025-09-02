//
//  readPodcastConfig.swift
//  rssGenerator
//
//  Created by Justin Purnell on 9/2/25.
//

import Foundation
import Yams
import OSLog

func readPodcastConfig(yamlFilePath: String) throws -> [String: Any] {
	let logger = Logger(subsystem: #function, category: Subsystems.app)
	let fileUrl = URL(fileURLWithPath: yamlFilePath)

	// Read the contents of the YAML file as a string
	let yamlString = try String(contentsOf: fileUrl, encoding: .utf8)

	// Decode the YAML string into a Swift dictionary
	if let yamlDictionary = try Yams.load(yaml: yamlString) as? [String: Any] {
		return yamlDictionary
	} else {
		let error = NSError(domain: "InvalidYAMLFormat", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not parse YAML into dictionary."])
		logger.error("Error parsing YAML: \(error.localizedDescription)")
		throw error
	}
}
