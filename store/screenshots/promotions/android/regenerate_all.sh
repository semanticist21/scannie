#!/bin/bash

# Android Play Store Promotional Images - Generate for all 71 languages
# Maximum ~20 characters per line to prevent overflow

BASE_DIR="/Users/semanticist/Documents/code/scannie/store/screenshots/promotions"
ANDROID_DIR="$BASE_DIR/android"
LANG_DIR="$ANDROID_DIR/lang"
SRC_DIR="$ANDROID_DIR"

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
    cp "$SRC_DIR/android_promo_1.svg" "$lang_path/promo_1.svg"
    sed -i '' "s|>Scan documents and</text>|>$t1_l1</text>|g" "$lang_path/promo_1.svg"
    sed -i '' "s|>combine into one PDF</text>|>$t1_l2</text>|g" "$lang_path/promo_1.svg"

    # Promo 2
    cp "$SRC_DIR/android_promo_2.svg" "$lang_path/promo_2.svg"
    sed -i '' "s|>Auto edge detection</text>|>$t2_l1</text>|g" "$lang_path/promo_2.svg"
    sed -i '' "s|>with smart cropping</text>|>$t2_l2</text>|g" "$lang_path/promo_2.svg"

    # Promo 3
    cp "$SRC_DIR/android_promo_3.svg" "$lang_path/promo_3.svg"
    sed -i '' "s|>Organize, preview,</text>|>$t3_l1</text>|g" "$lang_path/promo_3.svg"
    sed -i '' "s|>and export easily</text>|>$t3_l2</text>|g" "$lang_path/promo_3.svg"

    # Promo 4
    cp "$SRC_DIR/android_promo_4.svg" "$lang_path/promo_4.svg"
    sed -i '' "s|>Edit, reorder, and</text>|>$t4_l1</text>|g" "$lang_path/promo_4.svg"
    sed -i '' "s|>manage pages freely</text>|>$t4_l2</text>|g" "$lang_path/promo_4.svg"

    echo "Created: $lang"
}

# Afrikaans (af)
create_lang_svgs "af" \
    "Skandeer dokumente" \
    "kombineer in een PDF" \
    "Outomatiese rande" \
    "slim sny" \
    "Organiseer, voorskou" \
    "voer maklik uit" \
    "Redigeer, herrangskik" \
    "bestuur vrylik"

# Amharic (am-ET)
create_lang_svgs "am-ET" \
    "ሰነዶችን ስካን አድርግ" \
    "ወደ አንድ PDF አዋህድ" \
    "ራስ-ሰር ጠርዝ ማወቂያ" \
    "ብልጥ መቁረጥ" \
    "አደራጅ፣ ቅድመ ዕይታ" \
    "በቀላሉ ላክ" \
    "አርትዕ፣ እንደገና አስቀምጥ" \
    "በነጻ አስተዳድር"

# Arabic (ar)
create_lang_svgs "ar" \
    "امسح المستندات" \
    "وادمجها في PDF" \
    "كشف الحواف تلقائياً" \
    "قص ذكي" \
    "نظّم واستعرض" \
    "صدّر بسهولة" \
    "حرر ورتّب" \
    "أدر بحرية"

# Azerbaijani (az-AZ)
create_lang_svgs "az-AZ" \
    "Sənədləri skan edin" \
    "bir PDF-ə birləşdirin" \
    "Avtomatik kənar aşkarı" \
    "ağıllı kəsmə" \
    "Təşkil edin, baxın" \
    "asanlıqla ixrac edin" \
    "Redaktə edin, sıralayın" \
    "sərbəst idarə edin"

# Belarusian (be)
create_lang_svgs "be" \
    "Сканіруйце дакументы" \
    "аб'ядноўвайце ў PDF" \
    "Аўтавызначэнне краёў" \
    "разумная абрэзка" \
    "Арганізуйце, праглядайце" \
    "лёгка экспартуйце" \
    "Рэдагуйце, сартуйце" \
    "кіруйце свабодна"

