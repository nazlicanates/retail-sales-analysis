Analysis queries · SQL
/* ============================================================
   RETAIL SALES ANALYSIS - SQL Queries
   Veri seti: Retail Store Sales (Kaggle, "dirty" veri seti)
   Araç: SQLite (DB Browser for SQLite)
   ============================================================ */
 
 
/* ------------------------------------------------------------
   BÖLÜM 1: VERİ KEŞFİ (Data Exploration)
   ------------------------------------------------------------ */
 
-- İlk bakış
SELECT * FROM sales LIMIT 10;
 
-- Eksik değerlerin tek sorguda tespiti
SELECT 
    count(*) as toplam_satir,
    count(case when Item is null then 1 end) as bos_item,
    count(case when "Price Per Unit" is null then 1 end) as bos_price,
    count(case when Quantity is null then 1 end) as bos_quantity,
    count(case when "Total Spent" is null then 1 end) as bos_total_spent,
    count(case when "Discount Applied" is null then 1 end) as bos_discount
FROM sales;
 
-- Kategori dağılımında tutarsızlık var mı, kontrol:
SELECT Category, Count(*) as Adet
FROM sales
GROUP BY Category
ORDER BY Category;
 
-- Discount Applied değerlerinin dağılımı:
SELECT "Discount Applied", count(*) as adet
FROM sales
GROUP BY "Discount Applied";
 
-- Price Per Unit x Quantity = Total Spent ilişkisi doğrulama
-- Bu doğrulanırsa, boş Price Per Unit değerleri formülle hesaplanabilir
SELECT count(*) As formule_uymayan_satir
FROM sales
WHERE "Price Per Unit" is not null AND Quantity is not null AND "Total Spent" is not null
AND Round("Price per unit" * Quantity, 2) != round("Total Spent", 2);
-- Sonuç: 0 uyumsuz satır -> formül her zaman geçerli, 609 satır kurtarılabilir.
 
 
/* ------------------------------------------------------------
   BÖLÜM 2: VERİ TEMİZLEME (Data Cleaning)
   ------------------------------------------------------------ */
 
-- 1) Eksik Price Per Unit değerlerini formülle doldur
UPDATE sales
SET "Price Per Unit" = round("Total Spent" / Quantity, 2)
WHERE "Price Per Unit" is null
    AND Quantity is not NULL
    AND Quantity != 0;
 
SELECT count(*) as hala_bos_price
FROM sales
WHERE "Price Per Unit" is null;
-- Sonuç: 0 -> tüm kurtarılabilir satırlar dolduruldu.
 
-- 2) Eksik Discount Applied değerlerini 'Unknown' ile işaretle
--    (False ile karıştırılmadı çünkü gerçekten uygulanmadığı kanıtlanamıyor)
UPDATE sales
SET "Discount Applied" = 'Unknown'
WHERE "Discount Applied" IS NULL;
 
SELECT "Discount Applied", count(*) as adet
FROM sales
GROUP BY "Discount Applied";
 
-- 3) Veri kalitesi bayrağı ekle
--    Quantity ve Total Spent birlikte boş olan satırlar formülle kurtarılamıyor.
--    Bu satırlar veri kaybı olmaması açısından silinmedi, "incomplete" olarak işaretlenip analiz dışı bırakıldı.
ALTER TABLE sales
ADD COLUMN situation_flag TEXT;
 
UPDATE sales
SET situation_flag = 'complete';
 
UPDATE sales
SET situation_flag = 'incomplete'
WHERE Quantity is null AND "Total Spent" is null;
 
SELECT situation_flag, count(*)
FROM sales
GROUP BY situation_flag;
-- Sonuç: complete 11971 / incomplete 604
 
-- 4) Eksik Item değerlerini işaretle (Category'den türetilemediği için placeholder kullanıldı)
UPDATE sales
SET Item = 'Unknown Item'
WHERE Item is null;
 
SELECT count(*) as hala_bos_item
FROM sales
WHERE Item is null;
-- Sonuç: 0
 
 
/* ------------------------------------------------------------
   BÖLÜM 3: TEMEL İŞ SORULARI (Business Questions)
   Not: Tüm sorgularda situation_flag = 'complete' filtresi kullanılır,
   böylece eksik/kurtarılamaz veriler sonuçları etkilemez.
   ------------------------------------------------------------ */
 
-- 1) Hangi kategori en çok ciro yaratıyor?
SELECT Category, sum("Total Spent") as toplam_ciro
FROM sales
WHERE situation_flag = 'complete'
GROUP BY Category
ORDER BY toplam_ciro DESC;
 
