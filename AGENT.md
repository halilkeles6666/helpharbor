# AGENT.md

Bu dosya, HelpHarbor üzerinde çalışan bir yapay zekâ kodlama ajanı (ör. Claude Code) ve insan geliştirici için ortak çalışma rehberidir. Projenin kurucusuyla (öğrenci) ve bir AI ajanla **birlikte** yazılmıştır; projenin mimarisini, değişmezlerini ve nasıl güvenle değiştirileceğini anlatır.

## Proje özeti

HelpHarbor, Zendesk'ten ilham alan bir destek-talebi (ticket) uygulamasının **aort dilimidir**: talep → atama → yanıt → iş-günü SLA'i altında çözüm. Ürünün tamamı değil, müşterinin para ödemesinin asıl nedeni olan çekirdek akış hedeflenir.

- **Dil/çatı:** Ruby 3.4, Rails 8 (importmap, Hotwire, Propshaft).
- **Veritabanı:** SQLite (development/test/CI), PostgreSQL (production/Render).
- **Test:** Minitest + fixtures; zaman kuralları `travel_to` ile test edilir.

## Komutlar

```bash
bundle install
bin/rails db:prepare db:seed      # şema + örnek veri
bin/rails server                  # http://localhost:3000
bin/rails test                    # tüm testler
bin/rails test test/models/business_hours_test.rb   # tek dosya
bin/rubocop                       # stil (omakase)
bin/brakeman --no-pager           # güvenlik taraması
```

## Mimari ve dosya haritası

| Katman | Dosya | Sorumluluk |
|---|---|---|
| Zaman motoru | `app/services/business_hours.rb` | İş-günü/mesai aritmetiği (`advance`, `minutes_between`). **Çalışma haftası tek gerçek kaynağı.** |
| Alan modeli | `app/models/ticket.rb` | Durum makinesi (`TRANSITIONS`, `transition_to!`), SLA planlama, ihlal/duraklatma |
| | `app/models/sla_policy.rb` | Öncelik → SLA hedefleri (çalışma dakikası) |
| | `app/models/comment.rb` | Yanıt/iç not; ilk yanıt SLA sayacını durdurur |
| | `app/models/user.rb` | Ajan/admin; Rails 8 `has_secure_password` |
| Public giriş | `app/controllers/support_requests_controller.rb` | Müşteri talep formu (girişsiz) |
| Ajan paneli | `app/controllers/tickets_controller.rb`, `comments_controller.rb` | Kuyruk, detay, geçiş, atama, yanıt |
| Kimlik doğrulama | `app/controllers/concerns/authentication.rb` | Rails 8 üretimi session tabanlı auth |

## Değişmezler (bunları bozma)

1. **SLA süreleri "çalışma dakikası"dır; takvim dakikası değil.** Hafta sonu ve mesai dışı sayaç ilerletmez. Bu, ürünün ayırt edici özelliği (klonladığımız üründeki kullanıcı acısının çözümü). Yeni bir süre hesabı eklerken `BusinessHours.advance/minutes_between` kullan; ham `+ n.hours` KULLANMA.
2. **Durum değişiklikleri yalnızca `Ticket#transition_to!` üzerinden** yapılır; `TRANSITIONS` tablosuna uymayan geçişler reddedilir. `status`'u doğrudan `update` ile değiştirme.
3. **`pending` çözüm sayacını duraklatır.** `pending`'den çıkışta geçen çalışma süresi `resolution_due_at`'e eklenir (`apply_status_side_effects`).
4. **Zaman dilimi tek ve açık:** `config.time_zone = "Istanbul"`. Testlerde `Time.zone.local(...)` ve `travel_to` kullan.

## Test yaklaşımı

- **Zaman kuralı** ve **durum geçişleri** `travel_to` ile deterministik test edilir (bkz. `test/models/ticket_test.rb`, `business_hours_test.rb`).
- Referans hafta: 2026-10-12 Pazartesi … 2026-10-16 Cuma (hafta sonu 17–18).
- Uçtan uca akış: `test/integration/aorta_slice_test.rb`.
- **Kural:** yeni bir zaman/durum davranışı eklediğinde önce başarısız bir test yaz, sonra geçir. Ajanın "yaptım" demesine değil, yeşil testlere güven.

## Nasıl genişletilir (örnekler)

- **Çalışma gününü değiştir** (ör. Cumartesi de çalış): `BusinessHours::WORKDAYS`'e `6` ekle.
- **Mesai saatini değiştir:** `OPEN_HOUR` / `CLOSE_HOUR`.
- **Yeni öncelik/SLA:** `db/seeds.rb` içine yeni `SlaPolicy`; `Ticket::PRIORITIES`'e ekle.
- **Yeni durum:** `Ticket::TRANSITIONS` tablosuna düğüm + kenar ekle; geçiş yan etkisi gerekiyorsa `apply_status_side_effects`.

## Dağıtım

Render üzerinde; `render.yaml` + `bin/render-build.sh`. Ayrıntı: `DEPLOY.md`. Production'da `pg` kullanılır (`DATABASE_URL`), `RAILS_MASTER_KEY` elle ayarlanır.

## AI ajanla çalışma notu

Bu repo, bir AI kodlama ajanıyla birlikte üretildi. İzlenen ilke: **ajanın ürettiği her şey çalıştırılarak doğrulandı** — testler gerçekten koşturuldu (uydurma rapor yok), sunucu ayağa kaldırılıp sayfalar gerçek HTTP ile denendi. Ajana bir özellik yaptırırken, bitişte mutlaka `bin/rails test` yeşil olmalı ve ilgili akış elle/HTTP ile bir kez görülmelidir.
