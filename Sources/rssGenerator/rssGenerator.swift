// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import Yams
import OSLog

@main
struct rssGenerator {
    static func main() async {
		let logger = Logger(subsystem: #function, category: Subsystems.app)
		// Getting command-line arguments
		let arguments = CommandLine.arguments
		var inputFile: String = "podcast_config.yaml"
		var outputFile: String = "podcast_feed.xml"
		var skipAssetVerification: Bool = false
		var dryRun: Bool = false
		
		// Parse command-line arguments
		for i in 1..<arguments.count {
			let arg = arguments[i]
			switch arg {
			case "-i":
				if i + 1 < arguments.count {
					inputFile = arguments[i + 1]
				}
			case "--input-file":
				if i + 1 < arguments.count {
					inputFile = arguments[i + 1]
				}
			case "-o":
				if i + 1 < arguments.count {
					outputFile = arguments[i + 1]
				}
			case "--output-file":
				if i + 1 < arguments.count {
					outputFile = arguments[i + 1]
				}
			case "--skip-asset-verification":
				skipAssetVerification = true
			case "--dry-run":
				dryRun = true
			default:
				continue
			}
		}
		
		print("Input file: \(inputFile)")
		if !dryRun {
			print("Output file: \(outputFile)")
		}
		if skipAssetVerification {
			print("Skipping asset verification.")
		}
		if dryRun {
			print("Dry-run mode: validating configuration only.")
		}

		// Read and validate config
		var config: [String: Any]
		do {
			config = try readPodcastConfig(yamlFilePath: inputFile)
		} catch {
			logger.error("Error: Config file '\(inputFile)' not found or could not be read.")
			print("Error: Config file '\(inputFile)' not found or could not be read.")
			exit(1)
		}

		// Validate configuration
		let (isValid, errors) = validateConfig(config)
		if !isValid {
			logger.error(" Config validation failed:\n\(errors.map({ "\t- \($0)" }).joined(separator: "\n"))")
			print("✗ Config validation failed:")
			for error in errors {
				print("  - \(error)")
			}
			exit(1)
		}

		print("✓ Config validation passed!")

		// If dry-run, stop here
		if dryRun {
			print("✓ Dry-run completed successfully.")
			exit(0)
		}

		// Generate RSS feed
		await generateRSS(config: config, outputFilePath: outputFile, skipAssetVerification: skipAssetVerification)
    }
}
