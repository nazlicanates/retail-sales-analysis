#Perakende Satış Analizi: Bulgular Raporu

## Özet
- 12.575 kayıtlık perakende satış verisi temizlenip SQL ile analiz edildi. Analizde güvenilir olarak işaretlenen 11.971 kayıt kullanıldı. En önemli bulgular:
- En yüksek ciro: Butchers, toplam cironun %13.41’ini oluşturuyor.
- Satış kanalı: Online satışlar In-store’a göre yüksek olsada neredeyse hiç fark yok.
- İndirim etkisi: İndirimli işlemlerin ortalama tutarı 130.49, indirimsiz işlemlerin 129.95 ve unknown olarak update ettiğim değerler ise 128.51 tutmuştur.
- Zaman: Satışlar 2022 yılının ocak ayında sadece zirve yapıyor; haftanın en güçlü günü ise Cuma.
## 1. Projenin Amacı
- Bu projede perakende satış verileri kullanılarak satış performansı, veri kalitesi ve satış davranışları SQL ile analiz edilmiştir. Temel amaçlar:
- Ham verideki veri kalitesi problemlerini tespit etmek
- Eksik ve tutarsız verileri mümkün olduğunca veri kaybetmeden düzeltmek
- Satış performansını kategori, lokasyon, ödeme yöntemi ve indirim durumuna göre incelemek
- Zaman içindeki satış eğilimlerini analiz etmek
## 2. Veri Seti
- Kaynak: Retail Store Sales: Dirty for Data Cleaning
- Kayıt sayısı: 12.575 satış
- Kullanılan araç: SQLite / DB Browser
- Alanlar: Transaction ID, Customer ID, Category, Item, Price Per Unit, Quantity, Total Spent, Payment Method, Location, Transaction Date, Discount Applied
## 3. Veri Temizleme
- Price Per Unit. Price Per Unit × Quantity = Total Spent ilişkisi, üç değerin de dolu olduğu kayıtlarda kontrol edildi ve uyuşmayan kayıt bulunmadı. Bu nedenle eksik fiyatlar Total Spent / Quantity ile hesaplandı; 609 eksik değer veri kaybı olmadan tamamlandı.
- Discount Applied. Eksik değerlerin "indirim yok" anlamına geldiğini gösteren bir bilgi olmadığı için bu kayıtlar False yapılmadı, Unknown olarak işaretlendi.

- Tamamlanamayan kayıtlar. Quantity ve Total Spent birlikte eksikse formülle güvenilir şekilde tamamlanamadığından bu kayıtlar silinmedi, situation_flag alanıyla işaretlendi:

| Durum | Kayıt sayısı | Kullanım |
|---|---|---|
| complete | 11.971 | Analizde kullanıldı |
| incomplete | 604 | Analiz dışında bırakıldı |

- Item. Eksik değerler veri kaybı olmasın diye Unknown Item olarak işaretlendi.
## 4. Bulgular
## 4.1 Hangi kategori en yüksek ciroyu yaratıyor?
- Butchers en yüksek ciroyu yarattı: 208118. Onu Electric household essentials ve Bevareges izliyor. Kategoriler arasında belirgin fark yok, en yüksek ile en düşük arası yaklaşık %15.
## 4.2 Online ve mağaza satışları arasındaki fark
- Online satışlar 791401 , mağaza satışları 760670. Online ve mağaza işlem sayısı ile ortalama sepet bakımından değerler yakındır.
## 4.3 En çok kullanılan ödeme yöntemi
- En çok kullanılan ödeme yöntemi olan Cash ödeme işlemlerin %34’ünde kullanıldı.
## 4.4 İndirimli ve indirimsiz işlemlerin ortalama tutarı
- İndirimli: 130,49/ 4019(işlem sayısı) indirimsiz: 129,95/3964, Unknown: 128,51/3988. Yani ortlama tutar değişmiyor ve indirim harcamayı artırmıyor. 
## 4.5 Her kategoride en yüksek ciroyu yaratan ürünler
- Beverages: Item_25_BEV
- Butchers: Item_25_BUT
- Computers and electric accessories: Item_19_CEA
- Electric household essentials: Item_25_EHE
- Food: Item_25_FOOD
- Furniture: Item_25_FUR
- Milk Products: Item_19_MILK
- Patisserie: Item_23_PAT
## 4.6 Satışlar aylar içinde nasıl değişiyor?
- 2022 Ocak’ta satışlar zirveyken en düşük 2023 yılının kasım ayı dip oldu. 
## 4.7 Toplam ciro zaman içinde nasıl birikiyor?
- Kümülatif ciro 2025-01 sonunda 1552071’e ulaştı. Matematiksel olarak bir büyüme gösteriyor gibi olsa da asıl büyüme aylık olara neredeyse hiç yok.
## 4.8 Kategorilerin toplam ciroya katkısı
- Butchers: %13.41
- Electric household essentials: %13.13
- Beverages: %12.70
## 4.9 Haftanın hangi günleri daha yüksek satış var?
- Cuma en yüksek, pazartesi en düşük ciroyu getirdi.
## 5. Kullanılan SQL Teknikleri
- CTE (`WITH`)
- Window Functions
- `RANK()`
- `LAG()`
- `PARTITION BY`
- Kümülatif toplam
- Yüzde hesaplamaları
- `CASE WHEN`
- `strftime()` ile tarih analizi
 
## NOT
 - Veri setinde yalnızca 25 benzersiz müşteri var ve her biri yüzlerce işlem yapmış. Gerçek bir perakende verisinde müşteri sayısının işlem sayısından çok daha fazla olması beklenir. Bu nedenle veri seti sentetik görünüyor ve "en değerli müşteriler" gibi analizler anlamlı sonuç vermeyeceği için kapsam dışı bırakılmıştır.
- Ocak 2025 eksik bir ay. Verideki son işlem tarihi 18 Ocak 2025. Bu yüzden Ocak 2025 cirosu düşük görünüyor ama bu bir satış düşüşü değil, ayın yarım olmasının sonucu. Aylık trend yorumlarında bu ay dışarıda tutuldu.
- Kâr analizi yapılamadı. Veri setinde maliyet veya kâr bilgisi yok, analizler ciro ve işlem hacmi üzerinden yapıldı.
- Eksik kayıtlar analiz dışında kaldı. Quantity ve Total Spent birlikte eksik olan 604 kayıt (verinin yaklaşık %4,8'i) formülle tamamlanamadığı için `situation_flag` ile işaretlenip analize dahil edilmedi.
- Para birimi belirtilmemiş. Veri setinde para birimi bilgisi olmadığı için tutarlar birimsiz verildi.
- Tek tablo. Veri tek bir düz tablodan oluştuğu için bu projede `JOIN` kullanılmamıştır.
