#!/bin/bash

# iOS App Store Promotional Images - Regenerate with shorter text
# Maximum ~20 characters per line to prevent overflow

BASE_DIR="/Users/semanticist/Documents/code/scannie/store/screenshots/promotions"
IOS_DIR="$BASE_DIR/ios"
LANG_DIR="$IOS_DIR/lang"
SRC_DIR="$BASE_DIR"

create_lang_svgs() {
    local lang=$1
    local t1_l1=$2  # promo1 line1
    local t1_l2=$3  # promo1 line2
    local t2_l1=$4  # promo2 line1
    local t2_l2=$5  # promo2 line2
    local t3_l1=$6  # promo3 line1
    local t3_l2=$7  # promo3 line2
    local t4_l1=$8  # promo4 line1
    local t4_l2=$9  # promo4 line2

    local lang_path="$LANG_DIR/$lang"
    mkdir -p "$lang_path"

    # Promo 1
    cp "$SRC_DIR/promo_1.svg" "$lang_path/promo_1.svg"
    sed -i '' "s|>Scan documents and</text>|>$t1_l1</text>|g" "$lang_path/promo_1.svg"
    sed -i '' "s|>combine into one PDF</text>|>$t1_l2</text>|g" "$lang_path/promo_1.svg"

    # Promo 2
    cp "$SRC_DIR/promo_2.svg" "$lang_path/promo_2.svg"
    sed -i '' "s|>Auto edge detection</text>|>$t2_l1</text>|g" "$lang_path/promo_2.svg"
    sed -i '' "s|>with smart cropping</text>|>$t2_l2</text>|g" "$lang_path/promo_2.svg"

    # Promo 3
    cp "$SRC_DIR/promo_3.svg" "$lang_path/promo_3.svg"
    sed -i '' "s|>Organize, preview,</text>|>$t3_l1</text>|g" "$lang_path/promo_3.svg"
    sed -i '' "s|>and export easily</text>|>$t3_l2</text>|g" "$lang_path/promo_3.svg"

    # Promo 4
    cp "$SRC_DIR/promo_4.svg" "$lang_path/promo_4.svg"
    sed -i '' "s|>Edit, reorder, and</text>|>$t4_l1</text>|g" "$lang_path/promo_4.svg"
    sed -i '' "s|>manage pages freely</text>|>$t4_l2</text>|g" "$lang_path/promo_4.svg"

    echo "Created: $lang"
}

# Arabic
create_lang_svgs "ar" \
    "امسح المستندات" \
    "وادمجها في PDF" \
    "كشف الحواف تلقائياً" \
    "مع قص ذكي" \
    "نظّم واستعرض" \
    "وصدّر بسهولة" \
    "حرر ورتّب" \
    "وأدر بحرية"

# Catalan
create_lang_svgs "ca" \
    "Escaneja documents" \
    "i combina en PDF" \
    "Detecció automàtica" \
    "amb retall intel·ligent" \
    "Organitza i visualitza" \
    "exporta fàcilment" \
    "Edita i reordena" \
    "gestiona lliurement"

# Chinese Simplified
create_lang_svgs "zh-Hans" \
    "扫描文档" \
    "合并为PDF" \
    "自动边缘检测" \
    "智能裁剪" \
    "整理、预览" \
    "轻松导出" \
    "编辑、排序" \
    "自由管理"

# Chinese Traditional
create_lang_svgs "zh-Hant" \
    "掃描文件" \
    "合併為PDF" \
    "自動邊緣偵測" \
    "智慧裁剪" \
    "整理、預覽" \
    "輕鬆匯出" \
    "編輯、排序" \
    "自由管理"

# Croatian
create_lang_svgs "hr" \
    "Skeniraj dokumente" \
    "spoji u jedan PDF" \
    "Auto detekcija rubova" \
    "pametno izrezivanje" \
    "Organiziraj, pregledaj" \
    "i lako izvezi" \
    "Uredi, promijeni red" \
    "upravljaj slobodno"

# Czech
create_lang_svgs "cs" \
    "Skenujte dokumenty" \
    "sloučte do PDF" \
    "Auto detekce okrajů" \
    "s chytrým ořezem" \
    "Organizujte, prohlížejte" \
    "snadno exportujte" \
    "Upravujte, řaďte" \
    "spravujte volně"

# Danish
create_lang_svgs "da" \
    "Scan dokumenter" \
    "kombiner til én PDF" \
    "Auto kantgenkendelse" \
    "smart beskæring" \
    "Organiser, forhåndsvis" \
    "eksporter nemt" \
    "Rediger, omarranger" \
    "administrer frit"

# Dutch
create_lang_svgs "nl" \
    "Scan documenten" \
    "combineer tot PDF" \
    "Auto randdetectie" \
    "slim bijsnijden" \
    "Organiseer, bekijk" \
    "exporteer eenvoudig" \
    "Bewerk, herschik" \
    "beheer vrij"

# English (Australia)
create_lang_svgs "en-AU" \
    "Scan documents and" \
    "combine into one PDF" \
    "Auto edge detection" \
    "with smart cropping" \
    "Organise, preview," \
    "and export easily" \
    "Edit, reorder, and" \
    "manage pages freely"

