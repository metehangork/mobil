# Test / Kontrol Listesi - Sonuçlar

**Test Tarihi:** 3 Ekim 2025  
**Cihaz:** Mi Note 10 (89f3bc2e) - Android 11 (API 30)  
**Flutter Version:** Debug mode  
**Test Başlangıç:** ___:___

## 📱 1. Gezinti (Navigation)

### 1.1 Tab Stack Preservation
**Test:** Her sekmede ileri/geri gezin, sonra sekme değiştir → geri dönünce stack korunuyor mu?

- [ ] **AnaSayfa sekmesi**
  - [ ] AnaSayfa açık → başka sekmeye git → geri dön → AnaSayfa aynı konumda mı?
  
- [ ] **Dersler sekmesi**
  - [ ] Dersler açık → başka sekmeye git → geri dön → Dersler aynı konumda mı?
  
- [ ] **Gruplar sekmesi**
  - [ ] Gruplar açık → başka sekmeye git → geri dön → Gruplar aynı konumda mı?
  
- [ ] **Mesajlar sekmesi**
  - [ ] Mesajlar açık → başka sekmeye git → geri dön → Mesajlar aynı konumda mı?
  
- [ ] **Profil sekmesi**
  - [ ] Profil açık → başka sekmeye git → geri dön → Profil aynı konumda mı?

**Sonuç:** ⏳ Test edilecek  
**Notlar:** 

---

### 1.2 Performance - Hızlı Sekme Geçişi
**Test:** AnaSayfa → Dersler → Gruplar → Mesajlar → Profil hızlı geçişte performans takılmıyor mu?

- [ ] AnaSayfa → Dersler (geçiş süresi: ___ ms, sorunsuz mu?)
- [ ] Dersler → Gruplar (geçiş süresi: ___ ms, sorunsuz mu?)
- [ ] Gruplar → Mesajlar (geçiş süresi: ___ ms, sorunsuz mu?)
- [ ] Mesajlar → Profil (geçiş süresi: ___ ms, sorunsuz mu?)
- [ ] Profil → AnaSayfa (geçiş süresi: ___ ms, sorunsuz mu?)

**Sonuç:** ⏳ Test edilecek  
**Performans Notları:**

---

## 🔙 2. Geri Davranışı (Android Back Button)

### 2.1 Tab İçi Push Sonrası Geri
**Test:** Tab içi push sonrası geri: doğru ekran?

- [ ] **Scenario A:** AnaSayfa → (future: detail page) → Back → AnaSayfa'ya döndü mü?
- [ ] **Scenario B:** Dersler → (future: course detail) → Back → Dersler'e döndü mü?
- [ ] **Scenario C:** Gruplar → (future: group detail) → Back → Gruplar'a döndü mü?

**Sonuç:** ⏳ Test edilecek (nested routes henüz yok)  
**Notlar:**

---

### 2.2 Kök Ekranda Tek Basış
**Test:** Kök ekranda tek basış: "Çıkmak için tekrar basın" toast

- [ ] **AnaSayfa tab'da back tuşu** → Toast görünüyor mu?
- [ ] **Dersler tab'da back tuşu** → Toast görünüyor mu?
- [ ] **Gruplar tab'da back tuşu** → Toast görünüyor mu?
- [ ] **Mesajlar tab'da back tuşu** → Toast görünüyor mu?
- [ ] **Profil tab'da back tuşu** → Toast görünüyor mu?
- [ ] Toast mesajı: "Çıkmak için tekrar basın"

**Sonuç:** ⏳ Test edilecek  
**Toast Mesajı Doğru mu?:**

---

### 2.3 İki Saniye İçinde Tekrar Basış
**Test:** 2 sn içinde tekrar: uygulama kapanır

- [ ] Kök ekranda back → 1 saniye bekle → back → Uygulama kapandı mı?
- [ ] Kök ekranda back → 3 saniye bekle → back → Toast tekrar göründü mü? (kapanmadı mı?)

**Sonuç:** ⏳ Test edilecek  
**Zamanlama Doğru mu?:**

---

## 📱 3. Üst Bar (AppBar)

### 3.1 Buton Setleri Doğru mu?
**Test:** Her sekmede butonlar doğru set mi?

- [ ] **AnaSayfa:** Search button var mı?
- [ ] **Dersler:** Search, Filter, Add buttons var mı?
- [ ] **Gruplar:** Search, Filter, Add buttons var mı?
- [ ] **Mesajlar:** Search, Filter (menu) buttons var mı?
- [ ] **Profil:** Edit, Share buttons var mı?

**Sonuç:** ⏳ Test edilecek  
**Eksik/Yanlış Butonlar:**

---

### 3.2 Aksiyon Log'ları
**Test:** Aksiyonlara basınca en azından log (print) düşüyor mu?