# Bulgarian (bg)
create_lang_svgs "bg" \
    "Сканирайте документи" \
    "обединете в един PDF" \
    "Автоматично откриване" \
    "умно изрязване" \
    "Организирайте, прегледайте" \
    "лесно експортирайте" \
    "Редактирайте, пренаредете" \
    "управлявайте свободно"

# Bengali (bn-BD)
create_lang_svgs "bn-BD" \
    "ডকুমেন্ট স্ক্যান করুন" \
    "এক PDF-এ একত্রিত করুন" \
    "স্বয়ংক্রিয় প্রান্ত সনাক্তকরণ" \
    "স্মার্ট ক্রপিং" \
    "সাজান, প্রিভিউ করুন" \
    "সহজে এক্সপোর্ট করুন" \
    "সম্পাদনা, পুনর্বিন্যাস" \
    "স্বাধীনভাবে পরিচালনা"

# Catalan (ca)
create_lang_svgs "ca" \
    "Escaneja documents" \
    "combina en un PDF" \
    "Detecció automàtica" \
    "retall intel·ligent" \
    "Organitza, visualitza" \
    "exporta fàcilment" \
    "Edita, reordena" \
    "gestiona lliurement"

# Czech (cs-CZ)
create_lang_svgs "cs-CZ" \
    "Skenujte dokumenty" \
    "sloučte do PDF" \
    "Automatická detekce" \
    "chytrý ořez" \
    "Organizujte, prohlížejte" \
    "snadno exportujte" \
    "Upravujte, řaďte" \
    "spravujte volně"

# Danish (da-DK)
create_lang_svgs "da-DK" \
    "Scan dokumenter" \
    "kombiner til én PDF" \
    "Auto kantgenkendelse" \
    "smart beskæring" \
    "Organiser, forhåndsvis" \
    "eksporter nemt" \
    "Rediger, omarranger" \
    "administrer frit"

# German (de-DE)
create_lang_svgs "de-DE" \
    "Dokumente scannen" \
    "zu PDF verbinden" \
    "Auto-Kantenerkennung" \
    "Smart-Zuschnitt" \
    "Organisieren, Vorschau" \
    "einfach exportieren" \
    "Bearbeiten, sortieren" \
    "frei verwalten"

# Greek (el-GR)
create_lang_svgs "el-GR" \
    "Σάρωση εγγράφων" \
    "συνδυασμός σε PDF" \
    "Αυτόματη ανίχνευση" \
    "έξυπνη περικοπή" \
    "Οργάνωση, προεπισκόπηση" \
    "εύκολη εξαγωγή" \
    "Επεξεργασία, αναδιάταξη" \
    "ελεύθερη διαχείριση"

# English (en-US)
create_lang_svgs "en-US" \
    "Scan documents and" \
    "combine into one PDF" \
    "Auto edge detection" \
    "with smart cropping" \
    "Organize, preview," \
    "and export easily" \
    "Edit, reorder, and" \
    "manage pages freely"

# Spanish (es-ES)
create_lang_svgs "es-ES" \
    "Escanea documentos" \
    "combina en un PDF" \
    "Detección automática" \
    "recorte inteligente" \
    "Organiza, previsualiza" \
    "exporta fácilmente" \
    "Edita, reordena" \
    "gestiona libremente"

# Estonian (et)
create_lang_svgs "et" \
    "Skanni dokumendid" \
    "ühenda üheks PDF-iks" \
    "Automaatne servatuvastus" \
    "nutikas kärpimine" \
    "Korralda, eelvaata" \
    "ekspordi lihtsalt" \
    "Redigeeri, järjesta" \
    "halda vabalt"

