#!/usr/bin/env python3
"""
Google Play Store Metadata and Image Uploader
Uploads store listings and promotional images.

배치 모드: 모든 언어를 한 번의 edit에 업로드하고 1회 commit (할당량 1개만 사용)
단일 모드: 언어 하나씩 업로드
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
FEATURE_GRAPHIC = PROJECT_ROOT / "store" / "screenshots" / "graphic" / "feature_graphic.png"

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
    content = xml_path.read_text(encoding='utf-8')
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


def ensure_24bit_png(input_path: Path, output_path: Path = None):
    """Convert PNG to 24-bit RGB (no alpha) for Google Play compatibility.

    Google Play requires 24-bit PNG (no alpha) for screenshots and feature graphics.
    This removes alpha channel and converts to 8-bit/channel RGB.
    """
    if output_path is None:
        output_path = input_path

    # Use sips (macOS built-in) to convert to RGB without alpha
    subprocess.run([
        'sips',
        '-s', 'format', 'png',
        '-s', 'formatOptions', 'best',
        '--setProperty', 'format', 'png',
        str(input_path),
        '--out', str(output_path)
    ], check=True, capture_output=True)

    # Flatten to remove alpha and ensure 24-bit using ImageMagick if available
    try:
        subprocess.run([
            'convert',
            str(output_path),
            '-background', 'white',
            '-alpha', 'remove',
            '-alpha', 'off',
            '-depth', '8',
            str(output_path)
        ], check=True, capture_output=True)
    except FileNotFoundError:
        # ImageMagick not installed, try with sips only
        pass


def delete_feature_graphic_for_language(service, edit_id: str, lang_code: str) -> bool:
    """Delete feature graphic for a specific language."""
    try:
        service.edits().images().deleteall(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            language=lang_code,
            imageType='featureGraphic'
        ).execute()
        return True
    except Exception:
        return False


def upload_feature_graphic(service, edit_id: str) -> bool:
    """Upload feature graphic for en-US only (shared across all languages).

    Requirements: 1024 x 500 pixels, 24-bit PNG (no alpha), max 1MB
    """
    if not FEATURE_GRAPHIC.exists():
        print("     ⚠️  No feature_graphic.png")
        return False

    try:
        # Delete existing
        delete_feature_graphic_for_language(service, edit_id, 'en-US')

        # Convert to 24-bit PNG for Google Play compatibility
        with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as tmp:
            tmp_path = Path(tmp.name)

        try:
            ensure_24bit_png(FEATURE_GRAPHIC, tmp_path)
            media = MediaFileUpload(str(tmp_path), mimetype='image/png')
            service.edits().images().upload(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                language='en-US',
                imageType='featureGraphic',
                media_body=media
            ).execute()
            print("     ✅ Feature Graphic (en-US)")
            return True
        finally:
            if tmp_path.exists():
                tmp_path.unlink()
    except Exception as e:
        print(f"     ❌ Feature Graphic: {e}")
        return False


def upload_language(service, edit_id: str, lang_code: str, skip_screenshots: bool = False) -> bool:
    """Upload metadata and image for a single language within an existing edit."""
    print(f"\n  📌 {lang_code}")
    success = True

    # 1. Upload metadata
    xml_path = METADATA_DIR / f"{lang_code}.xml"
    if xml_path.exists():
        metadata = parse_metadata_xml(xml_path)

        listing_body = {}
        if metadata.get('title'):
            listing_body['title'] = metadata['title'][:30]
        if metadata.get('short_description'):
            listing_body['shortDescription'] = metadata['short_description'][:80]
        if metadata.get('full_description'):
            listing_body['fullDescription'] = metadata['full_description'][:4000]

        try:
            service.edits().listings().update(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                language=lang_code,
                body=listing_body
            ).execute()
            print(f"     ✅ Metadata")
        except Exception as e:
            print(f"     ❌ Metadata: {e}")
            success = False
    else:
        print(f"     ⚠️  No metadata")

    # 2. Delete feature graphic for this language (en-US will be the only one with it)
    #    This cleans up any incorrectly uploaded graphics per language
    if lang_code != 'en-US':
        if delete_feature_graphic_for_language(service, edit_id, lang_code):
            print(f"     🗑️  Feature Graphic deleted (using en-US fallback)")

    # 3. Upload phone screenshots (promo_1~4.svg → PNG)
    if skip_screenshots:
        print(f"     ⏭️  Screenshots skipped")
        return success

    promo_dir = PROMO_DIR / lang_code
    if promo_dir.exists():
        # Delete existing phone screenshots
        try:
            service.edits().images().deleteall(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                language=lang_code,
                imageType='phoneScreenshots'
            ).execute()
        except Exception:
            pass

        screenshot_count = 0
        for i in range(1, 5):  # promo_1 ~ promo_4
            promo_svg = promo_dir / f"promo_{i}.svg"
            if promo_svg.exists():
                with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as tmp:
                    png_path = Path(tmp.name)

                try:
                    # Phone screenshots: 1080x1920 (9:16 ratio)
                    convert_svg_to_png(promo_svg, png_path, width=1080, height=1920)

                    media = MediaFileUpload(str(png_path), mimetype='image/png')
                    service.edits().images().upload(
                        packageName=PACKAGE_NAME,
                        editId=edit_id,
                        language=lang_code,
                        imageType='phoneScreenshots',
                        media_body=media
                    ).execute()
                    screenshot_count += 1

                except Exception as e:
                    print(f"     ❌ Screenshot {i}: {e}")
                    success = False
                finally:
                    if png_path.exists():
                        png_path.unlink()

        if screenshot_count > 0:
            print(f"     ✅ Screenshots ({screenshot_count})")
        else:
            print(f"     ⚠️  No screenshots")
    else:
        print(f"     ⚠️  No promo dir")

    return success


def upload_batch(languages: list, skip_screenshots: bool = False):
    """Upload multiple languages in a single edit (1 quota usage)."""
    print(f"\n{'='*60}")
    print(f"🚀 배치 업로드: {len(languages)}개 언어")
    if skip_screenshots:
        print(f"📷 스크린샷 업로드 건너뜀 (메타데이터만)")
    print(f"💡 할당량 1개만 사용합니다!")
    print(f"{'='*60}")

    service = get_play_service()

    # Create single edit
    print("\n📝 Edit 생성...")
    edit_request = service.edits().insert(
        packageName=PACKAGE_NAME,
        body={}
    ).execute()
    edit_id = edit_request['id']
    print(f"✅ Edit ID: {edit_id}")

    # Upload Feature Graphic for en-US only (fallback for all languages)
    print(f"\n🖼️  Feature Graphic 업로드 (en-US만)...")
    upload_feature_graphic(service, edit_id)

    # Upload all languages (metadata + delete feature graphic + screenshots)
    print(f"\n📤 언어별 업로드 중...")
    success_count = 0
    fail_count = 0

    for i, lang in enumerate(languages, 1):
        print(f"\n[{i}/{len(languages)}]", end="")
        if upload_language(service, edit_id, lang, skip_screenshots=skip_screenshots):
            success_count += 1
        else:
            fail_count += 1

    # Commit once
    print(f"\n\n{'='*60}")
    print(f"📤 Commit 중... (할당량 1개 사용)")
    try:
        service.edits().commit(
            packageName=PACKAGE_NAME,
            editId=edit_id
        ).execute()
        print(f"✅ 성공! {success_count}개 언어 업로드 완료")
        if fail_count > 0:
            print(f"⚠️  {fail_count}개 언어 실패")
        return True
    except Exception as e:
        print(f"❌ Commit 실패: {e}")
        return False


def upload_single_language(lang_code: str):
    """Upload metadata and image for a single language (legacy mode)."""
    print(f"\n{'='*60}")
    print(f"🚀 단일 업로드: {lang_code}")
    print(f"{'='*60}")

    service = get_play_service()

    print("📝 Edit 생성...")
    edit_request = service.edits().insert(
        packageName=PACKAGE_NAME,
        body={}
    ).execute()
    edit_id = edit_request['id']
    print(f"✅ Edit ID: {edit_id}")

    # Upload feature graphic if en-US
    if lang_code == 'en-US':
        print(f"\n🖼️  Feature Graphic 업로드...")
        upload_feature_graphic(service, edit_id)

    upload_language(service, edit_id, lang_code)

    print(f"\n📤 Commit 중...")
    try:
        service.edits().commit(
            packageName=PACKAGE_NAME,
            editId=edit_id
        ).execute()
        print(f"✅ {lang_code} 완료!")
        return True
    except Exception as e:
        print(f"❌ Commit 실패: {e}")
        return False


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description='Google Play Store Metadata and Image Uploader',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
예시:
  python upload_play_store.py --all                    # 모든 언어 (메타데이터 + 스크린샷)
  python upload_play_store.py --all --skip-screenshots # 모든 언어 (메타데이터만)
  python upload_play_store.py ko-KR                    # 단일 언어
  python upload_play_store.py --batch ko-KR en-US      # 특정 언어들만
  python upload_play_store.py --list                   # 언어 목록
        """
    )
    parser.add_argument('language', nargs='?', help='업로드할 언어 코드 (예: ko-KR)')
    parser.add_argument('--all', action='store_true', help='모든 언어 배치 업로드 (할당량 1개)')
    parser.add_argument('--batch', nargs='+', metavar='LANG', help='특정 언어들 배치 업로드')
    parser.add_argument('--list', action='store_true', help='사용 가능한 언어 목록')
    parser.add_argument('--skip-screenshots', action='store_true', help='스크린샷 업로드 건너뜀 (메타데이터만)')

    args = parser.parse_args()

    print("🚀 Google Play Store Uploader")
    print(f"📱 Package: {PACKAGE_NAME}")

    # Get all available languages
    languages = sorted([f.stem for f in METADATA_DIR.glob("*.xml")])
    print(f"📋 {len(languages)}개 언어 발견")

    if args.list:
        print("\n사용 가능한 언어:")
        for i, lang in enumerate(languages, 1):
            print(f"  {i:2}. {lang}")
        return

    if args.all:
        upload_batch(languages, skip_screenshots=args.skip_screenshots)
        return

    if args.batch:
        valid_langs = [l for l in args.batch if l in languages]
        invalid_langs = [l for l in args.batch if l not in languages]
        if invalid_langs:
            print(f"⚠️  유효하지 않은 언어: {', '.join(invalid_langs)}")
        if valid_langs:
            upload_batch(valid_langs, skip_screenshots=args.skip_screenshots)
        else:
            print("❌ 유효한 언어가 없습니다")
        return

    if args.language:
        if args.language in languages:
            upload_single_language(args.language)
        else:
            print(f"❌ 알 수 없는 언어: {args.language}")
            print("--list로 언어 목록 확인")
        return

    # No arguments - show help
    parser.print_help()


if __name__ == "__main__":
    main()