#### AnaSayfa
- [ ] Search button → Console'da "Search action pressed" log'u görünüyor mu?

#### Dersler
- [ ] Search button → Console'da "Search courses pressed" log'u görünüyor mu?
- [ ] Filter button → Console'da "Filter courses pressed" log'u görünüyor mu?
- [ ] Add button → Console'da "Add course pressed" log'u görünüyor mu?

#### Gruplar
- [ ] Search button → Console'da "Search groups pressed" log'u görünüyor mu?
- [ ] Filter button → Console'da "Filter groups pressed" log'u görünüyor mu?
- [ ] Add button → Console'da "Create group pressed" log'u görünüyor mu?

#### Mesajlar
- [ ] Search button → Console'da "Search messages pressed" log'u görünüyor mu?
- [ ] Filter All → Console'da "Filter: All messages" log'u görünüyor mu?
- [ ] Filter Unread → Console'da "Filter: Unread messages" log'u görünüyor mu?
- [ ] Filter Attachments → Console'da "Filter: Messages with attachments" log'u görünüyor mu?

#### Profil
- [ ] Edit button → Console'da "Edit profile pressed" log'u görünüyor mu?
- [ ] Share button → Console'da "Share profile pressed" log'u görünüyor mu?

**Sonuç:** ⏳ Test edilecek  
**Çalışmayan Aksiyonlar:**

---

## 🔄 4. Pull-to-Refresh

### 4.1 Her Kök Ekranda Pull-to-Refresh
**Test:** Her kökte aşağı çekme → indicator → tamamlanıyor mu?

- [ ] **AnaSayfa:** Aşağı çek → RefreshIndicator görünüyor mu? → 2 saniye sonra tamamlanıyor mu?
- [ ] **Dersler:** Aşağı çek → RefreshIndicator görünüyor mu? → 2 saniye sonra tamamlanıyor mu?
- [ ] **Gruplar:** Aşağı çek → RefreshIndicator görünüyor mu? → 2 saniye sonra tamamlanıyor mu?
- [ ] **Mesajlar:** Aşağı çek → RefreshIndicator görünüyor mu? → 2 saniye sonra tamamlanıyor mu?
- [ ] **Profil:** Aşağı çek → RefreshIndicator görünüyor mu? → 2 saniye sonra tamamlanıyor mu?

**Sonuç:** ⏳ Test edilecek  
**Notlar:**

---

## 📭 5. Boş Durum (Empty State)

### 5.1 İlk Yükleme Boş Durumlar
**Test:** İlk yüklemede boş durum metni/CTA görünüyor mu?

#### AnaSayfa
- [ ] "UniCampus'a Hoş Geldiniz!" kartı görünüyor mu?
- [ ] Quick Actions (Ders Ekle, Grup Oluştur, Profili Tamamla, Bildirimler) görünüyor mu?
- [ ] "Henüz aktivite yok" mesajı görünüyor mu?

#### Dersler
- [ ] Boş durum ikonu (📚) görünüyor mu?
- [ ] "Henüz ders eklenmemiş" metni görünüyor mu?
- [ ] "Ders eklemek için butona tıklayın" metni görünüyor mu?
- [ ] "Ders Ekle" butonu görünüyor mu?

#### Gruplar
- [ ] Boş durum ikonu (👥) görünüyor mu?
- [ ] "Henüz grup yok" metni görünüyor mu?
- [ ] "Grup oluştur veya mevcut gruplara katıl" metni görünüyor mu?
- [ ] "Grup Oluştur" butonu görünüyor mu?
- [ ] "Grupları Keşfet" butonu görünüyor mu?

#### Mesajlar
- [ ] Boş durum ikonu (💬) görünüyor mu?
- [ ] "Mesaj kutusu boş" metni görünüyor mu?
- [ ] "Arkadaşlarınla sohbet etmeye başla" metni görünüyor mu?

#### Profil
- [ ] Profil header (avatar, isim, email, bio) görünüyor mu?
- [ ] İstatistikler (Derslerim, Gruplarım, Arkadaşlar) görünüyor mu?
- [ ] Menu items (Ayarlar, Bildirimler, Gizlilik, Yardım, Çıkış Yap) görünüyor mu?

**Sonuç:** ⏳ Test edilecek  
**Eksik/Yanlış Görünen Elemanlar:**

---

## 📊 Özet

**Test Başlangıç:** ___:___  
**Test Bitiş:** ___:___  
**Toplam Süre:** ___ dakika

**Başarılı:** __ / __  
**Başarısız:** __ / __  
**Test Edilmedi:** __ / __

**Kritik Sorunlar:**
- [ ] Yok

**Küçük Sorunlar:**
- [ ] Yok

**İyileştirme Önerileri:**
- 

---

## 📝 Test Notları

### Genel Gözlemler


### Performans Notları


### UI/UX Gözlemleri


### Öneriler