-- 2) Online ve mağaza (in-store) satışları arasında fark var mı?
SELECT Location, count(*) as islem_sayisi, sum("Total Spent") as toplam_ciro
FROM sales
WHERE situation_flag = 'complete'
GROUP BY Location;
 
-- 3) Hangi ödeme yöntemi en çok kullanılıyor?
SELECT "Payment Method", count(*) as adet
FROM sales
WHERE situation_flag = 'complete'
GROUP BY "Payment Method";
 
-- 4) İndirim uygulanan satışlarla uygulanmayanlar arasında ortalama tutar farkı var mı?
SELECT "Discount Applied", avg("Total Spent") as ortalama_tutar, count(*) as islem_sayisi
FROM sales
WHERE situation_flag = 'complete'
GROUP BY "Discount Applied";
 
-- 10) Online ve mağaza satışlarında ortalama sepet tutarı farklı mı?
SELECT Location, avg("Total Spent") as ortalama_sepet, count(*) as islem_sayisi
FROM sales
WHERE situation_flag = 'complete'
GROUP BY Location;
 
 
/* ------------------------------------------------------------
   BÖLÜM 4: İLERİ SEVİYE SQL (Window Functions & CTE)
   ------------------------------------------------------------ */
 
-- 5) Her kategoride en çok ciro yaratan ilk 3 ürün (RANK + PARTITION BY)
WITH ciro_siralama AS (
    SELECT Category, Item, sum("Total Spent") as toplam_ciro,
           rank() over (PARTITION BY Category ORDER BY sum("Total Spent") DESC) as siralama
    FROM sales
    WHERE situation_flag = 'complete'
    GROUP BY Category, Item
)
SELECT Category, Item, toplam_ciro, siralama
FROM ciro_siralama
WHERE siralama IN (1, 2, 3);
 
-- 6) Satışlar ay ay büyüyor mu, küçülüyor mu? (LAG)
SELECT monthly, aylik_ciro,
       lag(aylik_ciro) over (ORDER BY monthly) as onceki_ay,
       round((aylik_ciro - lag(aylik_ciro) over (ORDER BY monthly)) 
             / lag(aylik_ciro) over (ORDER BY monthly) * 100.0, 1) as buyume_yuzdesi
FROM (
    SELECT strftime('%Y-%m', "Transaction Date") as monthly,
           sum("Total Spent") as aylik_ciro
    FROM sales
    WHERE situation_flag = 'complete'
    GROUP BY strftime('%Y-%m', "Transaction Date")
) as T
ORDER BY monthly;
 
-- 7) Zamanla toplam ciro nasıl birikiyor? (kümülatif toplam)
SELECT monthly, aylik_ciro,
       sum(aylik_ciro) over (ORDER BY monthly ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as kumulatif_ciro
FROM (
    SELECT strftime('%Y-%m', "Transaction Date") as monthly,
           sum("Total Spent") as aylik_ciro
    FROM sales
    WHERE situation_flag = 'complete'
    GROUP BY strftime('%Y-%m', "Transaction Date")
) as T
ORDER BY monthly;
 
-- 8) Toplam cironun yüzde kaçı hangi kategoriden geliyor? (CTE)
WITH cat_ciro AS (
    SELECT Category, sum("Total Spent") as kat_ciro
    FROM sales
    WHERE situation_flag = 'complete'
    GROUP BY Category
),
toplam_ciro AS (
    SELECT sum(kat_ciro) as toplam_ciro
    FROM cat_ciro
)
SELECT c.Category, c.kat_ciro,
       round(c.kat_ciro * 100.0 / t.toplam_ciro, 2) as yuzde_katki
FROM cat_ciro as c, toplam_ciro as t
ORDER BY yuzde_katki DESC;
 
-- 9) Haftanın hangi gününde daha fazla satış yapılıyor? (strftime + CASE WHEN)
SELECT 
    CASE strftime('%w', "Transaction Date")
        WHEN '0' THEN 'Pazar'
        WHEN '1' THEN 'Pazartesi'
        WHEN '2' THEN 'Salı'
        WHEN '3' THEN 'Çarşamba'
        WHEN '4' THEN 'Perşembe'
        WHEN '5' THEN 'Cuma'
        WHEN '6' THEN 'Cumartesi'
    END as gun_isim,
    count(*) as islem_sayisi, 
    sum("Total Spent") as toplam_ciro
FROM sales
WHERE situation_flag = 'complete'
GROUP BY gun_isim
ORDER BY toplam_ciro DESC;