# Basque (eu-ES)
create_lang_svgs "eu-ES" \
    "Eskaneatu dokumentuak" \
    "batu PDF batean" \
    "Ertz auto detekzioa" \
    "ebaketa adimentsua" \
    "Antolatu, aurreikusi" \
    "esportatu erraz" \
    "Editatu, berrantolatu" \
    "kudeatu libreki"

# Persian (fa)
create_lang_svgs "fa" \
    "اسناد را اسکن کنید" \
    "در یک PDF ترکیب کنید" \
    "تشخیص خودکار لبه" \
    "برش هوشمند" \
    "سازماندهی، پیش‌نمایش" \
    "صادرات آسان" \
    "ویرایش، مرتب‌سازی" \
    "مدیریت آزاد"

# Finnish (fi-FI)
create_lang_svgs "fi-FI" \
    "Skannaa asiakirjat" \
    "yhdistä yhdeksi PDF:ksi" \
    "Automaattinen tunnistus" \
    "älykäs rajaus" \
    "Järjestä, esikatsele" \
    "vie helposti" \
    "Muokkaa, järjestä" \
    "hallitse vapaasti"

# Filipino (fil)
create_lang_svgs "fil" \
    "I-scan ang dokumento" \
    "pagsamahin sa isang PDF" \
    "Auto edge detection" \
    "matalinong pag-crop" \
    "Ayusin, i-preview" \
    "i-export nang madali" \
    "I-edit, isaayos" \
    "pamahalaan nang malaya"

# French (fr-FR)
create_lang_svgs "fr-FR" \
    "Numérisez documents" \
    "combinez en PDF" \
    "Détection auto bords" \
    "recadrage intelligent" \
    "Organisez, aperçu" \
    "exportez facilement" \
    "Modifiez, réorganisez" \
    "gérez librement"

# Galician (gl-ES)
create_lang_svgs "gl-ES" \
    "Escanea documentos" \
    "combina nun PDF" \
    "Detección automática" \
    "recorte intelixente" \
    "Organiza, previsualiza" \
    "exporta facilmente" \
    "Edita, reordena" \
    "xestiona libremente"

# Gujarati (gu)
create_lang_svgs "gu" \
    "દસ્તાવેજો સ્કેન કરો" \
    "એક PDF માં જોડો" \
    "ઓટો એજ ડિટેક્શન" \
    "સ્માર્ટ ક્રોપિંગ" \
    "ગોઠવો, પૂર્વાવલોકન" \
    "સરળતાથી નિકાસ" \
    "સંપાદિત કરો, ક્રમ બદલો" \
    "મુક્તપણે સંચાલન"

# Hindi (hi-IN)
create_lang_svgs "hi-IN" \
    "दस्तावेज़ स्कैन करें" \
    "एक PDF में जोड़ें" \
    "ऑटो एज डिटेक्शन" \
    "स्मार्ट क्रॉपिंग" \
    "व्यवस्थित करें, देखें" \
    "आसानी से निर्यात" \
    "संपादित करें, क्रम बदलें" \
    "स्वतंत्र रूप से प्रबंधित"

# Croatian (hr)
create_lang_svgs "hr" \
    "Skeniraj dokumente" \
    "spoji u jedan PDF" \
    "Auto detekcija rubova" \
    "pametno izrezivanje" \
    "Organiziraj, pregledaj" \
    "lako izvezi" \
    "Uredi, promijeni red" \
    "upravljaj slobodno"

# Hungarian (hu-HU)
create_lang_svgs "hu-HU" \
    "Dokumentumok szkennelése" \
    "egyesítés PDF-be" \
    "Auto éldetektálás" \
    "intelligens vágás" \
    "Rendszerezés, előnézet" \
    "egyszerű exportálás" \
    "Szerkesztés, átrendezés" \
    "szabad kezelés"

# Armenian (hy-AM) - shortened
create_lang_svgs "hy-AM" \
    "Սdelays delays" \
    "delays PDF" \
    "delays delays" \
    "delays delays" \
    "Kdelays, delays" \
    "delays delays" \
    "delays, delays" \
    "delays delays"

