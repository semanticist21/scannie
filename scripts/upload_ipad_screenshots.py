#!/usr/bin/env python3
"""
iPad 13" Screenshot Upload Script for App Store Connect
Uploads iPad screenshots to all locales
"""

import json
import time
import hashlib
import sys
from pathlib import Path
from datetime import datetime, timedelta

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
IPAD_SCREENSHOT_DIR = PROJECT_ROOT / "store" / "screenshots" / "ipad_13"

# Display type for iPad Pro 12.9" / 13"
IPAD_DISPLAY_TYPE = "APP_IPAD_PRO_3GEN_129"

# iOS locale codes
LOCALES = [
    "ar-SA", "ca", "cs", "da", "de-DE", "el", "en-AU", "en-CA", "en-GB", "en-US",
    "es-ES", "es-MX", "fi", "fr-CA", "fr-FR", "he", "hi", "hr", "hu", "id",
    "it", "ja", "ko", "ms", "nl-NL", "no", "pl", "pt-BR", "pt-PT", "ro",
    "ru", "sk", "sv", "th", "tr", "uk", "vi", "zh-Hans", "zh-Hant"
]

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
    url = f"{BASE_URL}{endpoint}"
    response = requests.get(url, headers=get_headers())
    response.raise_for_status()
    return response.json()


def api_post(endpoint: str, data: dict) -> dict:
    url = f"{BASE_URL}{endpoint}"
    response = requests.post(url, headers=get_headers(), json=data)
    response.raise_for_status()
    return response.json()


def api_patch(endpoint: str, data: dict) -> dict:
    url = f"{BASE_URL}{endpoint}"
    response = requests.patch(url, headers=get_headers(), json=data)
    response.raise_for_status()
    return response.json()


def api_delete(endpoint: str) -> None:
    url = f"{BASE_URL}{endpoint}"
    response = requests.delete(url, headers=get_headers())
    response.raise_for_status()


# ============================================================
# App Store Connect Operations
# ============================================================

def get_app_id() -> str:
    response = api_get(f"/apps?filter[bundleId]={BUNDLE_ID}")
    apps = response.get("data", [])
    if not apps:
        raise ValueError(f"App not found: {BUNDLE_ID}")
    return apps[0]["id"]


def get_app_store_version(app_id: str) -> dict:
    response = api_get(f"/apps/{app_id}/appStoreVersions?filter[platform]=IOS")
    versions = response.get("data", [])

    editable_states = ["PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
                       "METADATA_REJECTED", "WAITING_FOR_REVIEW", "IN_REVIEW"]

    for version in versions:
        state = version["attributes"].get("appStoreState")
        if state in editable_states:
            return version

    if versions:
        return versions[0]

    raise ValueError("No App Store version found")


def get_version_localizations(version_id: str) -> dict:
    response = api_get(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    localizations = {}
    for loc in response.get("data", []):
        locale = loc["attributes"]["locale"]
        localizations[locale] = loc
    return localizations


def get_screenshot_sets(localization_id: str) -> list:
    response = api_get(f"/appStoreVersionLocalizations/{localization_id}/appScreenshotSets")
    return response.get("data", [])


def create_screenshot_set(localization_id: str, display_type: str) -> dict:
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
    response = api_get(f"/appScreenshotSets/{screenshot_set_id}/appScreenshots")
    return response.get("data", [])


def delete_screenshot(screenshot_id: str) -> None:
    api_delete(f"/appScreenshots/{screenshot_id}")


def reserve_screenshot(screenshot_set_id: str, filename: str, file_size: int) -> dict:
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


def commit_screenshot(screenshot_id: str, checksum: str) -> dict:
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

        headers = {}
        if isinstance(op.get("requestHeaders"), list):
            headers = {h["name"]: h["value"] for h in op["requestHeaders"]}

        part_data = file_data[offset:offset + length]
        response = requests.put(upload_url, headers=headers, data=part_data)
        response.raise_for_status()

    # Commit upload
    commit_screenshot(screenshot_id, checksum)
    return True


def upload_ipad_screenshots_for_locale(localization_id: str, locale: str) -> None:
    """Upload iPad screenshots for a locale"""

    # Get or create screenshot set for iPad
    screenshot_sets = get_screenshot_sets(localization_id)

    screenshot_set = None
    for ss in screenshot_sets:
        if ss["attributes"]["screenshotDisplayType"] == IPAD_DISPLAY_TYPE:
            screenshot_set = ss
            break

    if not screenshot_set:
        print(f"    Creating screenshot set for {IPAD_DISPLAY_TYPE}")
        screenshot_set = create_screenshot_set(localization_id, IPAD_DISPLAY_TYPE)["data"]

    screenshot_set_id = screenshot_set["id"]

    # Delete existing screenshots
    existing = get_screenshots_in_set(screenshot_set_id)
    for ss in existing:
        print(f"    Deleting: {ss['attributes']['fileName']}")
        delete_screenshot(ss["id"])
        time.sleep(0.3)

    # Upload PNG files
    png_files = sorted(IPAD_SCREENSHOT_DIR.glob("*.png"))

    for png_path in png_files:
        print(f"    Uploading {png_path.name}...")
        try:
            upload_screenshot(screenshot_set_id, png_path)
            print(f"    ✓ Uploaded {png_path.name}")
        except Exception as e:
            print(f"    ✗ Failed: {e}")
        time.sleep(0.5)


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Upload iPad 13\" screenshots")
    parser.add_argument("locale", nargs="?", help="Specific locale (e.g., en-US)")
    parser.add_argument("--all", action="store_true", help="Upload to all locales")

    args = parser.parse_args()

    # Check screenshots exist
    if not IPAD_SCREENSHOT_DIR.exists():
        print(f"Screenshot directory not found: {IPAD_SCREENSHOT_DIR}")
        sys.exit(1)

    png_files = list(IPAD_SCREENSHOT_DIR.glob("*.png"))
    print(f"Found {len(png_files)} screenshots in {IPAD_SCREENSHOT_DIR}")

    if not png_files:
        print("No PNG files found!")
        sys.exit(1)

    # Get app info
    print("\nConnecting to App Store Connect...")
    app_id = get_app_id()
    print(f"App ID: {app_id}")

    version = get_app_store_version(app_id)
    version_id = version["id"]
    version_string = version["attributes"]["versionString"]
    print(f"Version: {version_string}")

    # Get localizations
    version_locs = get_version_localizations(version_id)
    print(f"Found {len(version_locs)} localizations")

    locales_to_process = []

    if args.locale:
        if args.locale in version_locs:
            locales_to_process = [args.locale]
        else:
            print(f"Locale not found: {args.locale}")
            print(f"Available: {', '.join(sorted(version_locs.keys()))}")
            sys.exit(1)
    elif args.all:
        locales_to_process = sorted(version_locs.keys())
    else:
        # Default: just en-US
        if "en-US" in version_locs:
            locales_to_process = ["en-US"]
        else:
            parser.print_help()
            sys.exit(1)

    success_count = 0
    fail_count = 0

    for locale in locales_to_process:
        print(f"\n{'='*50}")
        print(f"Processing: {locale}")
        print(f"{'='*50}")

        try:
            loc_id = version_locs[locale]["id"]
            upload_ipad_screenshots_for_locale(loc_id, locale)
            print(f"✅ Completed: {locale}")
            success_count += 1
        except Exception as e:
            print(f"❌ Failed: {locale} - {e}")
            fail_count += 1

        time.sleep(1)

    print(f"\n{'='*50}")
    print(f"Summary: {success_count} succeeded, {fail_count} failed")
    print(f"{'='*50}")


if __name__ == "__main__":
    main()
