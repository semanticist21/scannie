#!/usr/bin/env python3
"""
App Store Connect API - Submit for Review Script
Cancel pending review, update build, and resubmit for review.
"""

import sys
import time
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


def generate_token():
    """Generate JWT token for App Store Connect API."""
    private_key = PRIVATE_KEY_PATH.read_text()

    now = datetime.utcnow()
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + timedelta(minutes=20),
        "aud": "appstoreconnect-v1"
    }

    return jwt.encode(
        payload,
        private_key,
        algorithm="ES256",
        headers={"kid": KEY_ID}
    )


def get_headers():
    """Get request headers with auth token."""
    return {
        "Authorization": f"Bearer {generate_token()}",
        "Content-Type": "application/json"
    }


def get_app_id():
    """Get app ID from bundle identifier."""
    print("🔍 Finding app...")
    resp = requests.get(
        f"{BASE_URL}/apps",
        headers=get_headers(),
        params={"filter[bundleId]": BUNDLE_ID}
    )
    resp.raise_for_status()
    data = resp.json()

    if not data["data"]:
        raise ValueError(f"App not found: {BUNDLE_ID}")

    app_id = data["data"][0]["id"]
    app_name = data["data"][0]["attributes"]["name"]
    print(f"✅ Found: {app_name} (ID: {app_id})")
    return app_id


def get_app_store_version(app_id):
    """Get the current editable App Store version."""
    print("\n🔍 Finding App Store version...")
    resp = requests.get(
        f"{BASE_URL}/apps/{app_id}/appStoreVersions",
        headers=get_headers(),
        params={
            "filter[appStoreState]": "READY_FOR_SALE,PENDING_DEVELOPER_RELEASE,WAITING_FOR_REVIEW,IN_REVIEW,PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED",
            "limit": 5
        }
    )
    resp.raise_for_status()
    data = resp.json()

    for version in data["data"]:
        state = version["attributes"]["appStoreState"]
        version_string = version["attributes"]["versionString"]
        print(f"   Found version {version_string}: {state}")

        # Return the version that's in review or ready to submit
        if state in ["WAITING_FOR_REVIEW", "IN_REVIEW", "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED"]:
            return version

    # If no editable version, check for one being prepared
    resp = requests.get(
        f"{BASE_URL}/apps/{app_id}/appStoreVersions",
        headers=get_headers(),
        params={"limit": 5}
    )
    resp.raise_for_status()
    data = resp.json()

    for version in data["data"]:
        state = version["attributes"]["appStoreState"]
        if state != "READY_FOR_SALE":
            return version

    raise ValueError("No editable App Store version found")


def cancel_review_submission(version_id):
    """Cancel pending review submission."""
    print("\n🛑 Cancelling pending review...")

    # Get app store version submission
    resp = requests.get(
        f"{BASE_URL}/appStoreVersions/{version_id}/appStoreVersionSubmission",
        headers=get_headers()
    )

    if resp.status_code == 404:
        print("   No pending submission to cancel")
        return True

    resp.raise_for_status()
    submission = resp.json()

    if "data" in submission and submission["data"]:
        submission_id = submission["data"]["id"]

        # Delete the submission to cancel review
        delete_resp = requests.delete(
            f"{BASE_URL}/appStoreVersionSubmissions/{submission_id}",
            headers=get_headers()
        )

        if delete_resp.status_code in [200, 204]:
            print("✅ Review cancelled")
            return True
        else:
            print(f"⚠️ Could not cancel: {delete_resp.status_code}")
            print(f"   {delete_resp.text}")

    return True


def get_available_builds(app_id):
    """Get list of available builds for the app."""
    print("\n🔍 Getting available builds...")
    resp = requests.get(
        f"{BASE_URL}/builds",
        headers=get_headers(),
        params={
            "filter[app]": app_id,
            "filter[processingState]": "VALID",
            "sort": "-uploadedDate",
            "limit": 10
        }
    )
    resp.raise_for_status()
    data = resp.json()

    builds = []
    for build in data["data"]:
        version = build["attributes"]["version"]
        uploaded = build["attributes"]["uploadedDate"]
        processing = build["attributes"]["processingState"]
        builds.append({
            "id": build["id"],
            "version": version,
            "uploaded": uploaded,
            "state": processing
        })
        print(f"   Build {version}: {processing} (uploaded: {uploaded[:10]})")

    return builds


