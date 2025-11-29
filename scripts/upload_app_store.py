#!/usr/bin/env python3
"""
App Store Connect API - Metadata & Screenshot Upload Script
Uploads localized metadata and promotional images for Scannie iOS app
"""

import json
import time
import subprocess
import sys
import re
from pathlib import Path
from datetime import datetime, timedelta
import xml.etree.ElementTree as ET

import jwt
import requests

# ============================================================
# Configuration
# ============================================================

BUNDLE_ID = "com.kobbokkom.scannie"
ISSUER_ID = "a7524762-b1db-463b-84a8-bbee51a37cc2"
KEY_ID = "74HC92L9NA"
PRIVATE_KEY_PATH = Path("/Users/semanticist/Documents/API/AuthKey_74HC92L9NA.p8")

BASE_URL = "https://api.appstoreconnect.apple.com/v1"

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent
METADATA_DIR = PROJECT_ROOT / "store" / "metadata" / "ios"
PROMO_DIR = PROJECT_ROOT / "store" / "screenshots" / "promotions" / "ios" / "lang"

# iOS locale code mapping (XML filename -> App Store Connect locale)
LOCALE_MAPPING = {
    "ar-SA": "ar-SA",
    "ca": "ca",
    "cs": "cs",
    "da": "da",
    "de-DE": "de-DE",
    "el": "el",
    "en-AU": "en-AU",
    "en-CA": "en-CA",
    "en-GB": "en-GB",
    "en-US": "en-US",
    "es-ES": "es-ES",
    "es-MX": "es-MX",
    "fi": "fi",
    "fr-CA": "fr-CA",
    "fr-FR": "fr-FR",
    "he": "he",
    "hi": "hi",
    "hr": "hr",
    "hu": "hu",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "ko": "ko",
    "ms": "ms",
    "nl-NL": "nl-NL",
    "no": "no",
    "pl": "pl",
    "pt-BR": "pt-BR",
    "pt-PT": "pt-PT",
    "ro": "ro",
    "ru": "ru",
    "sk": "sk",
    "sv": "sv",
    "th": "th",
    "tr": "tr",
    "uk": "uk",
    "vi": "vi",
    "zh-Hans": "zh-Hans",
    "zh-Hant": "zh-Hant",
}

# Promo folder mapping (XML locale -> promo folder name)
PROMO_FOLDER_MAPPING = {
    "ar-SA": "ar",
    "ca": "ca",
    "cs": "cs",
    "da": "da",
    "de-DE": "de-DE",
    "el": "el",
    "en-AU": "en-AU",
    "en-CA": "en-CA",
    "en-GB": "en-GB",
    "en-US": "en-US",
    "es-ES": "es-ES",
    "es-MX": "es-MX",
    "fi": "fi",
    "fr-CA": "fr-CA",
    "fr-FR": "fr-FR",
    "he": "he",
    "hi": "hi",
    "hr": "hr",
    "hu": "hu",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "ko": "ko",
    "ms": "ms",
    "nl-NL": "nl",
    "no": "no",
    "pl": "pl",
    "pt-BR": "pt-BR",
    "pt-PT": "pt-PT",
    "ro": "ro",
    "ru": "ru",
    "sk": "sk",
    "sv": "sv",
    "th": "th",
    "tr": "tr",
    "uk": "uk",
    "vi": "vi",
    "zh-Hans": "zh-Hans",
    "zh-Hant": "zh-Hant",
}

# ============================================================
# JWT Token Generation
# ============================================================

def generate_token() -> str:
    """Generate JWT token for App Store Connect API"""
    private_key = PRIVATE_KEY_PATH.read_text()

    now = datetime.utcnow()
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + timedelta(minutes=20),
        "aud": "appstoreconnect-v1",
    }

    headers = {
        "alg": "ES256",
        "kid": KEY_ID,
        "typ": "JWT",
    }

    token = jwt.encode(payload, private_key, algorithm="ES256", headers=headers)
    return token


def get_headers() -> dict:
    """Get authorization headers"""
    return {
        "Authorization": f"Bearer {generate_token()}",
        "Content-Type": "application/json",
    }


# ============================================================
# API Calls
# ============================================================

def api_get(endpoint: str) -> dict:
    """Make GET request to App Store Connect API"""
    url = f"{BASE_URL}{endpoint}"
    response = requests.get(url, headers=get_headers())
    response.raise_for_status()
    return response.json()