# English (Canada)
create_lang_svgs "en-CA" \
    "Scan documents and" \
    "combine into one PDF" \
    "Auto edge detection" \
    "with smart cropping" \
    "Organize, preview," \
    "and export easily" \
    "Edit, reorder, and" \
    "manage pages freely"

# English (UK)
create_lang_svgs "en-GB" \
    "Scan documents and" \
    "combine into one PDF" \
    "Auto edge detection" \
    "with smart cropping" \
    "Organise, preview," \
    "and export easily" \
    "Edit, reorder, and" \
    "manage pages freely"

# English (US)
create_lang_svgs "en-US" \
    "Scan documents and" \
    "combine into one PDF" \
    "Auto edge detection" \
    "with smart cropping" \
    "Organize, preview," \
    "and export easily" \
    "Edit, reorder, and" \
    "manage pages freely"

# Finnish
create_lang_svgs "fi" \
    "Skannaa asiakirjat" \
    "yhdistä PDF:ksi" \
    "Automaattinen tunnistus" \
    "älykäs rajaus" \
    "Järjestä, esikatsele" \
    "vie helposti" \
    "Muokkaa, järjestä" \
    "hallitse vapaasti"

# French (France)
create_lang_svgs "fr-FR" \
    "Numérisez et" \
    "combinez en PDF" \
    "Détection auto" \
    "recadrage intelligent" \
    "Organisez, aperçu" \
    "exportez facilement" \
    "Modifiez, réorganisez" \
    "gérez librement"

# French (Canada)
create_lang_svgs "fr-CA" \
    "Numérisez et" \
    "combinez en PDF" \
    "Détection auto" \
    "recadrage intelligent" \
    "Organisez, aperçu" \
    "exportez facilement" \
    "Modifiez, réorganisez" \
    "gérez librement"

# German
create_lang_svgs "de-DE" \
    "Dokumente scannen" \
    "zu PDF verbinden" \
    "Auto-Kantenerkennung" \
    "Smart-Zuschnitt" \
    "Organisieren, Vorschau" \
    "einfach exportieren" \
    "Bearbeiten, sortieren" \
    "frei verwalten"

# Greek
create_lang_svgs "el" \
    "Σάρωση εγγράφων" \
    "συνδυασμός σε PDF" \
    "Αυτόματη ανίχνευση" \
    "έξυπνη περικοπή" \
    "Οργάνωση, προεπισκόπηση" \
    "εύκολη εξαγωγή" \
    "Επεξεργασία, αναδιάταξη" \
    "ελεύθερη διαχείριση"

# Hebrew
create_lang_svgs "he" \
    "סרוק מסמכים" \
    "שלב ל-PDF אחד" \
    "זיהוי קצוות אוטומטי" \
    "חיתוך חכם" \
    "ארגן, תצוגה מקדימה" \
    "ייצא בקלות" \
    "ערוך, סדר מחדש" \
    "נהל בחופשיות"

# Hindi
create_lang_svgs "hi" \
    "दस्तावेज़ स्कैन करें" \
    "PDF में जोड़ें" \
    "ऑटो एज डिटेक्शन" \
    "स्मार्ट क्रॉपिंग" \
    "व्यवस्थित करें, देखें" \
    "आसानी से निर्यात" \
    "संपादित करें, क्रम बदलें" \
    "स्वतंत्र रूप से प्रबंधित"

# Hungarian
create_lang_svgs "hu" \
    "Dokumentumok szkennelése" \
    "egyesítés PDF-be" \
    "Auto éldetektálás" \
    "intelligens vágás" \
    "Rendszerezés, előnézet" \
    "egyszerű exportálás" \
    "Szerkesztés, átrendezés" \
    "szabad kezelés"

# Indonesian
create_lang_svgs "id" \
    "Pindai dokumen" \
    "gabung jadi satu PDF" \
    "Deteksi tepi otomatis" \
    "pemotongan cerdas" \
    "Atur, pratinjau" \
    "ekspor dengan mudah" \
    "Edit, urutkan ulang" \
    "kelola dengan bebas"

# Italian
create_lang_svgs "it" \
    "Scansiona documenti" \
    "uniscili in un PDF" \
    "Rilevamento auto bordi" \
    "ritaglio intelligente" \
    "Organizza, anteprima" \
    "esporta facilmente" \
    "Modifica, riordina" \
    "gestisci liberamente"

# Japanese
create_lang_svgs "ja" \
    "ドキュメントをスキャン" \
    "1つのPDFに結合" \
    "自動エッジ検出" \
    "スマートクロップ" \
    "整理、プレビュー" \
    "簡単にエクスポート" \
    "編集、並べ替え" \
    "自由にページ管理"

# Korean
create_lang_svgs "ko" \
    "문서를 스캔하고" \
    "하나의 PDF로 합치세요" \
    "자동 문서 감지" \
    "스마트 자동 크롭" \
    "정리, 미리보기" \
    "간편한 내보내기" \
    "편집, 순서 변경" \
    "페이지 자유롭게 관리"