def update_version_build(version_id, build_id):
    """Update the App Store version to use a specific build."""
    print(f"\n🔄 Updating version to use build...")

    resp = requests.patch(
        f"{BASE_URL}/appStoreVersions/{version_id}",
        headers=get_headers(),
        json={
            "data": {
                "type": "appStoreVersions",
                "id": version_id,
                "relationships": {
                    "build": {
                        "data": {
                            "type": "builds",
                            "id": build_id
                        }
                    }
                }
            }
        }
    )

    if resp.status_code in [200, 204]:
        print("✅ Build updated")
        return True
    else:
        print(f"⚠️ Could not update build: {resp.status_code}")
        print(f"   {resp.text}")
        return False


def submit_for_review(app_id, version_id):
    """Submit the App Store version for review using new reviewSubmissions API."""
    print("\n📤 Submitting for review...")

    # New API: use reviewSubmissions endpoint
    resp = requests.post(
        f"{BASE_URL}/reviewSubmissions",
        headers=get_headers(),
        json={
            "data": {
                "type": "reviewSubmissions",
                "attributes": {
                    "platform": "IOS"
                },
                "relationships": {
                    "app": {
                        "data": {
                            "type": "apps",
                            "id": app_id
                        }
                    }
                }
            }
        }
    )

    if resp.status_code in [200, 201]:
        print("✅ Submitted for review!")
        return True
    else:
        print(f"❌ Failed to submit: {resp.status_code}")
        print(f"   {resp.text}")

        # Try legacy API as fallback
        print("\n🔄 Trying legacy API...")
        resp2 = requests.post(
            f"{BASE_URL}/appStoreVersionSubmissions",
            headers=get_headers(),
            json={
                "data": {
                    "type": "appStoreVersionSubmissions",
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
        )

        if resp2.status_code in [200, 201]:
            print("✅ Submitted for review (legacy API)!")
            return True
        else:
            print(f"❌ Legacy API also failed: {resp2.status_code}")
            return False


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description='Submit app for App Store review',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python submit_app_store_review.py              # Auto-select latest build
  python submit_app_store_review.py --build 40   # Use specific build version
  python submit_app_store_review.py --cancel-only  # Only cancel pending review
        """
    )
    parser.add_argument('--build', type=str, help='Specific build version to use')
    parser.add_argument('--cancel-only', action='store_true', help='Only cancel pending review')

    args = parser.parse_args()

    print("=" * 60)
    print("🍎 App Store Connect - Review Submission")
    print(f"📱 Bundle ID: {BUNDLE_ID}")
    print("=" * 60)

    try:
        # 1. Get app ID
        app_id = get_app_id()

        # 2. Get current App Store version
        version = get_app_store_version(app_id)
        version_id = version["id"]
        version_string = version["attributes"]["versionString"]
        state = version["attributes"]["appStoreState"]

        print(f"\n📦 Working with version {version_string} (state: {state})")

        # 3. Cancel pending review if needed
        if state in ["WAITING_FOR_REVIEW", "IN_REVIEW"]:
            cancel_review_submission(version_id)
            time.sleep(2)  # Wait for state to update

        if args.cancel_only:
            print("\n✅ Cancel only mode - done!")
            return 0

        # 4. Get available builds
        builds = get_available_builds(app_id)

        if not builds:
            print("❌ No valid builds found!")
            return 1

        # 5. Select build
        if args.build:
            target_build = next((b for b in builds if b["version"] == args.build), None)
            if not target_build:
                print(f"❌ Build {args.build} not found!")
                return 1
        else:
            target_build = builds[0]  # Latest build

        print(f"\n🎯 Selected build: {target_build['version']}")

        # 6. Update version to use selected build
        if not update_version_build(version_id, target_build["id"]):
            print("⚠️ Continuing anyway...")

        time.sleep(2)  # Wait for state to update

        # 7. Submit for review
        if submit_for_review(app_id, version_id):
            print("\n" + "=" * 60)
            print("🎉 SUCCESS!")
            print(f"📱 Version: {version_string}")
            print(f"🏗️ Build: {target_build['version']}")
            print("📤 Status: Submitted for Review")
            print("=" * 60)
            return 0
        else:
            return 1

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