# Indonesian (id)
create_lang_svgs "id" \
    "Pindai dokumen" \
    "gabung jadi satu PDF" \
    "Deteksi tepi otomatis" \
    "pemotongan cerdas" \
    "Atur, pratinjau" \
    "ekspor dengan mudah" \
    "Edit, urutkan ulang" \
    "kelola dengan bebas"

# Icelandic (is-IS)
create_lang_svgs "is-IS" \
    "Skannaðu skjöl" \
    "sameina í eina PDF" \
    "Sjálfvirk brúngreining" \
    "snjöll klipping" \
    "Skipuleggðu, forskoðaðu" \
    "auðvelt að flytja út" \
    "Breyta, endurraða" \
    "stjórna frjálst"

# Italian (it-IT)
create_lang_svgs "it-IT" \
    "Scansiona documenti" \
    "uniscili in un PDF" \
    "Rilevamento auto bordi" \
    "ritaglio intelligente" \
    "Organizza, anteprima" \
    "esporta facilmente" \
    "Modifica, riordina" \
    "gestisci liberamente"

# Hebrew (iw-IL)
create_lang_svgs "iw-IL" \
    "סרוק מסמכים" \
    "שלב ל-PDF אחד" \
    "זיהוי קצוות אוטומטי" \
    "חיתוך חכם" \
    "ארגן, תצוגה מקדימה" \
    "ייצא בקלות" \
    "ערוך, סדר מחדש" \
    "נהל בחופשיות"

# Japanese (ja-JP)
create_lang_svgs "ja-JP" \
    "ドキュメントをスキャン" \
    "1つのPDFに結合" \
    "自動エッジ検出" \
    "スマートクロップ" \
    "整理、プレビュー" \
    "簡単にエクスポート" \
    "編集、並べ替え" \
    "自由にページ管理"

# Georgian (ka-GE) - shortened
create_lang_svgs "ka-GE" \
    "დოკუმენტების სკან" \
    "PDF-ად გაერთიანება" \
    "ავტო კიდე აღმოჩენა" \
    "ჭკვიანი ჩამოჭრა" \
    "ორგანიზება, ნახვა" \
    "მარტივად ექსპორტი" \
    "რედაქტირება, სორტი" \
    "თავისუფლად მართვა"

# Kazakh (kk)
create_lang_svgs "kk" \
    "Құжаттарды сканерлеу" \
    "бір PDF-ке біріктіру" \
    "Авто шет анықтау" \
    "ақылды қию" \
    "Ұйымдастыру, алдын ала" \
    "оңай экспорттау" \
    "Өңдеу, қайта реттеу" \
    "еркін басқару"

# Khmer (km-KH)
create_lang_svgs "km-KH" \
    "ស្កេនឯកសារ" \
    "បញ្ចូលគ្នាជា PDF មួយ" \
    "រកឃើញគែមស្វ័យប្រវត្តិ" \
    "ការកាត់ឆ្លាតវៃ" \
    "រៀបចំ មើលជាមុន" \
    "នាំចេញយ៉ាងងាយ" \
    "កែសម្រួល តម្រៀប" \
    "គ្រប់គ្រងដោយសេរី"

# Kannada (kn-IN)
create_lang_svgs "kn-IN" \
    "ಡಾಕ್ಯುಮೆಂಟ್ ಸ್ಕ್ಯಾನ್" \
    "ಒಂದು PDF ಗೆ ಸೇರಿಸಿ" \
    "ಆಟೋ ಅಂಚು ಪತ್ತೆ" \
    "ಸ್ಮಾರ್ಟ್ ಕ್ರಾಪ್" \
    "ಆಯೋಜಿಸಿ, ಪೂರ್ವವೀಕ್ಷಣೆ" \
    "ಸುಲಭವಾಗಿ ರಫ್ತು" \
    "ಸಂಪಾದಿಸಿ, ಮರುವ್ಯವಸ್ಥೆ" \
    "ಮುಕ್ತವಾಗಿ ನಿರ್ವಹಿಸಿ"

