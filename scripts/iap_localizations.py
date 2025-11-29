#!/usr/bin/env python3
"""
Add IAP localizations for all supported languages
"""

import sys
sys.path.insert(0, '.')
from manage_iap import api_post, api_get, BASE_URL_V1, BASE_URL_V2

IAP_ID = '6755902740'

# Translations for "Remove Ads" and description (max 55 chars each)
TRANSLATIONS = {
    # Already exists: "en-US"
    "ar-SA": ("إزالة الإعلانات", "إزالة جميع الإعلانات نهائياً."),
    "ca": ("Eliminar anuncis", "Elimina tots els anuncis permanentment."),
    "cs": ("Odstranit reklamy", "Odstraňte všechny reklamy natrvalo."),
    "da": ("Fjern annoncer", "Fjern alle annoncer permanent."),
    "de-DE": ("Werbung entfernen", "Alle Werbung dauerhaft entfernen."),
    "el": ("Αφαίρεση διαφημίσεων", "Αφαιρέστε όλες τις διαφημίσεις μόνιμα."),
    "en-AU": ("Remove Ads", "Remove all ads permanently."),
    "en-CA": ("Remove Ads", "Remove all ads permanently."),
    "en-GB": ("Remove Ads", "Remove all ads permanently."),
    "es-ES": ("Quitar anuncios", "Elimina todos los anuncios permanentemente."),
    "es-MX": ("Quitar anuncios", "Elimina todos los anuncios permanentemente."),
    "fi": ("Poista mainokset", "Poista kaikki mainokset pysyvästi."),
    "fr-CA": ("Supprimer les pubs", "Supprimez toutes les publicités."),
    "fr-FR": ("Supprimer les pubs", "Supprimez toutes les publicités."),
    "he": ("הסרת פרסומות", "הסר את כל הפרסומות לצמיתות."),
    "hi": ("विज्ञापन हटाएं", "सभी विज्ञापन स्थायी रूप से हटाएं।"),
    "hr": ("Ukloni oglase", "Trajno uklonite sve oglase."),
    "hu": ("Hirdetések eltávolítása", "Távolítsa el az összes hirdetést végleg."),
    "id": ("Hapus Iklan", "Hapus semua iklan secara permanen."),
    "it": ("Rimuovi pubblicità", "Rimuovi tutta la pubblicità per sempre."),
    "ja": ("広告を削除", "すべての広告を永久に削除します。"),
    "ko": ("광고 제거", "모든 광고를 영구적으로 제거합니다."),
    "ms": ("Alih Keluar Iklan", "Alih keluar semua iklan secara kekal."),
    "nl-NL": ("Advertenties verwijderen", "Verwijder alle advertenties permanent."),
    "no": ("Fjern annonser", "Fjern alle annonser permanent."),
    "pl": ("Usuń reklamy", "Usuń wszystkie reklamy na stałe."),
    "pt-BR": ("Remover anúncios", "Remova todos os anúncios permanentemente."),
    "pt-PT": ("Remover anúncios", "Remova todos os anúncios permanentemente."),
    "ro": ("Elimină reclamele", "Elimină toate reclamele permanent."),
    "ru": ("Удалить рекламу", "Удалите всю рекламу навсегда."),
    "sk": ("Odstrániť reklamy", "Odstráňte všetky reklamy natrvalo."),
    "sv": ("Ta bort annonser", "Ta bort alla annonser permanent."),
    "th": ("ลบโฆษณา", "ลบโฆษณาทั้งหมดอย่างถาวร"),
    "tr": ("Reklamları Kaldır", "Tüm reklamları kalıcı olarak kaldırın."),
    "uk": ("Видалити рекламу", "Видаліть всю рекламу назавжди."),
    "vi": ("Xóa quảng cáo", "Xóa tất cả quảng cáo vĩnh viễn."),
    "zh-Hans": ("移除广告", "永久移除所有广告。"),
    "zh-Hant": ("移除廣告", "永久移除所有廣告。"),
}

def create_localization(locale: str, name: str, description: str) -> bool:
    """Create IAP localization for a locale"""
    data = {
        'data': {
            'type': 'inAppPurchaseLocalizations',
            'attributes': {
                'locale': locale,
                'name': name,
                'description': description
            },
            'relationships': {
                'inAppPurchaseV2': {
                    'data': {
                        'type': 'inAppPurchases',
                        'id': IAP_ID
                    }
                }
            }
        }
    }

    try:
        api_post('/inAppPurchaseLocalizations', data, base_url=BASE_URL_V1)
        return True
    except Exception as e:
        print(f"    Error: {e}")
        return False


def get_existing_locales() -> set:
    """Get existing localization locales"""
    response = api_get(f'/inAppPurchases/{IAP_ID}/inAppPurchaseLocalizations', base_url=BASE_URL_V2)
    locs = response.get('data', [])
    return {loc['attributes']['locale'] for loc in locs}


if __name__ == "__main__":
    print("🔍 Checking existing localizations...")
    existing = get_existing_locales()
    print(f"   Found {len(existing)} existing: {', '.join(sorted(existing))}")

    print(f"\n📝 Adding {len(TRANSLATIONS)} localizations...")

    success = 0
    skipped = 0
    failed = 0

    for locale, (name, desc) in TRANSLATIONS.items():
        if locale in existing:
            print(f"   ⏭️  {locale}: already exists")
            skipped += 1
            continue

        print(f"   🌐 {locale}: {name}...", end=" ")

        if create_localization(locale, name, desc):
            print("✅")
            success += 1
        else:
            print("❌")
            failed += 1

    print(f"\n📊 Results:")
    print(f"   ✅ Added: {success}")
    print(f"   ⏭️  Skipped: {skipped}")
    print(f"   ❌ Failed: {failed}")
