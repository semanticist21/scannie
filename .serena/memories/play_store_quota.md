# Google Play Store API 할당량 메모

## Daily Save Quota
- Google Play Developer API는 **일일 저장(commit) 할당량**이 있음
- 초과 시 `403: Daily save quota exceeded` 에러 발생
- **리셋 시간**: PST 자정 = **한국 시간 오후 5시**

## 해결 방법
배치 처리로 할당량 1개만 사용하도록 스크립트 수정됨:
```bash
# 남은 언어 한 번에 업로드 (할당량 1개)
python3 scripts/upload_play_store.py --remaining

# 전체 언어 업로드 (할당량 1개)
python3 scripts/upload_play_store.py --all
```

## 업로드 현황 (2024-11-29 기준)
- ✅ 완료: 35개 언어
- ❌ 미지원: am-ET (암하라어)
- ⏳ 남은 언어: 35개
  - ky-KG, lo-LA, lt, lv, mk-MK, ml-IN, mn-MN, mr-IN
  - ms-MY, my-MM, ne-NP, nl-NL, no-NO, pa, pl-PL, pt-BR
  - ro, ru-RU, si-LK, sk, sl, sq, sr, sv-SE, sw
  - ta-IN, te-IN, th, tr-TR, uk, ur, uz, vi, zh-CN, zu

## 할당량 증가 요청
Google Cloud Console에서 요청 가능하나, 일반적으로 승인 안 됨.
배치 처리가 현실적인 해결책.