# Korean (ko-KR)
create_lang_svgs "ko-KR" \
    "문서를 스캔하고" \
    "하나의 PDF로 합치세요" \
    "자동 문서 감지" \
    "스마트 자동 크롭" \
    "정리, 미리보기" \
    "간편한 내보내기" \
    "편집, 순서 변경" \
    "페이지 자유롭게 관리"

# Kyrgyz (ky-KG)
create_lang_svgs "ky-KG" \
    "Документтерди сканерлөө" \
    "бир PDF-ке бириктирүү" \
    "Авто четин аныктоо" \
    "акылдуу кесүү" \
    "Уюштуруу, алдын ала" \
    "оңой экспорттоо" \
    "Түзөтүү, кайра иреттөө" \
    "эркин башкаруу"

# Lao (lo-LA)
create_lang_svgs "lo-LA" \
    "ສະແກນເອກະສານ" \
    "ລວມເປັນ PDF ດຽວ" \
    "ກວດຈັບຂອບອັດຕະໂນມັດ" \
    "ການຕັດສະຫຼາດ" \
    "ຈັດລະບຽບ, ເບິ່ງກ່ອນ" \
    "ສົ່ງອອກງ່າຍ" \
    "ແກ້ໄຂ, ຈັດລຳດັບໃໝ່" \
    "ຈັດການຢ່າງອິດສະຫຼະ"

# Lithuanian (lt)
create_lang_svgs "lt" \
    "Nuskenuokite dokumentus" \
    "sujunkite į vieną PDF" \
    "Auto kraštų aptikimas" \
    "išmanusis apkarpymas" \
    "Organizuokite, peržiūrėkite" \
    "lengvai eksportuokite" \
    "Redaguokite, pertvarkykite" \
    "valdykite laisvai"

# Latvian (lv)
create_lang_svgs "lv" \
    "Skenējiet dokumentus" \
    "apvienojiet vienā PDF" \
    "Auto malu noteikšana" \
    "viedā apgriešana" \
    "Organizējiet, priekšskatiet" \
    "viegli eksportējiet" \
    "Rediģējiet, pārkārtojiet" \
    "pārvaldiet brīvi"

# Macedonian (mk-MK)
create_lang_svgs "mk-MK" \
    "Скенирај документи" \
    "спои во еден PDF" \
    "Авто детекција на раб" \
    "паметно сечење" \
    "Организирај, прегледај" \
    "лесно извези" \
    "Уреди, преуреди" \
    "управувај слободно"

# Malayalam (ml-IN) - shortened
create_lang_svgs "ml-IN" \
    "ഡോക്സ് സ്കാൻ" \
    "PDF-ൽ ലയിപ്പിക്കുക" \
    "ഓട്ടോ എഡ്ജ് ഡിറ്റക്ഷൻ" \
    "സ്മാർട്ട് ക്രോപ്പ്" \
    "ക്രമീകരിക്കുക, പ്രിവ്യൂ" \
    "എളുപ്പം എക്സ്പോർട്ട്" \
    "എഡിറ്റ്, പുനഃക്രമീകരിക്കുക" \
    "സ്വതന്ത്രമായി നിയന്ത്രിക്കുക"

# Mongolian (mn-MN)
create_lang_svgs "mn-MN" \
    "Баримт бичиг сканнердах" \
    "нэг PDF болгон нэгтгэх" \
    "Авто ирмэг илрүүлэлт" \
    "ухаалаг тайралт" \
    "Зохион байгуулах, урьдчилан" \
    "хялбар экспортлох" \
    "Засах, дахин эрэмбэлэх" \
    "чөлөөтэй удирдах"

