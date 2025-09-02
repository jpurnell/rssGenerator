//
//  validateConfig.swift
//  rssGenerator
//
//  Created by Justin Purnell on 9/2/25.
//

import Foundation
import OSLog

enum PodcastConfigError: Error {
	case invalidConfig(String)
}

func validateConfig(_ config: [String: Any]) -> (isValid: Bool, errors: [String]) {
	let logger = Logger(subsystem: #function, category: Subsystems.app)
	var errors = [String]()

	// Check top-level structure
	let configDict = config

	// Check for 'metadata' section
	guard let metadata = configDict["metadata"] as? [String: Any] else {
		logger.debug("Missing required 'metadata' section")
		errors.append("Missing required 'metadata' section")
		return (false, errors)
	}

	// Check for 'episodes' section
	guard let episodes = configDict["episodes"] as? [[String: Any]] else {
		logger.debug("Missing required 'episodes' section")
		errors.append("Missing required 'episodes' section")
		return (false, errors)
	}

	// Validate metadata fields
	let requiredMetadataFields = ["title", "description", "link", "rss_feed_url", "language"]
	for field in requiredMetadataFields {
		if metadata[field] == nil {
			logger.debug("Missing required metadata field: '\(field)'")
			errors.append("Missing required metadata field: '\(field)'")
		} else if let value = metadata[field] as? String, value.isEmpty {
			logger.debug("Metadata field '\(field)' must be a non-empty string")
			errors.append("Metadata field '\(field)' must be a non-empty string")
		}
	}

	// Validate email fields (new and old format)
	if let email = metadata["email"] as? String ?? metadata["itunes_email"] as? String, !isValidEmail(email) {
		logger.debug("Invalid email format: '\(email)'")
		errors.append("Invalid email format: '\(email)'")
	} else if metadata["email"] == nil && metadata["itunes_email"] == nil {
		logger.debug("Missing required metadata field: 'email' (or 'itunes_email')")
		errors.append("Missing required metadata field: 'email' (or 'itunes_email')")
	}

	// Validate author field (new and old format)
	if let author = metadata["author"] as? String ?? metadata["itunes_author"] as? String, author.isEmpty {
		logger.debug("Author field must be a non-empty string")
		errors.append("Author field must be a non-empty string")
	} else if metadata["author"] == nil && metadata["itunes_author"] == nil {
		logger.debug("Missing required metadata field: 'author' (or 'itunes_author')")
		errors.append("Missing required metadata field: 'author' (or 'itunes_author')")
	}

	// Validate category field
	if let category = metadata["category"] as? String ?? metadata["itunes_category"] as? String, category.isEmpty {
		logger.debug("Category field must be a non-empty string")
		errors.append("Category field must be a non-empty string")
	}

	// Validate URLs
	let urlFields = ["link", "rss_feed_url", "image"]
	for field in urlFields {
		if let url = metadata[field] as? String, !url.isEmpty, !isValidURL(url) {
			logger.debug("Invalid URL format in metadata field '\(field)': '\(url)'")
			errors.append("Invalid URL format in metadata field '\(field)': '\(url)'")
		}
	}

	// Validate boolean fields
	let booleanFields = ["explicit", "itunes_explicit", "use_asset_hash_as_guid"]
	for field in booleanFields {
		if let value = metadata[field] as? Bool, value != true && value != false {
			logger.debug("Metadata field '\(field)' must be a boolean (true/false)")
			errors.append("Metadata field '\(field)' must be a boolean (true/false)")
		}
	}

	// Validate podcast_locked field
	if let lockedVal = metadata["podcast_locked"] as? String, !["yes", "no", "true", "false"].contains(lockedVal) {
		logger.debug("Metadata field 'podcast_locked' must be 'yes', 'no', true, or false")
		errors.append("Metadata field 'podcast_locked' must be 'yes', 'no', true, or false")
	}

	// Validate episodes section
	if episodes.isEmpty {
		logger.debug("At least one episode is required")
		errors.append("At least one episode is required")
	}

	let requiredEpisodeFields = ["title", "description", "publication_date", "asset_url"]
	let validEpisodeTypes = ["full", "trailer", "bonus"]

	for (i, episode) in episodes.enumerated() {
		let episodeDict = episode 

		// Check required fields in each episode
		for field in requiredEpisodeFields {
			if episodeDict[field] == nil {
				logger.debug("Episode \(i + 1): Missing required field '\(field)'")
				errors.append("Episode \(i + 1): Missing required field '\(field)'")
			} else if let value = episodeDict[field] as? String, value.isEmpty {
				logger.debug("Episode \(i + 1): Field '\(field)' must be a non-empty string")
				errors.append("Episode \(i + 1): Field '\(field)' must be a non-empty string")
			}
		}

		// Validate publication date
		if let publicationDate = episodeDict["publication_date"] as? String, !isValidISODate(publicationDate) {
			logger.debug("Episode \(i + 1): Invalid publication_date format '\(publicationDate)' (must be ISO format like '2025-09-01T10:00:00Z')")
			errors.append("Episode \(i + 1): Invalid publication_date format '\(publicationDate)' (must be ISO format like '2023-09-01T10:00:00Z')")
		}

		// Validate asset_url
		if let assetUrl = episodeDict["asset_url"] as? String, !isValidURL(assetUrl) {
			logger.debug("Episode \(i + 1): Invalid asset_url format '\(assetUrl)'")
			errors.append("Episode \(i + 1): Invalid asset_url format '\(assetUrl)'")
		}

		// Validate optional URL fields
		let episodeURLFields = ["link", "image"]
		for field in episodeURLFields {
			if let url = episodeDict[field] as? String, !url.isEmpty, !isValidURL(url) {
				logger.debug("Episode \(i + 1): Invalid URL format in field '\(field)': '\(url)'")
				errors.append("Episode \(i + 1): Invalid URL format in field '\(field)': '\(url)'")
			}
		}

		// Validate episode number
		if let episodeNumber = episodeDict["episode"] as? Int, episodeNumber < 1 {
			logger.debug("Episode \(i + 1): Field 'episode' must be a positive integer")
			errors.append("Episode \(i + 1): Field 'episode' must be a positive integer")
		}

		// Validate season number
		if let seasonNumber = episodeDict["season"] as? Int, seasonNumber < 1 {
			logger.debug("Episode \(i + 1): Field 'season' must be a positive integer")
			errors.append("Episode \(i + 1): Field 'season' must be a positive integer")
		}

		// Validate episode type
		if let episodeType = episodeDict["episode_type"] as? String, !validEpisodeTypes.contains(episodeType) {
			logger.debug("Episode \(i + 1): Invalid episode_type '\(episodeType)' (must be one of: \(validEpisodeTypes.joined(separator: ", ")))")
			errors.append("Episode \(i + 1): Invalid episode_type '\(episodeType)' (must be one of: \(validEpisodeTypes.joined(separator: ", ")))")
		}

		// Validate boolean fields in episodes
		let episodeBooleanFields = ["explicit", "itunes_explicit"]
		for field in episodeBooleanFields {
			if let value = episodeDict[field] as? Bool, value != true && value != false {
				logger.debug("Episode \(i + 1): Field '\(field)' must be a boolean (true/false)")
				errors.append("Episode \(i + 1): Field '\(field)' must be a boolean (true/false)")
			}
		}

		// Validate transcripts
		if let transcripts = episodeDict["transcripts"] as? [[String: Any]] {
			if transcripts.isEmpty {
				logger.debug("Episode \(i + 1): Field 'transcripts' must be a non-empty list")
				errors.append("Episode \(i + 1): Field 'transcripts' must be a non-empty list")
			} else {
				for (j, transcript) in transcripts.enumerated() {
					let transcriptDict = transcript 

					// Check required transcript fields
					if transcriptDict["url"] == nil {
						logger.debug("Episode \(i + 1): Transcript \(j + 1) missing required field 'url'")
						errors.append("Episode \(i + 1): Transcript \(j + 1) missing required field 'url'")
					} else if let url = transcriptDict["url"] as? String, !isValidURL(url) {
						logger.debug("Episode \(i + 1): Transcript \(j + 1) has invalid URL format: '\(url)'")
						errors.append("Episode \(i + 1): Transcript \(j + 1) has invalid URL format: '\(url)'")
					}

					if transcriptDict["type"] == nil {
						logger.debug("Episode \(i + 1): Transcript \(j + 1) missing required field 'type'")
						errors.append("Episode \(i + 1): Transcript \(j + 1) missing required field 'type'")
					} else if let type = transcriptDict["type"] as? String, type.isEmpty {
						logger.debug("Episode \(i + 1): Transcript \(j + 1) field 'type' must be a non-empty string")
						errors.append("Episode \(i + 1): Transcript \(j + 1) field 'type' must be a non-empty string")
					}
				}
			}
		}
	}

	return (errors.isEmpty, errors)
}
