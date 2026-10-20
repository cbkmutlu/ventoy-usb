# Ventoy USB

**Windows kurulum, debloat ve uygulama yükleme** işlemlerini otomatikleştiren bir Ventoy USB araç setidir.

> Ventoy ile bootable USB üzerinden Windows kurulumu başlatılır, ardından debloat ve application scriptleri ile bilgisayar kullanıma hazır hale getirilir.

## Yapılandırma (ventoy.json)

```json
{
    "theme": {
        "display_mode": "CLI"
    },
    "auto_install": [
        {
            "image": "/Windows_10_EN_22H2_x64.iso",
            "template": ["/ventoy/default_en.xml"]
        },
        {
            "image": "/Windows_10_TR_22H2_x64.iso",
            "template": ["/ventoy/default_tr.xml"]
        },
        {
            "image": "/Windows_11_EN_25H2_x64.iso",
            "template": ["/ventoy/default_en.xml"]
        },
        {
            "image": "/Windows_11_TR_25H2_x64.iso",
            "template": ["/ventoy/default_tr.xml"]
        }
    ]
}
```

## USB Hazırlama

- Ventoy2Disk çalıştır ve doğru Flash Belleği seç
- Çıkan uyarıları onayla (Disk temizlenecek)
- İşlem bittikten sonra tüm dosya ve klasörleri flash bellek içine yapıştır.
- Flash bellek içine ISO dosyalarını yapıştır.
- USB içerisine ilave programlar eklenebilir.

---

Eğer ortamda eski (BIOS) bilgisayarlar varsa MBR tercih edilmelidir.
Eğer sadece yeni (UEFI) sistemler varsa GPT tercih edilmelidir.
Maksimum uyumluluk için MBR tercih edilmelidir.

---

BIOS kontrol (boot çalışmazsa)

- Secure Boot kapat (gerekirse)
- Boot Mode: Legacy / UEFI ikisi de açık olsun (varsa)

---

- Windows Auto Install (Unattended) ventoy.json dosyasında (auto_install) image (ISO) ve template (XML) dosyaları eşleştirilir.