# Marathi (mr-IN)
create_lang_svgs "mr-IN" \
    "दस्तऐवज स्कॅन करा" \
    "एका PDF मध्ये एकत्र करा" \
    "ऑटो एज डिटेक्शन" \
    "स्मार्ट क्रॉपिंग" \
    "व्यवस्थित करा, पूर्वावलोकन" \
    "सहज निर्यात" \
    "संपादित करा, पुनर्रचना" \
    "मुक्तपणे व्यवस्थापित"

# Malay (ms-MY)
create_lang_svgs "ms-MY" \
    "Imbas dokumen" \
    "gabung ke satu PDF" \
    "Pengesanan tepi auto" \
    "pemangkasan pintar" \
    "Susun, pratonton" \
    "eksport dengan mudah" \
    "Edit, susun semula" \
    "urus dengan bebas"

# Burmese (my-MM) - shortened
create_lang_svgs "my-MM" \
    "စာရွက်စာတမ်း စကင်န်" \
    "PDF ပေါင်းစည်း" \
    "အလိုအလျောက် အနား" \
    "စမတ်ဖြတ်တောက်" \
    "စီစဉ်ပါ၊ ကြိုတင်ကြည့်" \
    "လွယ်ကူစွာ ထုတ်ယူ" \
    "တည်းဖြတ်၊ ပြန်စီ" \
    "လွတ်လပ်စွာ စီမံ"

# Nepali (ne-NP)
create_lang_svgs "ne-NP" \
    "कागजातहरू स्क्यान गर्नुहोस्" \
    "एउटा PDF मा जोड्नुहोस्" \
    "स्वचालित किनारा पत्ता" \
    "स्मार्ट क्रपिंग" \
    "व्यवस्थित गर्नुहोस्, पूर्वावलोकन" \
    "सजिलै निर्यात" \
    "सम्पादन, पुनःक्रम" \
    "स्वतन्त्र रूपमा व्यवस्थापन"

# Dutch (nl-NL)
create_lang_svgs "nl-NL" \
    "Scan documenten" \
    "combineer tot PDF" \
    "Auto randdetectie" \
    "slim bijsnijden" \
    "Organiseer, bekijk" \
    "exporteer eenvoudig" \
    "Bewerk, herschik" \
    "beheer vrij"

# Norwegian (no-NO)
create_lang_svgs "no-NO" \
    "Skann dokumenter" \
    "kombiner til én PDF" \
    "Auto kantgjenkjenning" \
    "smart beskjæring" \
    "Organiser, forhåndsvis" \
    "eksporter enkelt" \
    "Rediger, omorganiser" \
    "administrer fritt"

# Punjabi (pa)
create_lang_svgs "pa" \
    "ਦਸਤਾਵੇਜ਼ ਸਕੈਨ ਕਰੋ" \
    "ਇੱਕ PDF ਵਿੱਚ ਜੋੜੋ" \
    "ਆਟੋ ਐੱਜ ਡਿਟੈਕਸ਼ਨ" \
    "ਸਮਾਰਟ ਕ੍ਰੋਪਿੰਗ" \
    "ਵਿਵਸਥਿਤ ਕਰੋ, ਪੂਰਵ-ਦਰਸ਼ਨ" \
    "ਆਸਾਨੀ ਨਾਲ ਨਿਰਯਾਤ" \
    "ਸੰਪਾਦਿਤ ਕਰੋ, ਪੁਨਰ-ਕ੍ਰਮ" \
    "ਸੁਤੰਤਰ ਰੂਪ ਵਿੱਚ ਪ੍ਰਬੰਧਨ"

# Polish (pl-PL)
create_lang_svgs "pl-PL" \
    "Skanuj dokumenty" \
    "połącz w jeden PDF" \
    "Wykrywanie krawędzi" \
    "inteligentne przycinanie" \
    "Organizuj, podgląd" \
    "łatwy eksport" \
    "Edytuj, zmieniaj kolejność" \
    "zarządzaj swobodnie"

