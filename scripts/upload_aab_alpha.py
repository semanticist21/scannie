#!/usr/bin/env python3
"""
Google Play Alpha Track AAB Uploader
Uploads App Bundle to internal/alpha track with release notes.
"""

import os
import sys
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# Configuration
PACKAGE_NAME = "com.kobbokkom.scannie"
SERVICE_ACCOUNT_JSON = "/Users/semanticist/Documents/API/simple-anzan-3e199a55a5b1.json"
PROJECT_ROOT = Path(__file__).parent.parent
AAB_PATH = PROJECT_ROOT / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"

# Google Play API scopes
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']

# Release notes (multi-language)
RELEASE_NOTES = {
    'en-US': """What's New in v1.0.2:
- Fixed duplicate image download issue with loading indicator
- Improved photo permission handling for iOS
- Updated translations for 75 languages
- Bug fixes and performance improvements""",
    'ko-KR': """v1.0.2 업데이트:
- 이미지 중복 다운로드 문제 수정 및 로딩 표시 추가
- iOS 사진 권한 처리 개선
- 75개 언어 번역 업데이트
- 버그 수정 및 성능 개선"""
}


def get_play_service():
    """Create authenticated Google Play Developer API service."""
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_JSON,
        scopes=SCOPES
    )
    return build('androidpublisher', 'v3', credentials=credentials)


def upload_aab_to_alpha(track_name: str = 'alpha'):
    """Upload AAB to specified track (alpha, beta, internal, production)."""

    if not AAB_PATH.exists():
        print(f"❌ AAB file not found: {AAB_PATH}")
        print("   Run 'flutter build appbundle' first")
        return False

    print(f"\n{'='*60}")
    print(f"🚀 Google Play {track_name.upper()} Track Upload")
    print(f"📱 Package: {PACKAGE_NAME}")
    print(f"📦 AAB: {AAB_PATH}")
    print(f"📊 Size: {AAB_PATH.stat().st_size / 1024 / 1024:.1f} MB")
    print(f"{'='*60}")

    service = get_play_service()

    # 1. Create edit
    print("\n📝 Creating edit...")
    edit_request = service.edits().insert(
        packageName=PACKAGE_NAME,
        body={}
    ).execute()
    edit_id = edit_request['id']
    print(f"✅ Edit ID: {edit_id}")

    # 2. Upload AAB
    print(f"\n📤 Uploading AAB...")
    media = MediaFileUpload(
        str(AAB_PATH),
        mimetype='application/octet-stream',
        resumable=True
    )

    bundle_response = service.edits().bundles().upload(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        media_body=media
    ).execute()

    version_code = bundle_response['versionCode']
    print(f"✅ Uploaded! Version Code: {version_code}")

    # 3. Assign to track with release notes
    print(f"\n🎯 Assigning to {track_name} track...")

    release_notes_list = [
        {'language': lang, 'text': text}
        for lang, text in RELEASE_NOTES.items()
    ]

    track_body = {
        'track': track_name,
        'releases': [{
            'versionCodes': [str(version_code)],
            'status': 'completed',
            'releaseNotes': release_notes_list
        }]
    }

    service.edits().tracks().update(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        track=track_name,
        body=track_body
    ).execute()
    print(f"✅ Assigned to {track_name} track")

    # 4. Commit
    print(f"\n📤 Committing changes...")
    # For production track, changes cannot be sent for review automatically
    # Use changesNotSentForReview=True, then manually send for review from Play Console
    service.edits().commit(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        changesNotSentForReview=(track_name == 'production')
    ).execute()

    print(f"\n{'='*60}")
    print(f"🎉 SUCCESS!")
    print(f"📱 Version Code: {version_code}")
    print(f"🎯 Track: {track_name}")
    print(f"📋 Release Notes: {len(RELEASE_NOTES)} languages")
    print(f"{'='*60}")

    return True


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description='Upload AAB to Google Play Alpha/Beta Track',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python upload_aab_alpha.py              # Upload to alpha (default)
  python upload_aab_alpha.py --track beta # Upload to beta
  python upload_aab_alpha.py --track internal  # Upload to internal testing
        """
    )
    parser.add_argument(
        '--track',
        default='alpha',
        choices=['internal', 'alpha', 'beta', 'production'],
        help='Release track (default: alpha)'
    )

    args = parser.parse_args()

    success = upload_aab_to_alpha(args.track)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