def api_patch(endpoint: str, data: dict) -> dict:
    """Make PATCH request to App Store Connect API"""
    url = f"{BASE_URL}{endpoint}"
    response = requests.patch(url, headers=get_headers(), json=data)
    response.raise_for_status()
    return response.json()


def api_post(endpoint: str, data: dict) -> dict:
    """Make POST request to App Store Connect API"""
    url = f"{BASE_URL}{endpoint}"
    response = requests.post(url, headers=get_headers(), json=data)
    response.raise_for_status()
    return response.json()


def api_delete(endpoint: str) -> None:
    """Make DELETE request to App Store Connect API"""
    url = f"{BASE_URL}{endpoint}"
    response = requests.delete(url, headers=get_headers())
    response.raise_for_status()


# ============================================================
# App Store Connect Operations
# ============================================================

def get_app_id() -> str:
    """Get app ID by bundle ID"""
    response = api_get(f"/apps?filter[bundleId]={BUNDLE_ID}")
    apps = response.get("data", [])
    if not apps:
        raise ValueError(f"App not found with bundle ID: {BUNDLE_ID}")
    return apps[0]["id"]


def get_app_store_version(app_id: str) -> dict:
    """Get the latest editable app store version"""
    response = api_get(f"/apps/{app_id}/appStoreVersions?filter[platform]=IOS")
    versions = response.get("data", [])

    # Find editable version (PREPARE_FOR_SUBMISSION, DEVELOPER_REJECTED, etc.)
    editable_states = ["PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED", "WAITING_FOR_REVIEW", "IN_REVIEW"]

    for version in versions:
        state = version["attributes"].get("appStoreState")
        if state in editable_states:
            return version

    # If no editable version, return the first one
    if versions:
        return versions[0]

    raise ValueError("No App Store version found")


def get_app_info(app_id: str) -> dict:
    """Get app info"""
    response = api_get(f"/apps/{app_id}/appInfos")
    infos = response.get("data", [])
    if not infos:
        raise ValueError("No app info found")
    return infos[0]


