---
name: app-store-metadata
description: Update App Store metadata (descriptions, keywords, release notes, etc.) and upload via fastlane deliver.
---

# App Store Metadata

Metadata lives in `fastlane/metadata/`. Edit the text files, then upload.

## Structure

- `fastlane/metadata/en-US/` — English
- `fastlane/metadata/de-DE/` — German
- `fastlane/metadata/copyright.txt`, `primary_category.txt` — non-localized

Key files per locale: `name.txt`, `subtitle.txt`, `description.txt`, `keywords.txt`, `promotional_text.txt`, `release_notes.txt`, `privacy_url.txt`, `support_url.txt`.

## Upload

Requires `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_BASE64` env vars (source `.env` if present).

```bash
export LC_ALL=en_US.UTF-8 && source .env && bundle exec fastlane metadata
```

This uploads metadata and screenshots without submitting for review.

## Submit for review

```bash
export LC_ALL=en_US.UTF-8 && source .env && bundle exec fastlane submit
```
