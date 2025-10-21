#!/bin/bash
# Redis + Socket.io Kurulum Script
# Sunucu: 37.148.210.244

echo "🚀 Redis + Socket.io Kurulum Başlıyor..."
echo ""

# 1. Redis kurulumu
echo "📦 Redis kuruluyor..."
sudo apt-get update
sudo apt-get install -y redis-server

# Redis'i başlat ve otomatik başlatmayı etkinleştir
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Redis testini yap
echo "🧪 Redis test ediliyor..."
redis-cli ping

echo ""
echo "✅ Redis kurulumu tamamlandı!"
echo ""

# 2. API dizinine git
echo "📂 API dizinine gidiliyor..."
cd /home/unicampus/api

# 3. Socket.io ve Redis paketlerini yükle
echo "📦 Socket.io ve Redis paketleri kuruluyor..."
npm install socket.io redis@4.6.7

echo ""
echo "✅ Paketler yüklendi!"
echo ""

# 4. .env dosyasına Redis ayarlarını ekle (eğer yoksa)
echo "⚙️ .env dosyası kontrol ediliyor..."
if ! grep -q "REDIS_HOST" .env; then
    echo "" >> .env
    echo "# Redis Configuration" >> .env
    echo "REDIS_HOST=localhost" >> .env
    echo "REDIS_PORT=6379" >> .env
    echo "✅ Redis ayarları .env dosyasına eklendi"
else
    echo "✅ Redis ayarları zaten mevcut"
fi

echo ""
echo "🔄 PM2 ile API yeniden başlatılıyor..."
pm2 restart unicampus-api

echo ""
echo "📊 PM2 durumu:"
pm2 list

echo ""
echo "📝 Son loglar:"
pm2 logs unicampus-api --lines 20 --nostream

echo ""
echo "✅ KURULUM TAMAMLANDI!"
echo ""
echo "🎯 Kontrol Komutları:"
echo "  - Redis: redis-cli ping"
echo "  - PM2: pm2 logs unicampus-api"
echo "  - Health: curl http://localhost:3000/health"
echo ""