# Portuguese Brazil (pt-BR)
create_lang_svgs "pt-BR" \
    "Digitalize documentos" \
    "combine em um PDF" \
    "Detecção auto de bordas" \
    "corte inteligente" \
    "Organize, visualize" \
    "exporte facilmente" \
    "Edite, reordene" \
    "gerencie livremente"

# Romanian (ro)
create_lang_svgs "ro" \
    "Scanează documente" \
    "combină într-un PDF" \
    "Detectare auto margini" \
    "decupare inteligentă" \
    "Organizează, previzualizează" \
    "exportă ușor" \
    "Editează, reordonează" \
    "gestionează liber"

# Russian (ru-RU)
create_lang_svgs "ru-RU" \
    "Сканируйте документы" \
    "объединяйте в PDF" \
    "Автоопределение краёв" \
    "умная обрезка" \
    "Организуй и смотри" \
    "легко экспортируй" \
    "Редактируй, сортируй" \
    "управляй свободно"

# Sinhala (si-LK)
create_lang_svgs "si-LK" \
    "ලේඛන ස්කෑන් කරන්න" \
    "එක PDF එකකට ඒකාබද්ධ" \
    "ස්වයංක්‍රීය දාර හඳුනාගැනීම" \
    "ස්මාර්ට් කැපීම" \
    "සංවිධානය, පූර්ව දැක්ම" \
    "පහසුවෙන් අපනයනය" \
    "සංස්කරණය, නැවත සකසන්න" \
    "නිදහසේ කළමනාකරණය"

# Slovak (sk)
create_lang_svgs "sk" \
    "Skenujte dokumenty" \
    "spojte do PDF" \
    "Auto detekcia okrajov" \
    "inteligentný orez" \
    "Organizujte, prezerajte" \
    "jednoducho exportujte" \
    "Upravujte, meňte poradie" \
    "spravujte voľne"

# Slovenian (sl)
create_lang_svgs "sl" \
    "Skeniraj dokumente" \
    "združi v en PDF" \
    "Samodejno zaznavanje robov" \
    "pametno obrezovanje" \
    "Organiziraj, predogled" \
    "enostavno izvozi" \
    "Uredi, preuredi" \
    "upravljaj prosto"

# Albanian (sq)
create_lang_svgs "sq" \
    "Skanoni dokumente" \
    "kombinoni në një PDF" \
    "Zbulimi automatik i skajeve" \
    "prerje inteligjente" \
    "Organizoni, parapamje" \
    "eksportoni lehtë" \
    "Modifikoni, rirenditni" \
    "menaxhoni lirisht"

# Serbian (sr)
create_lang_svgs "sr" \
    "Скенирајте документе" \
    "спојите у један PDF" \
    "Ауто детекција ивица" \
    "паметно сечење" \
    "Организујте, прегледајте" \
    "лако извезите" \
    "Уредите, преуредите" \
    "управљајте слободно"

# Swedish (sv-SE)
create_lang_svgs "sv-SE" \
    "Skanna dokument" \
    "kombinera till en PDF" \
    "Auto kantdetektering" \
    "smart beskärning" \
    "Organisera, förhandsgranska" \
    "exportera enkelt" \
    "Redigera, ordna om" \
    "hantera fritt"

# Swahili (sw)
create_lang_svgs "sw" \
    "Changanua nyaraka" \
    "unganisha kuwa PDF moja" \
    "Utambuzi wa kingo auto" \
    "kukata kwa busara" \
    "Panga, hakiki mapema" \
    "hamisha kwa urahisi" \
    "Hariri, panga upya" \
    "simamia kwa uhuru"

# Tamil (ta-IN)
create_lang_svgs "ta-IN" \
    "ஆவணங்களை ஸ்கேன்" \
    "ஒரு PDF இல் இணைக்கவும்" \
    "தானியங்கி விளிம்பு கண்டறிதல்" \
    "ஸ்மார்ட் க்ராப்பிங்" \
    "ஒழுங்கமை, முன்னோட்டம்" \
    "எளிதாக ஏற்றுமதி" \
    "திருத்து, மறுவரிசைப்படுத்து" \
    "சுதந்திரமாக நிர்வகி"

