# retail-sales-analysis
SQLite and Power BI analysis of a retail sales dataset: data cleaning, window functions, CTEs, and dashboard.

## İş Problemi
Bu projede perakende satış verisiyle şu sorulara cevap aradım: Hangi kategoriler ve ürünler öne çıkıyor? Online ve mağaza satışları arasında fark var mı? İndirim harcamayı artırıyor mu? Satışlar zaman içinde nasıl değişiyor?

## Veri Seti
- Kaynak: Retail Store Sales: Dirty for Data Cleaning (Kaggle)
- 12.575 kayıtlık perakende satış verisi temizlenip SQL ile analiz edildi. Analizde güvenilir olarak işaretlenen 11.971 kayıt kullanıldı.
- Alanlar: Transaction ID, Customer ID, Category, Item, Price Per Unit, Quantity, Total Spent, Payment Method, Location, Transaction Date, Discount Applied

## Veri Temizleme
Ham veri "dirty" bir veri seti olduğu için önce eksik değerleri ve tutarsızlıkları tespit ettim, sonra her sorun için ayrı bir karar verdim:

- **Price Per Unit (609 eksik):** `Price Per Unit × Quantity = Total Spent` ilişkisinin dolu kayıtların hepsinde tuttuğunu doğruladım ve eksik fiyatları `Total Spent / Quantity` ile hesapladım. Hiçbir satır silinmedi.
- **Discount Applied (4.199 eksik):** Eksik olmasının "indirim yok" anlamına geldiğini gösteren bir bilgi olmadığı için `False` yapmadım, `Unknown` olarak işaretledim.
- **Item (1.213 eksik):** Kategoriden türetilemediği için `Unknown Item` olarak işaretledim.
- **Quantity ve Total Spent birlikte eksik (604 kayıt):** Formülle tamamlanamadığı için bu kayıtları silmedim ama veri eksiği de olmasın diye silmek yerine `situation_flag` sütunuyla `incomplete` olarak işaretleyip analiz dışında bıraktım. Analizler `complete` olan 11.971 kayıt üzerinden yapıldı.

## SQL Analizi
Tüm sorgular [sql/analysis_queries.sql](sql/analysis_queries.sql) dosyasında. Kullanılan teknikler:

- CTE (`WITH`)
- Window functions: `RANK()`, `LAG()`, `PARTITION BY`
- Kümülatif toplam
- Yüzde hesaplamaları
- `CASE WHEN`
- `strftime()` ile tarih analizi

## Temel Bulgular
- Kategoriler arasında belirgin fark yok. En yüksek ciro Butchers'ta (toplamın %13,41'i), en düşük kategoriyle arasındaki fark yaklaşık %15.
- Online ve mağaza satışları işlem sayısı ve ortalama sepet bakımından neredeyse eşit.
- İndirim harcamayı artırmıyor: indirimli işlemlerde ortalama tutar 130,49, indirimsizlerde 129,95.
- Aylık ciroda belirgin bir mevsimsellik yok. En yüksek ay 2022 Ocak, en düşük ay 2023 Kasım.
- Haftanın en güçlü günü Cuma, en zayıfı Pazartesi.

Tüm sonuçlar için: [Bulgular Raporu](report/findings.md)

## Sınırlamalar
- Veri setinde yalnızca 25 benzersiz müşteri var ve her biri yüzlerce işlem yapmış, bu yüzden veri sentetik görünüyor. Müşteri bazlı analizler anlamlı sonuç vermeyeceği için kapsam dışı bırakıldı.
- Verideki son işlem tarihi 18 Ocak 2025, yani Ocak 2025 yarım bir ay. Aylık trend yorumlarında bu ay dışarıda tutuldu.
- Veri setinde maliyet veya kâr bilgisi yok, analizler ciro ve işlem sayısı üzerinden yapıldı.

## Power BI Dashboard
Devam ediyor, henüz bitmedi.
