#!/bin/bash
# ============================================================
# Google Play Store 남은 언어 업로드
# ============================================================
#
# 📅 할당량 리셋: PST 자정 = 한국 시간 오후 5시
#
# ⚠️  Daily save quota exceeded 에러 발생 시:
#     → 오후 5시 이후에 다시 실행
#
# 💡 배치 모드로 할당량 1개만 사용!
#    (기존: 36개 언어 × 36 commit = 36 할당량)
#    (현재: 36개 언어 × 1 commit = 1 할당량)
#
# ============================================================

# ✅ 완료된 언어 (35개):
# en-US, ko-KR, af, ar, az-AZ, be, bg, bn-BD, ca, cs-CZ
# da-DK, de-DE, el-GR, es-ES, et, eu-ES, fa, fi-FI, fil, fr-FR
# gl-ES, gu, hi-IN, hr, hu-HU, hy-AM, id, is-IS, it-IT, iw-IL
# ja-JP, ka-GE, kk, km-KH, kn-IN

# ❌ 미지원:
# am-ET (암하라어 - Google Play 미지원)

# ⏳ 남은 언어 (35개) - 아래 명령어로 한 번에 업로드

cd "$(dirname "$0")/.."

echo "🚀 남은 언어 배치 업로드 (할당량 1개 사용)"
echo "📅 할당량 리셋: 한국 시간 오후 5시"
echo ""

python3 scripts/upload_play_store.py --remaining
