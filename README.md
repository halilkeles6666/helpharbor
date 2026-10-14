# HelpHarbor

> Bir destek talebi (ticket) yaşam döngüsünün **aort dilimi**: talep gelir → atanır → yanıtlanır → iş-günü/mesai farkındalıklı bir **SLA** altında çözülür.
> İlham kaynağı: **Zendesk** (markanın adı/logosu bu uygulamada kullanılmaz; yalnızca burada, README'de referans olarak geçer).

<!-- CI rozeti: <KULLANICI_ADI>/<REPO_ADI> kısmını kendi GitHub repo yolunuzla değiştirin -->
![CI](https://github.com/KULLANICI_ADI/helpharbor/actions/workflows/ci.yml/badge.svg)

- **Canlı uygulama:** _(deploy sonrası Render URL'si buraya — bkz. [DEPLOY.md](DEPLOY.md))_
- **Demo giriş:** `agent@helpharbor.test` / `password`
- **Teknoloji:** Ruby 3.4 · Rails 8 · SQLite (dev/test) · PostgreSQL (production) · Minitest

---

## İçindekiler
1. [Faz 1 — Fortune 500 araştırması](#faz-1--fortune-500-araştırması-kaynaklı)
2. [SaaS seçimi ve Fortune 500 kanıtı](#saas-seçimi-ve-fortune-500-kanıtı)
3. [Faz 2 — Maliyet tahmini](#faz-2--maliyet-tahmini)
4. [Aort dilimi](#aort-dilimi-uçtan-uca-çalışan-ana-iş-akışı)
5. [100 puan: çözülen kullanıcı acısı](#100-puan--çözülen-kullanıcı-acısı)
6. [Zaman kuralı ve durum geçişi — kod nerede](#zaman-kuralı-ve-durum-geçişi--kod-nerede)
7. [Kurulum, test ve çalıştırma](#kurulum-test-ve-çalıştırma)
8. [Yapamadıklarım](#yapamadıklarım)

---

## Faz 1 — Fortune 500 araştırması (kaynaklı)

> Not: Fortune 500 listesi **piyasa değerine değil, yıllık gelire** göre sıralanır. Aşağıda hem gelir hem (toplam) piyasa değeri verilmiştir. Her rakamın yanında kaynağı vardır.

| Soru | Değer (yaklaşık / aralık) | Kaynak |
|---|---|---|
| **a. Değerleme / büyüklük aralığı** | Gelire göre: en büyük **Walmart ≈ 681 milyar $**, listeye giriş eşiği (#500) **≈ 7,4 milyar $**. Medyan gelir ≈ 16,6 milyar $. Grubun **toplam piyasa değeri ≈ 46 trilyon $**. | [Fortune 2025 duyurusu][f1], [AOL — en büyük 10][f2], [eqvista — medyan][f3] |
| **b. Çalışan sayısı aralığı** | 500 firma **toplam ≈ 31 milyon** çalışan istihdam ediyor; tek tek firmalar ~7 binden (eşik civarı küçük firmalar) en büyük işveren **Walmart ≈ 2,1 milyon**'a kadar değişiyor. | [Fortune 2025 duyurusu][f1] |
| **c. Bir firmanın kullandığı SaaS ürünü sayısı** | Büyük kurumlar (10.000+ çalışan) ortalama **~473 SaaS uygulaması**; Okta'nın ölçümünde 2.000+ çalışanlı firmalar **~231**, genel ortalama **~101** (metodolojiye göre değişir). | [CloudNuro / Zylo derlemesi][s1], [Torii][s2] |
| **d. SaaS aboneliklerine yıllık ödenen para** | Ortalama kurum **yılda ≈ 52 milyon $** (2024'te ≈ 45 milyon $); yazılım bütçesinin ~%70'i. (İkincil kaynak; birincil anket Statista'da ücretli.) | [CloudNuro derlemesi][s1], [Statista anketi][s3] |

> Rakamların çoğu satıcı/ikincil derlemelerdir ve metodolojiye göre değişir; birincil raporlar (Zylo SaaS Management Index, Okta *Businesses at Work*, Statista) daha kesin veri için işaret edilmiştir.

[f1]: https://fortunemedia.mediaroom.com/2025-06-02-Fortune-Announces-2025-Fortune-500-List
[f2]: https://www.aol.com/10-largest-us-companies-revenue-140205973.html
[f3]: https://eqvista.com/fortune-500-companies-in-the-us/
[s1]: https://www.cloudnuro.ai/blog/saas-statistics
[s2]: https://www.toriihq.com/articles/saas-statistics
[s3]: https://www.statista.com/statistics/1472733/organizations-saas-annual-spend-globally

---

## SaaS seçimi ve Fortune 500 kanıtı

**Seçilen ürün: Zendesk** (müşteri destek / ticketing platformu).

Ödevin kriterlerini neden karşılıyor:

- **En az bir Fortune 500 firmasının para ödediği kanıtı:** **Uber Technologies**, 2010'dan beri Zendesk kullanıyor ve Zendesk'in kendi vaka çalışması sayfasında yer alıyor → [zendesk.com/customer/uber][z-uber]. Uber'in FY2024 geliri **≈ 44 milyar $** ([SEC 10-K][uber-10k]), Fortune 500 giriş eşiği olan 7,4 milyar $'ın çok üzerinde; dolayısıyla Uber kesinlikle Fortune 500'dedir ([Fortune şirket sayfası][uber-fortune]).
- **Çok sayıda Fortune 500 kullanımı:** Zendesk gelirinin %35'inden fazlası kurumsal müşterilerden gelir; müşterileri arasında LATAM Airlines, Lending Club gibi büyük kurumlar da bulunur ([Zendesk SEC 8-K][z-8k]).
- **Ölçek (~300k+ satır, gerçek kurumsal ürün):** Zendesk 15+ yıllık, halka açık olmuş (sonra Permira tarafından ~10,2 milyar $'a özelleştirilen), yıllık ~1,7 milyar $ gelirli, çok ürünlü bir platformdur — oyuncak değil, devasa bir kod tabanı (bkz. Faz 2 tahmini).
- **Bol gerçek kullanıcı yorumu:** G2'de **4.3/5 (~6.800 yorum)**, Capterra'da **4.4/5 (~4.000 yorum)** ([derleme][z-reviews]) — acı madenciliği için zengin kaynak.

[z-uber]: https://www.zendesk.com/customer/uber/
[uber-10k]: https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=0001543151&type=10-K
[uber-fortune]: https://fortune.com/company/uber-technologies/
[z-8k]: https://www.sec.gov/Archives/edgar/data/0001463172/000156459016017453/zen-ex992_10.htm
[z-reviews]: https://clearfeed.ai/blogs/zendesk-review-pros-cons

---

## Faz 2 — Maliyet tahmini

### Zendesk'in yaklaşık satır sayısı ve tahmin yöntemi

Zendesk kapalı kaynaktır; satır sayısı **dolaylı olarak** tahmin edildi:

- **Yöntem:** (1) ürün yaşı (2007'den beri, 18+ yıl), (2) mühendis sayısı (halka açıkken binlerce çalışan, yüzlerce mühendis), (3) özellik yüzeyi (çok kanallı destek, SLA, otomasyon/trigger'lar, raporlama, API, uygulama pazarı, AI), (4) kıyas: açık kaynak yardım masaları (ör. Zammad, osTicket) tek başına 100k–300k satır bandındadır ve Zendesk bunların kat kat üstündedir.
- **Tahmin:** Yalnızca **Support (ticketing) çekirdeği birkaç yüz bin satır**; tüm Suite (Chat, Talk, Guide, Explore, Sunshine) toplamı rahatlıkla **1 milyon satırın üzerinde**. Ödevin "~300.000 satırlık gerçek kurumsal ürün" ölçeğini fazlasıyla karşılar.

### Çekirdeği bugünün coding agent'ları ile üretmek

|  | Tahmin | Gerçekleşen |
|---|---|---|
| **Kapsam** | Yalnızca aort dilimi (talep + SLA + durum akışı), tüm ürün değil | Aynı — aort dilimi uçtan uca |
| **Süre** | Tek geliştirici + AI ajan ile **2–4 gün** | **~1 yoğun oturum** (bu repo, tek ajan ile) |
| **Para (token/abonelik)** | Coding agent aboneliği (~20–100 $/ay) içinde; saf token maliyeti kabaca **birkaç ila ~30 $** | Mevcut Claude Code aboneliği kapsamında; ek saf token maliyeti düşük (tek haneli–~onlarca $ mertebesinde tahmini) |

> Dürüst not: Tam ürünü (tüm Suite) klonlamak bu bütçenin çok ötesindedir; ucuzlayan şey **çekirdek iş akışının** bir kopyasını çıkarmaktır — ödevin tezi de budur.

---

## Aort dilimi (uçtan uca çalışan ana iş akışı)

Müşterinin bu ürüne para ödemesinin asıl nedeni: **bir sorun bildirildiğinde, söz verilen sürede (SLA) çözülmesi.** Klonlanan dilim:

1. **Müşteri talep açar** (girişsiz, public form): `/support`
2. Talep **SLA politikasıyla** oluşturulur (önceliğe göre ilk-yanıt ve çözüm hedefleri iş-günü bazında hesaplanır).
3. **Ajan giriş yapar**, kuyruğu SLA'e göre görür, talebi kendine **atar**.
4. **Yanıt** yazar → ilk-yanıt SLA sayacı durur.
5. Talep **durum makinesinde** ilerler: `new → open → pending → solved → closed` (geçersiz geçişler reddedilir).
6. `pending` (müşteri bekleniyor) iken **çözüm sayacı duraklar**.

**İki zorunlu öğe:**
- **Zaman kuralı:** SLA süreleri (ilk yanıt + çözüm), iş-günü/mesai farkındalıklı (`app/services/business_hours.rb`).
- **Durum akışı:** `app/models/ticket.rb` içindeki `TRANSITIONS` durum makinesi.

---

## 100 puan — çözülen kullanıcı acısı

**Kimin acısı, hangi yorumdan, çözümümüz ne — tek cümleyle:**
> Zendesk kullanıcıları, SLA sayacının **hafta sonu ve mesai dışını da saymasından** (rozetin takvim saatiyle ilerleyip Pzt–Cum takvimini yok saymasından) şikâyet ediyor; HelpHarbor'da SLA **yalnızca çalışma günü/saatinde ilerler, hafta sonu/mesai dışını saymaz ve talep "beklemede" iken durur.**

Kaynaklar (gerçek kullanıcı geri bildirimi):
- Zendesk Community fikir gönderisi — *"SLA Badge Display Ignores Business Hours Configuration"* (kullanıcılar Pzt–Cum takvimine rağmen rozetin takvim saatiyle saydığını, taleplerin hafta sonu ihlal ediyormuş gibi göründüğünü bildiriyor): [community.zendesk.com][p1]
- *"Five Mistakes Behind Weekend SLA Breaches in Zendesk"*: [l5.ai][p2]
- G2/Capterra derlemesinde "business hours" kısıtı şikâyetleri: [clearfeed.ai][z-reviews]

**Çözümümüz nasıl çalışıyor:** `BusinessHours` motoru her SLA süresini *çalışma dakikası* olarak işler. Cuma 16:30'da gelen 2 saatlik bir ilk-yanıt hedefi, hafta sonunu atlayarak **Pazartesi 10:30**'a denk gelir (bkz. testler). Rozet de kalan süreyi takvim saatiyle değil iş-günü bazında gösterir.

[p1]: https://community.zendesk.com/ideas/sla-badge-display-ignores-business-hours-configuration-1895
[p2]: https://l5.ai/resources/zendesk-business-hours-sla-breaches

---

## Zaman kuralı ve durum geçişi — kod nerede

| Konu | Dosya | Açıklama |
|---|---|---|
| **Zaman kuralı (SLA, iş-günü)** | [`app/services/business_hours.rb`](app/services/business_hours.rb) | `WORKDAYS`, `OPEN_HOUR`, `CLOSE_HOUR` sabitleri; `advance` ve `minutes_between`. **Çalışma haftası kuralını değiştirmek için tek nokta.** |
| SLA'in talebe uygulanması | [`app/models/ticket.rb`](app/models/ticket.rb) | `schedule_sla`, `resolution_breached?`, pending duraklatma |
| **Durum geçişi** | [`app/models/ticket.rb`](app/models/ticket.rb) | `TRANSITIONS` tablosu + `transition_to!` |
| Testler (travel_to) | [`test/models/business_hours_test.rb`](test/models/business_hours_test.rb), [`test/models/ticket_test.rb`](test/models/ticket_test.rb) | Hafta sonu atlama, pending duraklatma, geçiş kuralları |

> **Sunum 5. soru örneği** ("SLA hafta sonunu saymasın"): zaten böyle çalışıyor. "Cumartesi de çalışılsın" denirse `app/services/business_hours.rb` → `WORKDAYS` sabitine `6` eklenir (tek satır).

---

## Kurulum, test ve çalıştırma

```bash
bundle install
bin/rails db:prepare db:seed
bin/rails server            # http://localhost:3000
bin/rails test              # tüm testler (model + servis + entegrasyon)
```

- Dev/test: SQLite (kurulum gerektirmez). Production: PostgreSQL (`DATABASE_URL`).
- CI: GitHub Actions (`.github/workflows/ci.yml`) — brakeman, importmap audit, rubocop ve `bin/rails test`.
- Deploy: [DEPLOY.md](DEPLOY.md) (Render).

---

## Yapamadıklarım

Dürüstlük bölümü — bunlar **bilerek kapsam dışı** bırakıldı (gizli eksik değil):

- **E-posta ile talep alma/gönderme yok.** Talepler yalnızca web formundan açılır; gerçek mail ingest ve giden bildirim e-postası yok (mailer altyapısı var ama SMTP bağlı değil).
- **Çok kanallılık yok** (chat, telefon, sosyal medya). Sadece web ticket.
- **Çalışma takvimi tek ve sabit** (Pzt–Cum 09:00–17:00, İstanbul) — kod sabiti; takıma/müşteriye göre ayrı takvim veya resmi tatil takvimi yok. Değiştirmek kolay ama UI'dan yönetilemiyor.
- **Müşteri self-servis portalı / talep durumu takip ekranı yok** (referans no veriliyor ama müşteri girişiyle takip yok).
- **Raporlama/analitik, dosya eki, etiketler, makrolar, otomasyon trigger'ları, SLA ihlal bildirimi (arka plan job) yok.**
- **Yetkilendirme sade:** tüm giriş yapan kullanıcılar ajan; rol bazlı yetki (admin-only ekranlar) uygulanmadı.
- **Sayfalama yok** (talep listesi büyürse tek sayfada gelir).
- **Demo seed parolaları zayıf** (`password`) — yalnızca demo/sunum içindir, gerçek kullanım için değildir.
- **Sistem (tarayıcı) testleri yok**; kapsam model + servis + HTTP entegrasyon testleriyle doğrulandı.