# Malay
create_lang_svgs "ms" \
    "Imbas dokumen" \
    "gabung ke satu PDF" \
    "Pengesanan tepi auto" \
    "pemangkasan pintar" \
    "Susun, pratonton" \
    "eksport dengan mudah" \
    "Edit, susun semula" \
    "urus dengan bebas"

# Norwegian
create_lang_svgs "no" \
    "Skann dokumenter" \
    "kombiner til én PDF" \
    "Auto kantgjenkjenning" \
    "smart beskjæring" \
    "Organiser, forhåndsvis" \
    "eksporter enkelt" \
    "Rediger, omorganiser" \
    "administrer fritt"

# Polish
create_lang_svgs "pl" \
    "Skanuj dokumenty" \
    "połącz w jeden PDF" \
    "Wykrywanie krawędzi" \
    "inteligentne przycinanie" \
    "Organizuj, podgląd" \
    "łatwy eksport" \
    "Edytuj, zmieniaj kolejność" \
    "zarządzaj swobodnie"

# Portuguese (Brazil)
create_lang_svgs "pt-BR" \
    "Digitalize documentos" \
    "combine em um PDF" \
    "Detecção auto de bordas" \
    "corte inteligente" \
    "Organize, visualize" \
    "exporte facilmente" \
    "Edite, reordene" \
    "gerencie livremente"

# Portuguese (Portugal)
create_lang_svgs "pt-PT" \
    "Digitalize documentos" \
    "combine num PDF" \
    "Deteção auto de bordas" \
    "recorte inteligente" \
    "Organize, pré-visualize" \
    "exporte facilmente" \
    "Edite, reordene" \
    "faça a gestão livre"

# Romanian
create_lang_svgs "ro" \
    "Scanează documente" \
    "combină într-un PDF" \
    "Detectare auto margini" \
    "decupare inteligentă" \
    "Organizează, previzualizează" \
    "exportă ușor" \
    "Editează, reordonează" \
    "gestionează liber"

# Russian
create_lang_svgs "ru" \
    "Сканируйте документы" \
    "объединяйте в PDF" \
    "Автоопределение краёв" \
    "умная обрезка" \
    "Организуй и смотри" \
    "легко экспортируй" \
    "Редактируй, сортируй" \
    "управляй свободно"

# Slovak
create_lang_svgs "sk" \
    "Skenujte dokumenty" \
    "spojte do PDF" \
    "Auto detekcia okrajov" \
    "inteligentný orez" \
    "Organizujte, prezerajte" \
    "jednoducho exportujte" \
    "Upravujte, meňte poradie" \
    "spravujte voľne"

# Spanish (Mexico)
create_lang_svgs "es-MX" \
    "Escanea documentos" \
    "combina en un PDF" \
    "Detección auto de bordes" \
    "recorte inteligente" \
    "Organiza, previsualiza" \
    "exporta fácilmente" \
    "Edita, reordena" \
    "gestiona libremente"

# Spanish (Spain)
create_lang_svgs "es-ES" \
    "Escanea documentos" \
    "combina en un PDF" \
    "Detección auto de bordes" \
    "recorte inteligente" \
    "Organiza, previsualiza" \
    "exporta fácilmente" \
    "Edita, reordena" \
    "gestiona libremente"

# Swedish
create_lang_svgs "sv" \
    "Skanna dokument" \
    "kombinera till en PDF" \
    "Auto kantdetektering" \
    "smart beskärning" \
    "Organisera, förhandsgranska" \
    "exportera enkelt" \
    "Redigera, ordna om" \
    "hantera fritt"

# Thai
create_lang_svgs "th" \
    "สแกนเอกสาร" \
    "รวมเป็น PDF เดียว" \
    "ตรวจจับขอบอัตโนมัติ" \
    "ครอบตัดอัจฉริยะ" \
    "จัดระเบียบ, ดูตัวอย่าง" \
    "ส่งออกได้ง่าย" \
    "แก้ไข, เรียงลำดับใหม่" \
    "จัดการได้อิสระ"

# Turkish
create_lang_svgs "tr" \
    "Belgeleri tarayın" \
    "tek PDF'te birleştirin" \
    "Otomatik kenar algılama" \
    "akıllı kırpma" \
    "Düzenleyin, önizleyin" \
    "kolayca dışa aktarın" \
    "Düzenle, yeniden sırala" \
    "özgürce yönet"

# Ukrainian
create_lang_svgs "uk" \
    "Скануйте документи" \
    "об'єднуйте в PDF" \
    "Автовизначення країв" \
    "розумне обрізання" \
    "Організуй, переглядай" \
    "легко експортуй" \
    "Редагуй, сортуй" \
    "керуй вільно"

# Vietnamese
create_lang_svgs "vi" \
    "Quét tài liệu" \
    "kết hợp thành PDF" \
    "Tự động phát hiện cạnh" \
    "cắt thông minh" \
    "Sắp xếp, xem trước" \
    "xuất dễ dàng" \
    "Chỉnh sửa, sắp xếp lại" \
    "quản lý tự do"

echo "Done! Regenerated all 39 languages with shorter text."