def get_version_localizations(version_id: str) -> dict:
    """Get all version localizations (title, subtitle, keywords)"""
    response = api_get(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    localizations = {}
    for loc in response.get("data", []):
        locale = loc["attributes"]["locale"]
        localizations[locale] = loc
    return localizations


def get_app_info_localizations(app_info_id: str) -> dict:
    """Get all app info localizations (description)"""
    response = api_get(f"/appInfos/{app_info_id}/appInfoLocalizations")
    localizations = {}
    for loc in response.get("data", []):
        locale = loc["attributes"]["locale"]
        localizations[locale] = loc
    return localizations


def create_version_localization(version_id: str, locale: str, metadata: dict) -> dict:
    """Create a new version localization"""
    data = {
        "data": {
            "type": "appStoreVersionLocalizations",
            "attributes": {
                "locale": locale,
                "description": metadata.get("description", ""),
                "keywords": metadata.get("keywords", ""),
                "whatsNew": metadata.get("whats_new", ""),
            },
            "relationships": {
                "appStoreVersion": {
                    "data": {
                        "type": "appStoreVersions",
                        "id": version_id
                    }
                }
            }
        }
    }
    return api_post("/appStoreVersionLocalizations", data)


def update_version_localization(localization_id: str, metadata: dict) -> dict:
    """Update version localization (description, keywords, whatsNew)"""
    data = {
        "data": {
            "type": "appStoreVersionLocalizations",
            "id": localization_id,
            "attributes": {}
        }
    }

    if "description" in metadata:
        data["data"]["attributes"]["description"] = metadata["description"]
    if "keywords" in metadata:
        data["data"]["attributes"]["keywords"] = metadata["keywords"]
    if "whats_new" in metadata:
        data["data"]["attributes"]["whatsNew"] = metadata["whats_new"]

    return api_patch(f"/appStoreVersionLocalizations/{localization_id}", data)


def create_app_info_localization(app_info_id: str, locale: str, metadata: dict) -> dict:
    """Create a new app info localization"""
    data = {
        "data": {
            "type": "appInfoLocalizations",
            "attributes": {
                "locale": locale,
                "name": metadata.get("title", "")[:30],
                "subtitle": metadata.get("subtitle", "")[:30],
            },
            "relationships": {
                "appInfo": {
                    "data": {
                        "type": "appInfos",
                        "id": app_info_id
                    }
                }
            }
        }
    }
    return api_post("/appInfoLocalizations", data)


def update_app_info_localization(localization_id: str, metadata: dict) -> dict:
    """Update app info localization (name, subtitle)"""
    data = {
        "data": {
            "type": "appInfoLocalizations",
            "id": localization_id,
            "attributes": {}
        }
    }

    if "title" in metadata:
        data["data"]["attributes"]["name"] = metadata["title"][:30]
    if "subtitle" in metadata:
        data["data"]["attributes"]["subtitle"] = metadata["subtitle"][:30]

    return api_patch(f"/appInfoLocalizations/{localization_id}", data)


# ============================================================
# Metadata Parsing
# ============================================================

def strip_emojis(text: str) -> str:
    """Remove emojis from text (App Store doesn't allow emojis in description)"""
    import unicodedata

    # Remove emoji characters
    emoji_pattern = re.compile(
        "["
        "\U0001F600-\U0001F64F"  # emoticons
        "\U0001F300-\U0001F5FF"  # symbols & pictographs
        "\U0001F680-\U0001F6FF"  # transport & map symbols
        "\U0001F1E0-\U0001F1FF"  # flags (iOS)
        "\U00002700-\U000027BF"  # Dingbats
        "\U0001F900-\U0001F9FF"  # Supplemental Symbols and Pictographs
        "\U00002600-\U000026FF"  # Misc symbols
        "\U00002300-\U000023FF"  # Misc Technical
        "\U0001FA00-\U0001FA6F"  # Chess Symbols
        "\U0001FA70-\U0001FAFF"  # Symbols and Pictographs Extended-A
        "\U00002B50"             # Star
        "\U00002728"             # Sparkles
        "]+",
        flags=re.UNICODE
    )

    # Remove emojis
    text = emoji_pattern.sub('', text)

    # Clean up extra whitespace and blank lines left after emoji removal
    lines = text.split('\n')
    cleaned_lines = []
    for line in lines:
        stripped = line.strip()
        # Keep the line if it has content after stripping
        if stripped:
            cleaned_lines.append(line)
        # Or keep blank lines between content (not at the start)
        elif cleaned_lines and cleaned_lines[-1].strip():
            cleaned_lines.append('')

    # Remove trailing blank lines
    while cleaned_lines and not cleaned_lines[-1].strip():
        cleaned_lines.pop()

    return '\n'.join(cleaned_lines)


def parse_metadata_xml(xml_path: Path) -> dict:
    """Parse iOS metadata XML file"""
    content = xml_path.read_text(encoding='utf-8')

    # Escape unescaped & characters
    content = re.sub(r'&(?!amp;|lt;|gt;|quot;|apos;|#)', '&amp;', content)

    root = ET.fromstring(content)

    metadata = {
        "title": "",
        "subtitle": "",
        "keywords": "",
        "description": "",
    }

    title_elem = root.find("title")
    if title_elem is not None and title_elem.text:
        metadata["title"] = title_elem.text.strip()

    subtitle_elem = root.find("subtitle")
    if subtitle_elem is not None and subtitle_elem.text:
        metadata["subtitle"] = subtitle_elem.text.strip()

    keywords_elem = root.find("keywords")
    if keywords_elem is not None and keywords_elem.text:
        metadata["keywords"] = keywords_elem.text.strip()

    desc_elem = root.find("description")
    if desc_elem is not None and desc_elem.text:
        # Strip emojis from description (App Store doesn't allow them)
        metadata["description"] = strip_emojis(desc_elem.text.strip())

    return metadata


# ============================================================
# Screenshot Upload
# ============================================================

def convert_svg_to_png(svg_path: Path, png_path: Path, width: int = 1290, height: int = 2796) -> bool:
    """Convert SVG to PNG using rsvg-convert (iPhone 6.7" display size)"""
    try:
        subprocess.run([
            "rsvg-convert",
            "-w", str(width),
            "-h", str(height),
            str(svg_path),
            "-o", str(png_path)
        ], check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"    Error converting {svg_path}: {e.stderr.decode()}")
        return False
    except FileNotFoundError:
        print("    Error: rsvg-convert not found. Install with: brew install librsvg")
        return False


def get_screenshot_sets(localization_id: str) -> list:
    """Get all screenshot sets for a localization"""
    response = api_get(f"/appStoreVersionLocalizations/{localization_id}/appScreenshotSets")
    return response.get("data", [])


def create_screenshot_set(localization_id: str, display_type: str) -> dict:
    """Create a new screenshot set"""
    data = {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {
                "screenshotDisplayType": display_type
            },
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "id": localization_id
                    }
                }
            }
        }
    }
    return api_post("/appScreenshotSets", data)


