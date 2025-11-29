#!/usr/bin/env python3
"""
App Store Connect API - In-App Purchase Management Script
Manages in-app purchases for Scannie iOS app
"""

import json
import sys
from pathlib import Path
from datetime import datetime, timedelta

import jwt
import requests

# ============================================================
# Configuration
# ============================================================

BUNDLE_ID = "com.kobbokkom.scannie"
ISSUER_ID = "a7524762-b1db-463b-84a8-bbee51a37cc2"
KEY_ID = "74HC92L9NA"
PRIVATE_KEY_PATH = Path("/Users/semanticist/Documents/API/AuthKey_74HC92L9NA.p8")

BASE_URL_V1 = "https://api.appstoreconnect.apple.com/v1"
BASE_URL_V2 = "https://api.appstoreconnect.apple.com/v2"

# ============================================================
# JWT Token Generation
# ============================================================

def generate_token() -> str:
    """Generate JWT token for App Store Connect API"""
    private_key = PRIVATE_KEY_PATH.read_text()

    now = datetime.utcnow()
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + timedelta(minutes=19),
        "aud": "appstoreconnect-v1",
    }

    headers = {
        "alg": "ES256",
        "kid": KEY_ID,
        "typ": "JWT",
    }

    token = jwt.encode(payload, private_key, algorithm="ES256", headers=headers)
    return token


def get_headers() -> dict:
    """Get authorization headers"""
    return {
        "Authorization": f"Bearer {generate_token()}",
        "Content-Type": "application/json",
    }


# ============================================================
# API Helpers
# ============================================================

def api_get(endpoint: str, base_url: str = BASE_URL_V1) -> dict:
    """Make GET request to App Store Connect API"""
    url = f"{base_url}{endpoint}"
    response = requests.get(url, headers=get_headers())

    if response.status_code != 200:
        print(f"Error GET {url}: {response.status_code}")
        print(response.text)
        raise Exception(f"API error: {response.status_code}")

    return response.json()


def api_post(endpoint: str, data: dict, base_url: str = BASE_URL_V2) -> dict:
    """Make POST request to App Store Connect API"""
    url = f"{base_url}{endpoint}"
    response = requests.post(url, headers=get_headers(), json=data)

    if response.status_code not in [200, 201]:
        print(f"Error POST {url}: {response.status_code}")
        print(response.text)
        raise Exception(f"API error: {response.status_code}")

    return response.json()


def api_delete(endpoint: str, base_url: str = BASE_URL_V2) -> bool:
    """Make DELETE request to App Store Connect API"""
    url = f"{base_url}{endpoint}"
    response = requests.delete(url, headers=get_headers())

    if response.status_code not in [200, 204]:
        print(f"Error DELETE {url}: {response.status_code}")
        print(response.text)
        return False

    return True


# ============================================================
# App Store Connect Operations
# ============================================================

def get_app_id() -> str:
    """Get app ID by bundle ID"""
    response = api_get(f"/apps?filter[bundleId]={BUNDLE_ID}")
    apps = response.get("data", [])
    if not apps:
        raise ValueError(f"App not found: {BUNDLE_ID}")
    return apps[0]["id"]


def list_in_app_purchases(app_id: str) -> list:
    """List all in-app purchases for the app"""
    response = api_get(f"/apps/{app_id}/inAppPurchasesV2")
    return response.get("data", [])


def delete_in_app_purchase(iap_id: str) -> bool:
    """Delete an in-app purchase by ID"""
    return api_delete(f"/inAppPurchases/{iap_id}")


def create_in_app_purchase(app_id: str, product_id: str, name: str,
                           iap_type: str = "NON_CONSUMABLE",
                           review_note: str = "",
                           family_sharable: bool = False) -> dict:
    """Create a new in-app purchase"""
    data = {
        "data": {
            "type": "inAppPurchases",
            "attributes": {
                "name": name,
                "productId": product_id,
                "inAppPurchaseType": iap_type,
                "reviewNote": review_note,
                "familySharable": family_sharable
            },
            "relationships": {
                "app": {
                    "data": {
                        "type": "apps",
                        "id": app_id
                    }
                }
            }
        }
    }

    return api_post("/inAppPurchases", data)


# ============================================================
# Main Commands
# ============================================================

def cmd_list():
    """List all in-app purchases"""
    print("🔍 Fetching app ID...")
    app_id = get_app_id()
    print(f"   App ID: {app_id}")

    print("\n📦 In-App Purchases:")
    iaps = list_in_app_purchases(app_id)

    if not iaps:
        print("   (none)")
        return

    for iap in iaps:
        attrs = iap["attributes"]
        print(f"   - ID: {iap['id']}")
        print(f"     Product ID: {attrs.get('productId', 'N/A')}")
        print(f"     Name: {attrs.get('name', 'N/A')}")
        print(f"     Type: {attrs.get('inAppPurchaseType', 'N/A')}")
        print(f"     State: {attrs.get('state', 'N/A')}")
        print()


def cmd_delete(product_id: str):
    """Delete an in-app purchase by product ID"""
    print("🔍 Fetching app ID...")
    app_id = get_app_id()

    print(f"📦 Finding IAP with product ID: {product_id}")
    iaps = list_in_app_purchases(app_id)

    target_iap = None
    for iap in iaps:
        if iap["attributes"].get("productId") == product_id:
            target_iap = iap
            break

    if not target_iap:
        print(f"❌ IAP not found: {product_id}")
        return False

    iap_id = target_iap["id"]
    print(f"🗑️  Deleting IAP: {iap_id}")

    if delete_in_app_purchase(iap_id):
        print("✅ Deleted successfully!")
        return True
    else:
        print("❌ Delete failed")
        return False


