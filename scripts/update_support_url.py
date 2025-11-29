#!/usr/bin/env python3
"""
App Store Connect API - Support URL Bulk Update Script
Updates support URL for all version localizations
"""

import json
import time
import sys
from pathlib import Path
from datetime import datetime, timezone, timedelta

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

# Support URL to set for all locales
SUPPORT_URL = "https://kobbokkom.com/forum"

# All iOS App Store Connect locales
ALL_LOCALES = [
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

    now = datetime.now(timezone.utc)
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

    # Find editable version
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
    """Get all version localizations"""
    response = api_get(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    localizations = {}
    for loc in response.get("data", []):
        locale = loc["attributes"]["locale"]
        localizations[locale] = loc
    return localizations


def update_support_url(localization_id: str, support_url: str) -> dict:
    """Update support URL for a version localization"""
    data = {
        "data": {
            "type": "appStoreVersionLocalizations",
            "id": localization_id,
            "attributes": {
                "supportUrl": support_url
            }
        }
    }
    return api_patch(f"/appStoreVersionLocalizations/{localization_id}", data)


def create_version_localization_with_support_url(version_id: str, locale: str, support_url: str) -> dict:
    """Create a new version localization with support URL"""
    data = {
        "data": {
            "type": "appStoreVersionLocalizations",
            "attributes": {
                "locale": locale,
                "supportUrl": support_url
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


# ============================================================
# Main Function
# ============================================================

def main():
    print("=" * 60)
    print(f"🔗 Setting Support URL for all locales")
    print(f"   URL: {SUPPORT_URL}")
    print("=" * 60)

    try:
        # Get app info
        app_id = get_app_id()
        print(f"\n📱 App ID: {app_id}")

        # Get editable version
        version = get_app_store_version(app_id)
        version_id = version["id"]
        version_string = version["attributes"]["versionString"]
        version_state = version["attributes"]["appStoreState"]
        print(f"📦 Version: {version_string} ({version_state})")
        print(f"🆔 Version ID: {version_id}")

        # Get existing localizations
        existing_locs = get_version_localizations(version_id)
        print(f"📍 Found {len(existing_locs)} existing localizations")

        success_count = 0
        fail_count = 0

        for locale in ALL_LOCALES:
            try:
                if locale in existing_locs:
                    # Update existing localization
                    loc_id = existing_locs[locale]["id"]
                    current_url = existing_locs[locale]["attributes"].get("supportUrl", "")

                    if current_url == SUPPORT_URL:
                        print(f"  ⏭️  {locale}: Already set")
                        success_count += 1
                        continue

                    update_support_url(loc_id, SUPPORT_URL)
                    print(f"  ✅ {locale}: Updated")
                else:
                    # Create new localization
                    create_version_localization_with_support_url(version_id, locale, SUPPORT_URL)
                    print(f"  ✅ {locale}: Created")

                success_count += 1
                time.sleep(0.3)  # Rate limiting

            except requests.exceptions.HTTPError as e:
                print(f"  ❌ {locale}: HTTP Error - {e}")
                if e.response is not None:
                    try:
                        error_detail = e.response.json()
                        errors = error_detail.get("errors", [])
                        for err in errors:
                            print(f"      {err.get('detail', err)}")
                    except:
                        pass
                fail_count += 1
            except Exception as e:
                print(f"  ❌ {locale}: {e}")
                fail_count += 1

        print("\n" + "=" * 60)
        print(f"✅ Summary: {success_count} succeeded, {fail_count} failed")
        print("=" * 60)

        return fail_count == 0

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
