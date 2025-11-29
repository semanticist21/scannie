#!/usr/bin/env python3
"""
Update IAP localizations with friendly marketing copy (카카오/토스 style)
"""

import sys
import requests
sys.path.insert(0, '.')
from manage_iap import get_headers, api_get, BASE_URL_V1, BASE_URL_V2

IAP_ID = '6755902740'

# Friendly marketing translations (카카오/토스 style)
# name: "Remove Ads" / "광고 제거" 스타일 유지
# description: 토스체 (~요/~어요) + 혜택 중심 (55자 제한)
TRANSLATIONS = {
    "en-US": ("Remove Ads", "Pay once and enjoy ad-free scanning forever."),
    "en-AU": ("Remove Ads", "Pay once and enjoy ad-free scanning forever."),
    "en-CA": ("Remove Ads", "Pay once and enjoy ad-free scanning forever."),
    "en-GB": ("Remove Ads", "Pay once and enjoy ad-free scanning forever."),
    "ko": ("광고 제거", "한 번만 결제하면 광고 없이 쓸 수 있어요."),
    "ja": ("広告を削除", "一度お支払いいただければ広告なしで使えます。"),
    "zh-Hans": ("移除广告", "只需付款一次，即可永久无广告使用。"),
    "zh-Hant": ("移除廣告", "只需付款一次，即可永久無廣告使用。"),
    "de-DE": ("Werbung entfernen", "Einmal zahlen, für immer werbefrei nutzen."),
    "fr-FR": ("Supprimer les pubs", "Payez une fois et profitez sans pub pour toujours."),
    "fr-CA": ("Supprimer les pubs", "Payez une fois et profitez sans pub pour toujours."),
    "es-ES": ("Quitar anuncios", "Paga una vez y disfruta sin anuncios para siempre."),
    "es-MX": ("Quitar anuncios", "Paga una vez y disfruta sin anuncios para siempre."),
    "it": ("Rimuovi pubblicità", "Paga una volta e usa senza pubblicità per sempre."),
    "pt-BR": ("Remover anúncios", "Pague uma vez e use sem anúncios para sempre."),
    "pt-PT": ("Remover anúncios", "Pague uma vez e use sem anúncios para sempre."),
    "ru": ("Удалить рекламу", "Заплатите один раз и пользуйтесь без рекламы."),
    "ar-SA": ("إزالة الإعلانات", "ادفع مرة واحدة واستمتع بدون إعلانات للأبد."),
    "he": ("הסרת פרסומות", "שלמו פעם אחת והשתמשו בלי פרסומות לנצח."),
    "hi": ("विज्ञापन हटाएं", "एक बार भुगतान करें और हमेशा विज्ञापन-मुक्त उपयोग करें।"),
    "th": ("ลบโฆษณา", "จ่ายครั้งเดียว ใช้งานไม่มีโฆษณาตลอดไป"),
    "vi": ("Xóa quảng cáo", "Thanh toán một lần, dùng mãi không có quảng cáo."),
    "id": ("Hapus Iklan", "Bayar sekali, pakai tanpa iklan selamanya."),
    "ms": ("Buang Iklan", "Bayar sekali, guna tanpa iklan selama-lamanya."),
    "tr": ("Reklamları Kaldır", "Bir kez ödeyin, sonsuza dek reklamsız kullanın."),
    "pl": ("Usuń reklamy", "Zapłać raz i korzystaj bez reklam na zawsze."),
    "nl-NL": ("Advertenties verwijderen", "Betaal eenmalig en gebruik zonder reclame."),
    "sv": ("Ta bort annonser", "Betala en gång och använd reklamfritt för alltid."),
    "da": ("Fjern annoncer", "Betal én gang og brug reklamefrit for evigt."),
    "no": ("Fjern annonser", "Betal én gang og bruk reklamefritt for alltid."),
    "fi": ("Poista mainokset", "Maksa kerran ja käytä mainoksetta ikuisesti."),
    "cs": ("Odstranit reklamy", "Zaplaťte jednou a používejte navždy bez reklam."),
    "sk": ("Odstrániť reklamy", "Zaplaťte raz a používajte navždy bez reklám."),
    "hu": ("Hirdetések eltávolítása", "Fizessen egyszer és használja örökre reklámmentes."),
    "ro": ("Elimină reclamele", "Plătiți o dată și folosiți fără reclame mereu."),
    "el": ("Αφαίρεση διαφημίσεων", "Πληρώστε μία φορά, χρησιμοποιήστε χωρίς διαφημίσεις."),
    "hr": ("Ukloni oglase", "Platite jednom i koristite zauvijek bez oglasa."),
    "uk": ("Видалити рекламу", "Сплатіть один раз і користуйтесь без реклами."),
    "ca": ("Eliminar anuncis", "Pagueu un cop i feu servir sense anuncis sempre."),
}


def api_patch(endpoint: str, data: dict, base_url: str = BASE_URL_V1) -> dict:
    """Make PATCH request to App Store Connect API"""
    url = f"{base_url}{endpoint}"
    response = requests.patch(url, headers=get_headers(), json=data)

    if response.status_code not in [200, 201]:
        print(f"Error PATCH {url}: {response.status_code}")
        print(response.text)
        raise Exception(f"API error: {response.status_code}")

    return response.json()


def update_localization(loc_id: str, name: str, description: str) -> bool:
    """Update IAP localization"""
    data = {
        'data': {
            'type': 'inAppPurchaseLocalizations',
            'id': loc_id,
            'attributes': {
                'name': name,
                'description': description
            }
        }
    }

    try:
        api_patch(f'/inAppPurchaseLocalizations/{loc_id}', data)
        return True
    except Exception as e:
        print(f"    Error: {e}")
        return False


def get_localizations() -> dict:
    """Get all localizations with their IDs"""
    response = api_get(f'/inAppPurchases/{IAP_ID}/inAppPurchaseLocalizations', base_url=BASE_URL_V2)
    locs = response.get('data', [])
    return {loc['attributes']['locale']: loc['id'] for loc in locs}


if __name__ == "__main__":
    print("🔍 Fetching existing localizations...")
    loc_map = get_localizations()
    print(f"   Found {len(loc_map)} localizations")

    print(f"\n✨ Updating to friendly marketing copy...")

    success = 0
    failed = 0
    skipped = 0

    for locale, (name, desc) in TRANSLATIONS.items():
        if locale not in loc_map:
            print(f"   ⏭️  {locale}: not found, skipping")
            skipped += 1
            continue

        loc_id = loc_map[locale]
        print(f"   🌐 {locale}: {name}...", end=" ")

        if update_localization(loc_id, name, desc):
            print("✅")
            success += 1
        else:
            print("❌")
            failed += 1

    print(f"\n📊 Results:")
    print(f"   ✅ Updated: {success}")
    print(f"   ⏭️  Skipped: {skipped}")
    print(f"   ❌ Failed: {failed}")
