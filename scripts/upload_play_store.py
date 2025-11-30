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


def upload_feature_graphic(service, edit_id: str) -> bool:
    """Upload feature graphic for en-US only (shared across all languages)."""
    if not FEATURE_GRAPHIC.exists():
        print("     ⚠️  No feature_graphic.png")
        return False

    try:
        # Delete existing
        try:
            service.edits().images().deleteall(
                packageName=PACKAGE_NAME,
                editId=edit_id,
                language='en-US',
                imageType='featureGraphic'
            ).execute()
        except Exception:
            pass

        media = MediaFileUpload(str(FEATURE_GRAPHIC), mimetype='image/png')
        service.edits().images().upload(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            language='en-US',
            imageType='featureGraphic',
            media_body=media
        ).execute()
        print("     ✅ Feature Graphic (en-US)")
        return True
    except Exception as e:
        print(f"     ❌ Feature Graphic: {e}")
        return False


def upload_language(service, edit_id: str, lang_code: str) -> bool:
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

    # 2. Upload phone screenshots (promo_1~4.svg → PNG)
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


def upload_batch(languages: list):
    """Upload multiple languages in a single edit (1 quota usage)."""
    print(f"\n{'='*60}")
    print(f"🚀 배치 업로드: {len(languages)}개 언어")
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

    # Upload feature graphic (en-US only, shared)
    print(f"\n🖼️  Feature Graphic 업로드...")
    upload_feature_graphic(service, edit_id)

    # Upload all languages
    print(f"\n📤 언어별 업로드 중...")
    success_count = 0
    fail_count = 0

    for i, lang in enumerate(languages, 1):
        print(f"\n[{i}/{len(languages)}]", end="")
        if upload_language(service, edit_id, lang):
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
    print("🚀 Google Play Store Uploader")
    print(f"📱 Package: {PACKAGE_NAME}")

    # Get all available languages
    languages = sorted([f.stem for f in METADATA_DIR.glob("*.xml")])
    print(f"📋 {len(languages)}개 언어 발견")

    if len(sys.argv) > 1:
        arg = sys.argv[1]

        if arg == "--list":
            print("\n사용 가능한 언어:")
            for i, l in enumerate(languages, 1):
                print(f"  {i:2}. {l}")

        elif arg == "--all":
            # 배치 모드: 모든 언어를 한 번에 (할당량 1개)
            upload_batch(languages)

        elif arg == "--batch":
            # 특정 언어들만 배치로
            if len(sys.argv) > 2:
                batch_langs = sys.argv[2:]
                valid_langs = [l for l in batch_langs if l in languages]
                if valid_langs:
                    upload_batch(valid_langs)
                else:
                    print("❌ 유효한 언어가 없습니다")
            else:
                print("❌ 언어를 지정해주세요")
                print("예: python upload_play_store.py --batch ko-KR en-US ja-JP")

        elif arg == "--remaining":
            # upload_remaining.sh에 있는 남은 언어들 배치로
            remaining = [
                "ky-KG", "lo-LA", "lt", "lv", "mk-MK", "ml-IN", "mn-MN", "mr-IN",
                "ms-MY", "my-MM", "ne-NP", "nl-NL", "no-NO", "pa", "pl-PL", "pt-BR",
                "ro", "ru-RU", "si-LK", "sk", "sl", "sq", "sr", "sv-SE", "sw",
                "ta-IN", "te-IN", "th", "tr-TR", "uk", "ur", "uz", "vi", "zh-CN", "zu"
            ]
            # 실제 존재하는 언어만 필터링
            valid_remaining = [l for l in remaining if l in languages]
            print(f"⏳ 남은 언어: {len(valid_remaining)}개")
            upload_batch(valid_remaining)

        elif arg in languages:
            # 단일 언어 업로드
            upload_single_language(arg)
        else:
            print(f"❌ 알 수 없는 옵션/언어: {arg}")
            print("--list로 언어 목록 확인")
    else:
        print("\n사용법:")
        print("  python upload_play_store.py <lang>       # 단일 언어 (할당량 1개)")
        print("  python upload_play_store.py --all        # 모든 언어 배치 (할당량 1개)")
        print("  python upload_play_store.py --remaining  # 남은 36개 배치 (할당량 1개)")
        print("  python upload_play_store.py --batch <언어들>  # 특정 언어들 배치")
        print("  python upload_play_store.py --list       # 언어 목록")
        print("\n예:")
        print("  python upload_play_store.py ko-KR")
        print("  python upload_play_store.py --remaining")


if __name__ == "__main__":
    main()