def cmd_create(product_id: str, name: str):
    """Create a new non-consumable in-app purchase"""
    print("🔍 Fetching app ID...")
    app_id = get_app_id()
    print(f"   App ID: {app_id}")

    print(f"\n📦 Creating IAP:")
    print(f"   Product ID: {product_id}")
    print(f"   Name: {name}")
    print(f"   Type: NON_CONSUMABLE")

    try:
        result = create_in_app_purchase(
            app_id=app_id,
            product_id=product_id,
            name=name,
            iap_type="NON_CONSUMABLE",
            review_note="Remove all ads permanently",
            family_sharable=False
        )

        iap_id = result["data"]["id"]
        print(f"\n✅ Created successfully!")
        print(f"   IAP ID: {iap_id}")
        print(f"\n⚠️  Note: You need to set pricing in App Store Connect manually")
        print(f"   or use the pricing API endpoint.")
        return True

    except Exception as e:
        print(f"\n❌ Failed to create: {e}")
        return False


def get_price_points(iap_id: str, territory: str = "USA") -> list:
    """Get available price points for an IAP"""
    response = api_get(
        f"/inAppPurchases/{iap_id}/pricePoints?filter[territory]={territory}&include=territory",
        base_url=BASE_URL_V2
    )
    return response.get("data", []), response.get("included", [])


def set_price(iap_id: str, price_point_id: str, territory_id: str = "USA") -> dict:
    """Set price for an IAP using price schedule"""
    data = {
        "data": {
            "type": "inAppPurchasePriceSchedules",
            "relationships": {
                "inAppPurchase": {
                    "data": {
                        "type": "inAppPurchases",
                        "id": iap_id
                    }
                },
                "baseTerritory": {
                    "data": {
                        "type": "territories",
                        "id": territory_id
                    }
                },
                "manualPrices": {
                    "data": [
                        {
                            "type": "inAppPurchasePrices",
                            "id": "${price1}"
                        }
                    ]
                }
            }
        },
        "included": [
            {
                "type": "inAppPurchasePrices",
                "id": "${price1}",
                "relationships": {
                    "inAppPurchasePricePoint": {
                        "data": {
                            "type": "inAppPurchasePricePoints",
                            "id": price_point_id
                        }
                    }
                }
            }
        ]
    }

    return api_post("/inAppPurchasePriceSchedules", data, base_url=BASE_URL_V1)


def cmd_set_price(product_id: str, target_price: float):
    """Set price for an IAP"""
    print("🔍 Fetching app ID...")
    app_id = get_app_id()

    print(f"📦 Finding IAP: {product_id}")
    iaps = list_in_app_purchases(app_id)

    target_iap = None
    for iap in iaps:
        if iap["attributes"].get("productId") == product_id:
            target_iap = iap
            break

    if not target_iap:
        print(f"❌ IAP not found: {product_id}")
        return False

    iap_id = target_iap["id"]
    print(f"   IAP ID: {iap_id}")

    print(f"\n💰 Finding price point for ${target_price}...")
    price_points, territories = get_price_points(iap_id, "USA")

    # Find closest price point
    best_match = None
    best_diff = float('inf')

    for pp in price_points:
        customer_price = float(pp["attributes"]["customerPrice"])
        diff = abs(customer_price - target_price)
        if diff < best_diff:
            best_diff = diff
            best_match = pp

    if not best_match:
        print("❌ No price points found")
        return False

    price = best_match["attributes"]["customerPrice"]
    price_point_id = best_match["id"]
    print(f"   Found: ${price} (ID: {price_point_id[:30]}...)")

    print(f"\n⚙️  Setting price...")
    try:
        result = set_price(iap_id, price_point_id, "USA")
        print(f"✅ Price set to ${price}!")
        return True
    except Exception as e:
        print(f"❌ Failed: {e}")
        return False


def print_usage():
    print("""
Usage: python manage_iap.py <command> [args]

Commands:
    list                        List all in-app purchases
    delete <product_id>         Delete an IAP by product ID
    create <product_id> <name>  Create a new non-consumable IAP
    price <product_id> <amount> Set price (e.g., 1.99)

Examples:
    python manage_iap.py list
    python manage_iap.py delete premium_remove_ads
    python manage_iap.py create premium "Remove Ads"
    python manage_iap.py price premium 1.99
""")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)

    command = sys.argv[1]

    if command == "list":
        cmd_list()

    elif command == "delete":
        if len(sys.argv) < 3:
            print("Error: product_id required")
            print_usage()
            sys.exit(1)
        cmd_delete(sys.argv[2])

    elif command == "create":
        if len(sys.argv) < 4:
            print("Error: product_id and name required")
            print_usage()
            sys.exit(1)
        cmd_create(sys.argv[2], sys.argv[3])

    elif command == "price":
        if len(sys.argv) < 4:
            print("Error: product_id and amount required")
            print_usage()
            sys.exit(1)
        cmd_set_price(sys.argv[2], float(sys.argv[3]))

    else:
        print(f"Unknown command: {command}")
        print_usage()
        sys.exit(1)
