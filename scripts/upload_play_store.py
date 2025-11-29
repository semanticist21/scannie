#!/usr/bin/env python3
"""
Google Play Store Metadata and Image Uploader
Uploads store listings and promotional images one language at a time.
"""

import os
import sys
import xml.etree.ElementTree as ET
import subprocess
import tempfile
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# Configuration
PACKAGE_NAME = "com.kobbokkom.scannie"
SERVICE_ACCOUNT_JSON = "/Users/semanticist/Documents/API/simple-anzan-3e199a55a5b1.json"
PROJECT_ROOT = Path(__file__).parent.parent
METADATA_DIR = PROJECT_ROOT / "store" / "metadata" / "android"
PROMO_DIR = PROJECT_ROOT / "store" / "screenshots" / "promotions" / "android" / "lang"

# Google Play API scopes
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']


def get_play_service():
    """Create authenticated Google Play Developer API service."""
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_JSON,
        scopes=SCOPES
    )
    return build('androidpublisher', 'v3', credentials=credentials)


def parse_metadata_xml(xml_path: Path) -> dict:
    """Parse metadata XML file and return title, short_description, full_description."""
    # Read file and escape unescaped & characters
    content = xml_path.read_text(encoding='utf-8')
    # Replace & with &amp; but not already escaped entities
    import re
    content = re.sub(r'&(?!amp;|lt;|gt;|quot;|apos;|#)', '&amp;', content)

    root = ET.fromstring(content)

    return {
        'title': root.find('title').text.strip() if root.find('title') is not None else None,
        'short_description': root.find('short-description').text.strip() if root.find('short-description') is not None else None,
        'full_description': root.find('full-description').text.strip() if root.find('full-description') is not None else None,
    }


def convert_svg_to_png(svg_path: Path, output_path: Path, width: int = 1024, height: int = 500):
    """Convert SVG to PNG using rsvg-convert."""
    subprocess.run([
        'rsvg-convert',
        '-w', str(width),
        '-h', str(height),
        str(svg_path),
        '-o', str(output_path)
    ], check=True)


def upload_single_language(lang_code: str):
    """Upload metadata and image for a single language."""
    print(f"\n{'='*60}")
    print(f"🚀 Uploading: {lang_code}")
    print(f"{'='*60}")

    # Create service
    service = get_play_service()

    # Create new edit
    print("📝 Creating new edit...")
    edit_request = service.edits().insert(
        packageName=PACKAGE_NAME,
        body={}
    ).execute()
    edit_id = edit_request['id']
    print(f"✅ Edit ID: {edit_id}")

    success = True

    # 1. Upload metadata
    xml_path = METADATA_DIR / f"{lang_code}.xml"
    if xml_path.exists():
        print(f"\n📄 Uploading metadata...")
        metadata = parse_metadata_xml(xml_path)

        listing_body = {}
        if metadata.get('title'):
            listing_body['title'] = metadata['title'][:30]  # Google Play limit: 30 chars
            print(f"   Title: {metadata['title'][:30]}")
        if metadata.get('short_description'):
            listing_body['shortDescription'] = metadata['short_description'][:80]
            print(f"   Short: {metadata['short_description'][:40]}...")
        if metadata.get('full_description'):
            listing_body['fullDescription'] = metadata['full_description'][:4000]
            print(f"   Full: {len(metadata['full_description'])} chars")

        try:
            service.edits().listings().update(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                language=lang_code,
                body=listing_body
            ).execute()
            print("   ✅ Metadata uploaded")
        except Exception as e:
            print(f"   ❌ Metadata failed: {e}")
            success = False
    else:
        print(f"⚠️  No metadata file found")

    # 2. Upload feature graphic
    promo_svg = PROMO_DIR / lang_code / "promo_1.svg"
    if promo_svg.exists():
        print(f"\n🖼️  Uploading feature graphic...")
        with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as tmp:
            png_path = Path(tmp.name)

        try:
            convert_svg_to_png(promo_svg, png_path)
            print(f"   Converted: {promo_svg.name} → PNG")

            # Delete existing
            try:
                service.edits().images().deleteall(
                    packageName=PACKAGE_NAME,
                    editId=edit_id,
                    language=lang_code,
                    imageType='featureGraphic'
                ).execute()
            except Exception:
                pass

            # Upload
            media = MediaFileUpload(str(png_path), mimetype='image/png')
            service.edits().images().upload(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                language=lang_code,
                imageType='featureGraphic',
                media_body=media
            ).execute()
            print("   ✅ Feature graphic uploaded")

        except Exception as e:
            print(f"   ❌ Image failed: {e}")
            success = False
        finally:
            if png_path.exists():
                png_path.unlink()
    else:
        print(f"⚠️  No promo image found")

    # Commit
    print(f"\n📤 Committing...")
    try:
        service.edits().commit(
            packageName=PACKAGE_NAME,
            editId=edit_id
        ).execute()
        print(f"✅ {lang_code} committed successfully!")
        return True
    except Exception as e:
        print(f"❌ Commit failed: {e}")
        return False


def main():
    """Main entry point."""
    print("🚀 Google Play Store Uploader (One by One)")
    print(f"📱 Package: {PACKAGE_NAME}")

    # Get all available languages
    languages = sorted([f.stem for f in METADATA_DIR.glob("*.xml")])
    print(f"📋 Found {len(languages)} languages")

    if len(sys.argv) > 1:
        # Upload specific language
        lang = sys.argv[1]
        if lang in languages:
            upload_single_language(lang)
        elif lang == "--list":
            print("\nAvailable languages:")
            for i, l in enumerate(languages, 1):
                print(f"  {i:2}. {l}")
        elif lang == "--all":
            # Upload all languages one by one
            for i, l in enumerate(languages, 1):
                print(f"\n[{i}/{len(languages)}]")
                upload_single_language(l)
        else:
            print(f"❌ Unknown language: {lang}")
            print("Use --list to see available languages")
    else:
        print("\nUsage:")
        print("  python upload_play_store.py <lang-code>  # Upload single language")
        print("  python upload_play_store.py --list      # List all languages")
        print("  python upload_play_store.py --all       # Upload all languages")
        print("\nExample:")
        print("  python upload_play_store.py en-US")
        print("  python upload_play_store.py ko-KR")


if __name__ == "__main__":
    main()
