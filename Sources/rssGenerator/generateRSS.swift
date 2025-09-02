//
//  generateRSS.swift
//  rssGenerator
//
//  Created by Justin Purnell on 9/2/25.
//

import Foundation
import Yams
import OSLog

func generateRSS(config: [String: Any], outputFilePath: String, skipAssetVerification: Bool = false) async {
	let logger = Logger(subsystem: #function, category: Subsystems.app)
	// Create XML root
	let rss = XMLElement(name: "rss")
	rss.setAttributesWith([
		"version": "2.0",
		"xmlns:itunes": "http://www.itunes.com/dtds/podcast-1.0.dtd",
		"xmlns:atom": "http://www.w3.org/2005/Atom",
		"xmlns:podcast": "https://podcastindex.org/namespace/1.0"
	])
	
	let channel = XMLElement(name: "channel")
	rss.addChild(channel)

	// Retrieve metadata
	guard let metadata = config["metadata"] as? [String: Any] else {
		logger.error("Error: Missing required 'metadata' section")
		return
	}
	
	// Populate channel with metadata
	func getMeta(key: String, oldKey: String? = nil) -> Any? {
		return metadata[key] ?? (oldKey.map { metadata[$0] }) ?? nil
	}

	channel.addChild(XMLElement(name: "title", stringValue: getMeta(key: "title") as? String ?? ""))
	channel.addChild(XMLElement(name: "description", stringValue: formatDescription(getMeta(key: "description") as? String ?? "")))
	channel.addChild(XMLElement(name: "language", stringValue: getMeta(key: "language") as? String ?? "en-us"))
	channel.addChild(XMLElement(name: "link", stringValue: getMeta(key: "link") as? String ?? ""))
	channel.addChild(XMLElement(name: "generator", stringValue: "Podcast RSS Generator (https://github.com/vpetersson/podcast-rss-generator)"))

	// Atom link element
	if let rssFeedURL = getMeta(key: "rss_feed_url") as? String {
		let atomLink = XMLElement(name: "atom:link")
		atomLink.setAttributesWith([
			"href": rssFeedURL,
			"rel": "self",
			"type": "application/rss+xml"
		])
		channel.addChild(atomLink)
	}

	// Explicit tag
	let explicit = (getMeta(key: "itunes_explicit") as? Bool == true) ? "yes" : "no"
	channel.addChild(XMLElement(name: "itunes:explicit", stringValue: explicit))
	
	// Owner/Email
	if let email = getMeta(key: "email", oldKey: "itunes_email") as? String {
		let owner = XMLElement(name: "itunes:owner")
		owner.addChild(XMLElement(name: "itunes:email", stringValue: email))
		channel.addChild(owner)
	}

	// Author
	channel.addChild(XMLElement(name: "itunes:author", stringValue: getMeta(key: "author", oldKey: "itunes_author") as? String ?? ""))
	
	// Summary
	channel.addChild(XMLElement(name: "itunes:summary", stringValue: metadata["description"] as? String ?? ""))
	
	// Category
	if let category = getMeta(key: "category", oldKey: "itunes_category") as? String {
		channel.addChild(XMLElement(name: "itunes:category", stringValue: category))
	}
	
	// Image
	if let image = getMeta(key: "image") as? String {
		let imageElement = XMLElement(name: "itunes:image")
		imageElement.setAttributesWith(["href": image])
		channel.addChild(imageElement)
	}
	
	// Copyright
	if let copyright = metadata["copyright"] as? String {
		channel.addChild(XMLElement(name: "copyright", stringValue: copyright))
	}
	
	// Process podcast locked
	let podcastLocked = getMeta(key: "podcast_locked") as? String ?? "no"
	let lockedText = (podcastLocked.lowercased() == "true" || podcastLocked.lowercased() == "yes") ? "yes" : "no"
	
	let lockedElement = XMLElement(name: "podcast:locked")
	let email = getMeta(key: "email", oldKey: "itunes_email") as? String ?? ""
	lockedElement.setAttributesWith(["owner": email])
	lockedElement.stringValue = lockedText
	channel.addChild(lockedElement)

	// Process podcast guid
	if let podcastGuid = getMeta(key: "podcast_guid") as? String {
		channel.addChild(XMLElement(name: "podcast:guid", stringValue: podcastGuid))
	} else if let _ = getMeta(key: "rss_feed_url") as? String {
		let generatedGuid = UUID().uuidString // Generate a new GUID if not found
		logger.warning("Warning: podcast_guid not found in metadata. Generated GUID: \(generatedGuid)")
		channel.addChild(XMLElement(name: "podcast:guid", stringValue: generatedGuid))
	}

	// --- Episode Processing ---
	guard let episodes = config["episodes"] as? [[String: Any]] else {
		logger.error("Error: Missing required 'episodes' section")
		return
	}

	for episode in episodes {
		let title = episode["title"] as? String ?? "Unknown Title"
		logger.debug("Processing episode \(title)...")
		
		guard let pubDateStr = episode["publication_date"] as? String else {
			logger.warning("  Skipping episode as 'publication_date' is missing.")
			continue
		}

		// Format the publication date
		let compatiblePubDateStr = pubDateStr.replacingOccurrences(of: "Z", with: "+00:00")
		let dateFormatter = ISO8601DateFormatter()
		
		guard let pubDate = dateFormatter.date(from: compatiblePubDateStr) else {
			logger.warning("  Skipping episode \(title) as the publication date is invalid.")
			continue
		}

		// Compare to the current date
		if pubDate >= Date() {
			logger.warning("  Skipping episode \(title) as it's not yet published.")
			continue
		}

//		var fileInfo: [String: Any] = [
//			"content-length": "0", // Default values
//			"content-type": "application/octet-stream",
//			"duration": 0,
//			"content_hash": 0
//		]
		var fileInfo = FileInfo(contentLength: "0", contentType: "application/octet-stream", duration: 0, contentHash: "")

		// Asset verification logic
		if !skipAssetVerification, let assetUrl = episode["asset_url"] as? String {
			do {
				fileInfo = try await getFileInfo(url: assetUrl) // Call the file info function
			} catch {
				logger.error("Failed to get file info for \(assetUrl): \(error)")
			}
		}

		// Create an item element
		let item = XMLElement(name: "item")
		item.addChild(XMLElement(name: "pubDate", stringValue: convertISOToRFC2822(pubDateStr)))
		item.addChild(XMLElement(name: "title", stringValue: episode["title"] as? String ?? ""))
		item.addChild(XMLElement(name: "description", stringValue: formatDescription(episode["description"] as? String ?? "")))

		// GUID Logic
		var guidText = episode["asset_url"] as? String ?? ""
		if let contentHash = fileInfo.contentHash {
			guidText = contentHash
			logger.debug("  Using content hash for GUID: \(guidText)")
		}
		item.addChild(XMLElement(name: "guid", stringValue: guidText))

		// Enclosure
		let enclosure = XMLElement(name: "enclosure")
		enclosure.setAttributesWith([
			"url": episode["asset_url"] as? String ?? "",
			"type": fileInfo.contentType ?? "application/octet-stream",
			"length": fileInfo.contentLength ?? "0"
		])
		item.addChild(enclosure)

		// Add other iTunes-specific fields
		if let episodeType = episode["episode_type"] as? String {
			item.addChild(XMLElement(name: "itunes:episodeType", stringValue: episodeType))
		}

		if let explicitValue = episode["explicit"] as? Bool {
			let explicitString = explicitValue ? "yes" : "no"
			item.addChild(XMLElement(name: "itunes:explicit", stringValue: explicitString))
		}

		// Add season and episode fields
		if let episodeNumber = episode["episode"] as? Int {
			item.addChild(XMLElement(name: "itunes:episode", stringValue: String(episodeNumber)))
		}

		if let seasonNumber = episode["season"] as? Int {
			item.addChild(XMLElement(name: "itunes:season", stringValue: String(seasonNumber)))
		}

		// Add link and image
		if let link = episode["link"] as? String {
			item.addChild(XMLElement(name: "link", stringValue: link))
		} else {
			item.addChild(XMLElement(name: "link", stringValue: metadata["link"] as? String ?? ""))
		}

		if let imageUrl = episode["image"] as? String {
			let imageElement = XMLElement(name: "itunes:image")
			imageElement.setAttributesWith(["href": imageUrl])
			item.addChild(imageElement)
		}

		// Process transcripts if available
		if let transcripts = episode["transcripts"] as? [[String: Any]] {
			for transcript in transcripts {
				if let url = transcript["url"] as? String,
				   let type = transcript["type"] as? String {
					let transcriptElement = XMLElement(name: "podcast:transcript")
					transcriptElement.setAttributesWith(["url": url, "type": type])
					item.addChild(transcriptElement)
				} else {
					logger.warning("  Skipping invalid transcript entry: \(transcript)")
				}
			}
		}

		// Add the item to the channel
		channel.addChild(item)
	}

	// Write the XML to the output file
	let xmlString = rss.xmlString // Assuming you have implemented xmlString property or function
	do {
		try xmlString.write(to: URL(fileURLWithPath: outputFilePath), atomically: true, encoding: .utf8)
	} catch {
		logger.error("Error writing XML to file: \(error)")
	}
}