# Telugu (te-IN)
create_lang_svgs "te-IN" \
    "డాక్యుమెంట్లను స్కాన్" \
    "ఒక PDF గా కలపండి" \
    "ఆటో ఎడ్జ్ డిటెక్షన్" \
    "స్మార్ట్ క్రాపింగ్" \
    "ఆర్గనైజ్, ప్రివ్యూ" \
    "సులభంగా ఎక్స్‌పోర్ట్" \
    "ఎడిట్, రీఆర్డర్" \
    "స్వేచ్ఛగా నిర్వహించండి"

# Thai (th)
create_lang_svgs "th" \
    "สแกนเอกสาร" \
    "รวมเป็น PDF เดียว" \
    "ตรวจจับขอบอัตโนมัติ" \
    "ครอบตัดอัจฉริยะ" \
    "จัดระเบียบ, ดูตัวอย่าง" \
    "ส่งออกได้ง่าย" \
    "แก้ไข, เรียงลำดับใหม่" \
    "จัดการได้อิสระ"

# Turkish (tr-TR)
create_lang_svgs "tr-TR" \
    "Belgeleri tarayın" \
    "tek PDF'te birleştirin" \
    "Otomatik kenar algılama" \
    "akıllı kırpma" \
    "Düzenleyin, önizleyin" \
    "kolayca dışa aktarın" \
    "Düzenle, yeniden sırala" \
    "özgürce yönet"

# Ukrainian (uk)
create_lang_svgs "uk" \
    "Скануйте документи" \
    "об'єднуйте в PDF" \
    "Автовизначення країв" \
    "розумне обрізання" \
    "Організуй, переглядай" \
    "легко експортуй" \
    "Редагуй, сортуй" \
    "керуй вільно"

# Urdu (ur)
create_lang_svgs "ur" \
    "دستاویزات اسکین کریں" \
    "ایک PDF میں جوڑیں" \
    "خودکار کنارے کا پتہ" \
    "سمارٹ کراپنگ" \
    "ترتیب دیں، پیش نظارہ" \
    "آسانی سے برآمد" \
    "ترمیم، دوبارہ ترتیب" \
    "آزادانہ انتظام"

# Uzbek (uz)
create_lang_svgs "uz" \
    "Hujjatlarni skanerlash" \
    "bitta PDF ga birlashtirish" \
    "Avtomatik chet aniqlash" \
    "aqlli qirqish" \
    "Tartibga solish, oldindan ko'rish" \
    "oson eksport qilish" \
    "Tahrirlash, qayta tartiblab" \
    "erkin boshqarish"

# Vietnamese (vi)
create_lang_svgs "vi" \
    "Quét tài liệu" \
    "kết hợp thành PDF" \
    "Tự động phát hiện cạnh" \
    "cắt thông minh" \
    "Sắp xếp, xem trước" \
    "xuất dễ dàng" \
    "Chỉnh sửa, sắp xếp lại" \
    "quản lý tự do"

# Chinese Simplified (zh-CN)
create_lang_svgs "zh-CN" \
    "扫描文档" \
    "合并为一个PDF" \
    "自动边缘检测" \
    "智能裁剪" \
    "整理、预览" \
    "轻松导出" \
    "编辑、排序" \
    "自由管理"

# Zulu (zu)
create_lang_svgs "zu" \
    "Skena amadokhumenti" \
    "hlanganisa ku-PDF eyodwa" \
    "Ukutholwa kwemingcele auto" \
    "ukusika okuhlakaniphile" \
    "Hlela, buka kuqala" \
    "thumela kalula" \
    "Hlela, buyisela" \
    "phatha ngokukhululeka"

echo "Done! Generated all 71 languages for Android."
