#!/bin/bash
# MacOS üzerinde Admin Panelini yerel sunucuda başlatır

echo "======================================"
echo "🚑 Triyaj Admin Paneli Başlatılıyor..."
echo "======================================"
echo "Lütfen tarayıcınız açıldığında Google ile Giriş yapın."
echo ""
echo "Paneli kapatmak için bu pencereyi kapatabilir veya CTRL+C yapabilirsiniz."

# Python yerleşik HTTP sunucusunu çalıştır ve tarayıcıyı aç
cd "$(dirname "$0")" || exit 1
open "http://localhost:8000"
python3 -m http.server 8000