def get_screenshots_in_set(screenshot_set_id: str) -> list:
    """Get all screenshots in a set"""
    response = api_get(f"/appScreenshotSets/{screenshot_set_id}/appScreenshots")
    return response.get("data", [])


def delete_screenshot(screenshot_id: str) -> None:
    """Delete a screenshot"""
    api_delete(f"/appScreenshots/{screenshot_id}")


def reserve_screenshot(screenshot_set_id: str, filename: str, file_size: int) -> dict:
    """Reserve a screenshot upload"""
    data = {
        "data": {
            "type": "appScreenshots",
            "attributes": {
                "fileName": filename,
                "fileSize": file_size
            },
            "relationships": {
                "appScreenshotSet": {
                    "data": {
                        "type": "appScreenshotSets",
                        "id": screenshot_set_id
                    }
                }
            }
        }
    }
    return api_post("/appScreenshots", data)


def upload_screenshot_part(upload_url: str, data: bytes, offset: int, length: int) -> None:
    """Upload a screenshot part"""
    headers = {
        "Content-Type": "application/octet-stream",
        "Content-Range": f"bytes {offset}-{offset + length - 1}/{len(data)}"
    }
    response = requests.put(upload_url, headers=headers, data=data[offset:offset + length])
    response.raise_for_status()


def commit_screenshot(screenshot_id: str, checksum: str) -> dict:
    """Commit a screenshot upload"""
    data = {
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {
                "uploaded": True,
                "sourceFileChecksum": checksum
            }
        }
    }
    return api_patch(f"/appScreenshots/{screenshot_id}", data)


def upload_screenshot(screenshot_set_id: str, png_path: Path) -> bool:
    """Upload a single screenshot"""
    import hashlib

    file_data = png_path.read_bytes()
    file_size = len(file_data)
    checksum = hashlib.md5(file_data).hexdigest()

    # Reserve upload
    reservation = reserve_screenshot(screenshot_set_id, png_path.name, file_size)
    screenshot_id = reservation["data"]["id"]

    # Get upload operations
    upload_ops = reservation["data"]["attributes"].get("uploadOperations", [])

    if not upload_ops:
        print(f"    No upload operations returned for {png_path.name}")
        return False

    # Upload parts
    for op in upload_ops:
        upload_url = op["url"]
        offset = op["offset"]
        length = op["length"]

        headers = {k: v for k, v in op.get("requestHeaders", []) if isinstance(op.get("requestHeaders"), list)}
        if isinstance(op.get("requestHeaders"), list):
            headers = {h["name"]: h["value"] for h in op["requestHeaders"]}

        part_data = file_data[offset:offset + length]
        response = requests.put(upload_url, headers=headers, data=part_data)
        response.raise_for_status()

    # Commit upload
    commit_screenshot(screenshot_id, checksum)
    return True


def upload_screenshots_for_locale(localization_id: str, locale: str, promo_folder: str) -> None:
    """Upload all promotional screenshots for a locale"""
    promo_path = PROMO_DIR / promo_folder

    if not promo_path.exists():
        print(f"    No promo folder found: {promo_path}")
        return

    # Get or create screenshot set for iPhone 6.7" display (largest available)
    screenshot_sets = get_screenshot_sets(localization_id)

    display_type = "APP_IPHONE_67"  # iPhone 6.7" display
    screenshot_set = None

    for ss in screenshot_sets:
        if ss["attributes"]["screenshotDisplayType"] == display_type:
            screenshot_set = ss
            break

    if not screenshot_set:
        print(f"    Creating screenshot set for {display_type}")
        screenshot_set = create_screenshot_set(localization_id, display_type)["data"]

    screenshot_set_id = screenshot_set["id"]

    # Delete existing screenshots
    existing = get_screenshots_in_set(screenshot_set_id)
    for ss in existing:
        print(f"    Deleting existing screenshot: {ss['attributes']['fileName']}")
        delete_screenshot(ss["id"])
        time.sleep(0.5)

    # Convert and upload SVGs
    svg_files = sorted(promo_path.glob("promo_*.svg"))

    for svg_path in svg_files:
        png_path = svg_path.with_suffix(".png")

        print(f"    Converting {svg_path.name} to PNG...")
        if not convert_svg_to_png(svg_path, png_path):
            continue

        print(f"    Uploading {png_path.name}...")
        try:
            upload_screenshot(screenshot_set_id, png_path)
            print(f"    ✓ Uploaded {png_path.name}")
        except Exception as e:
            print(f"    ✗ Failed to upload {png_path.name}: {e}")
        finally:
            # Clean up PNG
            if png_path.exists():
                png_path.unlink()

        time.sleep(1)


