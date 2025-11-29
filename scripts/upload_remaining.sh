#!/bin/bash
# ============================================================
# Google Play Store 남은 언어 업로드 스크립트
# 일일 할당량 초과로 내일 실행해야 함
# ============================================================

# ✅ 완료된 언어 (35개):
# en-US, ko-KR, af, ar, az-AZ, be, bg, bn-BD, ca, cs-CZ
# da-DK, de-DE, el-GR, es-ES, et, eu-ES, fa, fi-FI, fil, fr-FR
# gl-ES, gu, hi-IN, hr, hu-HU, hy-AM, id, is-IS, it-IT, iw-IL
# ja-JP, ka-GE, kk, km-KH, kn-IN

# ❌ 지원 안 됨:
# am-ET (암하라어 - Google Play 미지원)

# ⏳ 남은 언어 (36개):
REMAINING_LANGS=(
  "ky-KG"   # 키르기스어
  "lo-LA"   # 라오어
  "lt"      # 리투아니아어
  "lv"      # 라트비아어
  "mk-MK"   # 마케도니아어
  "ml-IN"   # 말라얄람어
  "mn-MN"   # 몽골어
  "mr-IN"   # 마라티어
  "ms-MY"   # 말레이어
  "my-MM"   # 미얀마어
  "ne-NP"   # 네팔어
  "nl-NL"   # 네덜란드어
  "no-NO"   # 노르웨이어
  "pa"      # 펀자브어
  "pl-PL"   # 폴란드어
  "pt-BR"   # 포르투갈어 (브라질)
  "ro"      # 루마니아어
  "ru-RU"   # 러시아어
  "si-LK"   # 싱할라어
  "sk"      # 슬로바키아어
  "sl"      # 슬로베니아어
  "sq"      # 알바니아어
  "sr"      # 세르비아어
  "sv-SE"   # 스웨덴어
  "sw"      # 스와힐리어
  "ta-IN"   # 타밀어
  "te-IN"   # 텔루구어
  "th"      # 태국어
  "tr-TR"   # 터키어
  "uk"      # 우크라이나어
  "ur"      # 우르두어
  "uz"      # 우즈베크어
  "vi"      # 베트남어
  "zh-CN"   # 중국어 (간체)
  "zu"      # 줄루어
)

cd "$(dirname "$0")/.."

echo "🚀 남은 ${#REMAINING_LANGS[@]}개 언어 업로드 시작"

for lang in "${REMAINING_LANGS[@]}"; do
  echo "=== Uploading $lang ==="
  python3 scripts/upload_play_store.py "$lang"
  sleep 2
done

echo "✅ 완료!"
