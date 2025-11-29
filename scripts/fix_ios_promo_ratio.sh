#!/bin/bash
# iOS 프로모션 이미지 6.9" 비율로 수정
# 375x812 → 375x815 (높이 +3px)

IOS_PROMO_DIR="store/screenshots/promotions/ios/lang"

cd "$(dirname "$0")/.."

echo "🔧 iOS 프로모션 이미지 6.9\" 비율로 수정 중..."

for lang_dir in "$IOS_PROMO_DIR"/*/; do
    lang=$(basename "$lang_dir")
    
    for promo in "$lang_dir"promo_*.svg; do
        if [ -f "$promo" ]; then
            # viewBox와 height 수정: 812 → 815, 상단으로 1.5px 이동
            sed -i '' \
                -e 's/width="375" height="812"/width="375" height="815"/g' \
                -e 's/viewBox="0 0 375 812"/viewBox="0 -1.5 375 815"/g' \
                "$promo"
        fi
    done
    echo "  ✓ $lang"
done

echo "✅ 완료!"