# ============================================================
# Main Upload Function
# ============================================================

def upload_locale(locale: str, skip_screenshots: bool = False) -> bool:
    """Upload metadata and screenshots for a single locale"""
    xml_locale = locale
    api_locale = LOCALE_MAPPING.get(locale)
    promo_folder = PROMO_FOLDER_MAPPING.get(locale)

    if not api_locale:
        print(f"❌ Unknown locale mapping: {locale}")
        return False

    xml_path = METADATA_DIR / f"{xml_locale}.xml"
    if not xml_path.exists():
        print(f"❌ Metadata file not found: {xml_path}")
        return False

    print(f"\n{'='*60}")
    print(f"📱 Processing: {locale} ({api_locale})")
    print(f"{'='*60}")

    try:
        # Parse metadata
        metadata = parse_metadata_xml(xml_path)
        print(f"  Title: {metadata['title'][:40]}...")
        print(f"  Subtitle: {metadata['subtitle'][:40]}...")

        # Get app info
        app_id = get_app_id()
        print(f"  App ID: {app_id}")

        # Get app info and version
        app_info = get_app_info(app_id)
        app_info_id = app_info["id"]

        version = get_app_store_version(app_id)
        version_id = version["id"]
        version_string = version["attributes"]["versionString"]
        print(f"  Version: {version_string} ({version_id})")

        # Get existing localizations
        version_locs = get_version_localizations(version_id)
        app_info_locs = get_app_info_localizations(app_info_id)

        # Update or create version localization (description, keywords)
        if api_locale in version_locs:
            loc_id = version_locs[api_locale]["id"]
            print(f"  Updating version localization: {loc_id}")
            update_version_localization(loc_id, metadata)
        else:
            print(f"  Creating version localization for {api_locale}")
            result = create_version_localization(version_id, api_locale, metadata)
            loc_id = result["data"]["id"]

        # Update or create app info localization (name, subtitle)
        if api_locale in app_info_locs:
            info_loc_id = app_info_locs[api_locale]["id"]
            print(f"  Updating app info localization: {info_loc_id}")
            update_app_info_localization(info_loc_id, metadata)
        else:
            print(f"  Creating app info localization for {api_locale}")
            create_app_info_localization(app_info_id, api_locale, metadata)

        print(f"  ✓ Metadata updated")

        # Upload screenshots
        if not skip_screenshots and promo_folder:
            print(f"  Uploading screenshots from: {promo_folder}")

            # Get version localization ID for screenshots
            version_locs = get_version_localizations(version_id)
            if api_locale in version_locs:
                ver_loc_id = version_locs[api_locale]["id"]
                upload_screenshots_for_locale(ver_loc_id, api_locale, promo_folder)
            else:
                print(f"    ⚠️ No version localization found for screenshots")

        print(f"✅ Completed: {locale}")
        return True

    except requests.exceptions.HTTPError as e:
        print(f"❌ HTTP Error for {locale}: {e}")
        if e.response is not None:
            try:
                error_detail = e.response.json()
                print(f"   Details: {json.dumps(error_detail, indent=2)}")
            except:
                print(f"   Response: {e.response.text[:500]}")
        return False
    except Exception as e:
        print(f"❌ Error for {locale}: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Upload iOS App Store metadata")
    parser.add_argument("locale", nargs="?", help="Specific locale to upload (e.g., en-US)")
    parser.add_argument("--all", action="store_true", help="Upload all locales")
    parser.add_argument("--skip-screenshots", action="store_true", help="Skip screenshot upload")
    parser.add_argument("--list", action="store_true", help="List available locales")

    args = parser.parse_args()

    if args.list:
        print("Available locales:")
        for locale in sorted(LOCALE_MAPPING.keys()):
            xml_path = METADATA_DIR / f"{locale}.xml"
            status = "✓" if xml_path.exists() else "✗"
            print(f"  {status} {locale}")
        return

    if args.locale:
        success = upload_locale(args.locale, args.skip_screenshots)
        sys.exit(0 if success else 1)

    elif args.all:
        success_count = 0
        fail_count = 0

        for locale in sorted(LOCALE_MAPPING.keys()):
            if upload_locale(locale, args.skip_screenshots):
                success_count += 1
            else:
                fail_count += 1
            time.sleep(2)  # Rate limiting

        print(f"\n{'='*60}")
        print(f"Summary: {success_count} succeeded, {fail_count} failed")
        print(f"{'='*60}")

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
