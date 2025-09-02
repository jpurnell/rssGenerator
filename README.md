# Podcast RSS Generator

## Description

This an RSS Feed Generator is designed to generate an RSS feed for audio/video podcasts, reading metadata and episode data from a YAML file.

It assumes that you self-host your video episodes somewhere (e.g. S3/GCS/R2) as well as the output of this script. You can then point YouTube/Spotify/Apple Podcast to this path.

This tool is a Swift implementation of the [podcast-rss-generator](https://github.com/vpetersson/podcast-rss-generator/blob) by [Nerding Out with Viktor](https://vpetersson.com/podcast/) to solve for the fact that Apple's [Podcast Connect](https://podcastsconnect.apple.com) require you to self-host videos in order to publish.

## Features

- Generates RSS feed for audio/video podcasts
- Reads podcast metadata and episode data from a YAML file
- Converts ISO format dates to RFC 2822 format
- Attempts to follow [The Podcast RSS Standard](https://github.com/Podcast-Standards-Project/PSP-1-Podcast-RSS-Specification)

## Known Issues

- Videos uploaded to YouTube [via RSS](https://support.google.com/youtube/answer/13525207?hl=en#zippy=%2Ccan-i-deliver-an-rss-feed-if-i-already-have-a-podcast-on-youtube) will be uploaded as audio.
- Spotify can't handle videos via RSS yet. You will be able to see the episodes in Podcaster, but they will not be processed and sent to Spotify properly. This is apparently a known issue that they are working on resolving.

The workaround for the above issues is to manually upload the episodes.

## Installation

### Prerequisites

- Swift 6.1 or higher
- brew
- ffmpeg

### Setup

1. **Clone the Repository**

```bash
$ git clone https://github.com/jpurnell/rssGenerator.git
$ cd rssGenerator
```

2. **Install Dependencies**

```bash
$ swift run
```

**Optional:** Install `yamllint`, `xq` and `flake8`.

## Usage

```bash
$ rssGenerator --help
usage: rssGenerator [-h] [--input-file -i INPUT_FILE] [--output-file -o OUTPUT_FILE]
                        [--skip-asset-verification] [--dry-run]

Process some parameters.

options:
  -h, --help            show this help message and exit
  --input-file -i INPUT_FILE
                        Input YAML file
  --output-file -o OUTPUT_FILE
                        Output XML file
  --skip-asset-verification
                        Skip HTTP HEAD and ffprobe checks for asset URLs (use for testing/fake URLs)
  --dry-run             Validate configuration file only, do not generate RSS feed
```

1. **Prepare Your Data Files**

Copy `podcast_config.example.yaml` to `podcast_config.yaml` and fill out your podcast metadata and eepisodes.

2. **Validate Your Configuration** (Dry-run)

Before generating the RSS feed, you can validate your configuration file using the `--dry-run` flag:

```bash
$ rssGenerator --dry-run
```

This will:

- Check if your YAML file has valid syntax
- Validate all required fields are present
- Check URL formats for links, asset URLs, and images
- Verify email addresses and ISO date formats
- Validate episode structure and optional fields
- Exit with code 0 if valid, or code 1 if errors are found

Example output for a valid config:

```
✓ Config validation passed!
✓ Dry-run completed successfully.
```

Example output for an invalid config:

```
✗ Config validation failed:
  - Invalid email format: 'invalid-email'
  - Episode 1: Invalid publication_date format 'invalid-date'
  - Episode 1: Invalid asset_url format 'not-a-url'
```

3. **Generate the RSS Feed**

The `podcast_config.yaml` file contains two main sections: `metadata` and `episodes`.

### Metadata Section

This section contains general information about your podcast:

| Key                      | Description                                                                                                                                                                                                                                                                                                    | Notes                                                                                                                                                                                                                               |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `title`                  | The title of your podcast.                                                                                                                                                                                                                                                                                     | Required                                                                                                                                                                                                                            |
| `description`            | A description of your podcast.                                                                                                                                                                                                                                                                                 | Required. Markdown is supported.                                                                                                                                                                                                    |
| `link`                   | The URL of the main website for your podcast.                                                                                                                                                                                                                                                                  | Required. Also the default link for episodes if not provided per-episode.                                                                                                                                                           |
| `rss_feed_url`           | The public URL where your generated `podcast_feed.xml` will be hosted.                                                                                                                                                                                                                                         | Required                                                                                                                                                                                                                            |
| `language`               | The language of the podcast (e.g., `en-us`).                                                                                                                                                                                                                                                                   | Optional. Default: `en-us`.                                                                                                                                                                                                         |
| `email`                  | The contact email for the podcast owner.                                                                                                                                                                                                                                                                       | Required. Backward compatibility: `itunes_email`. Used for `<podcast:locked>`.                                                                                                                                                      |
| `author`                 | The author name(s).                                                                                                                                                                                                                                                                                            | Required. Backward compatibility: `itunes_author`.                                                                                                                                                                                  |
| `category`               | The primary category for iTunes.                                                                                                                                                                                                                                                                               | Optional. Backward compatibility: `itunes_category`.                                                                                                                                                                                |
| `image`                  | The URL for the main podcast cover art (JPEG or PNG, 1400x1400 to 3000x3000 pixels).                                                                                                                                                                                                                           | Required. Also the default image for episodes if not provided per-episode.                                                                                                                                                          |
| `explicit`               | Indicates if the podcast contains explicit content.                                                                                                                                                                                                                                                            | Optional (`true`/`false`). Default: `false`. Backward compatibility: `itunes_explicit`. Can be overridden per-episode.                                                                                                              |
| `use_asset_hash_as_guid` | Use a content hash or ETag from the asset file\'s headers as the episode\'s `<guid>`. Prioritizes `x-amz-checksum-sha256`, then `x-goog-hash` (MD5 part), then `ETag`. **Warning:** This can break GUID permanence if asset files change or are re-uploaded, potentially causing re-downloads for subscribers. | Optional (`true`/`false`). Default: `false` (uses `asset_url`).                                                                                                                                                                     |
| `copyright`              | A string containing the copyright notice for the podcast.                                                                                                                                                                                                                                                      | Optional.                                                                                                                                                                                                                           |
| `podcast_locked`         | Tells platforms not to import the feed without confirming ownership via the `email` address.                                                                                                                                                                                                                   | Optional (`yes`/`no`). Default: `no`. Based on [Podcast Standards Project](https://github.com/Podcast-Standards-Project/PSP-1-Podcast-RSS-Specification).                                                                           |
| `podcast_guid`           | A globally unique, permanent identifier (UUID recommended) for the _entire podcast show_.                                                                                                                                                                                                                      | Optional. If omitted, a stable UUIDv5 is generated from `rss_feed_url`. Strongly recommended to set explicitly. Based on [Podcast Standards Project](https://github.com/Podcast-Standards-Project/PSP-1-Podcast-RSS-Specification). |

### Episodes Section

This section is a list of your podcast episodes. Each episode is an object with the following fields:

| Key                | Description                                                                                                                                             | Notes                                                                                                                           |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `title`            | The title of the episode.                                                                                                                               | Required.                                                                                                                       |
| `description`      | A description of the episode.                                                                                                                           | Required. Markdown is supported.                                                                                                |
| `publication_date` | The date and time the episode was published. Episodes with future dates will not be included.                                                           | Required. ISO 8601 format (e.g., `2023-01-15T10:00:00Z`).                                                                       |
| `asset_url`        | The direct URL to the audio or video file for the episode.                                                                                              | Required.                                                                                                                       |
| `link`             | The URL for a webpage specific to this episode.                                                                                                         | Optional. Defaults to the global `link` from `metadata`.                                                                        |
| `image`            | The URL for artwork specific to this episode (same format requirements as the main podcast image).                                                      | Optional. Defaults to the global `image` from `metadata`.                                                                       |
| `episode`          | The episode number.                                                                                                                                     | Optional. Integer.                                                                                                              |
| `season`           | The season number.                                                                                                                                      | Optional. Integer.                                                                                                              |
| `episode_type`     | Defines the type of content for the episode.                                                                                                            | Optional. Can be `full` (default), `trailer`, or `bonus`.                                                                       |
| `explicit`         | Indicates if this specific episode contains explicit content.                                                                                           | Optional (`true`/`false`). Overrides the global `explicit` setting for this episode. Backward compatibility: `itunes_explicit`. |
| `transcripts`      | A list of transcript files associated with the episode. Each item is an object with `url` (required), `type` (required), `language` (opt), `rel` (opt). | Optional. See example config for structure.                                                                                     |

4. **Generate the RSS Feed**

Make sure your YAML is valid:

```bash
$ yamllint podcast_config.yaml
```

Generate your `podcast_feed.xml` file:

```bash
$ rssGenerator
```

Now copy your `podcast_feed.xml` to S3/GCS/R2 using a tool like `s3cmd`, `aws` or `mc` (from Minio).

You can verify your RSS feed using a tool like [Podbase](https://podba.se/validate/).

## **Optional:** Optimize video

If you're dealing with video podcasts, the file size matters for obvious reasons. What I do is to export the video as h624 from my video editor (which I upload to YouTube and Spotify).

I then re-encode the h264 video to h265 for other platforms using `ffmpeg` with the following command (on macOS):

```bash
$ ffmpeg -i input.mp4 \
    -tag:v hvc1 \
    -c:v hevc_videotoolbox \
    -crf 28 \
    -preset slowest \
    -c:a aac \
    -b:a 128k \
    -movflags faststart \
    output.mp4
```

## Contributing

Contributions to this project are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature.
3. Commit your changes.
4. Push to the branch.
5. Submit a pull request.

## License

[MIT License](LICENSE)
