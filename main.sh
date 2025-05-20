#!/bin/bash

# Fungsi untuk mengenkripsi file
encrypt_file() {
    local file="$1"
    local encrypted_file="${file}.enc"

    echo "Mengenkripsi file ${file}..."
    openssl enc -aes-256-cbc -salt -in "$file" -out "$encrypted_file" -k "supersecurepassword"

    if [[ -f "$encrypted_file" ]]; then
        echo "File berhasil dienkripsi: ${encrypted_file}"
        rm -f "$file"  # Hapus file asli
    else
        echo "Enkripsi gagal."
        exit 1
    fi
}

# Fungsi untuk menanyakan URL
prompt_version_url() {
    read -p "Masukkan URL Windows yang Anda inginkan: " version_url
    echo "$version_url"
}

# Periksa apakah Docker sudah diinstal
if ! command -v docker &> /dev/null; then
    echo "Docker belum terinstal. Menginstal Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm -f get-docker.sh
else
    echo "Docker sudah terinstal."
fi

# Periksa apakah Docker Compose sudah diinstal
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose belum terinstal. Menginstal Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose sudah terinstal."
fi

# Buat file docker-compose.yml
echo "Membuat file konfigurasi Docker Compose..."
version_url=$(prompt_version_url)

cat <<EOF > docker-compose.yml
version: '3.8'
services:
  windows:
    image: diana591/windows-master:v2.0
    container_name: windows
    environment:
      USERNAME: "Mpragans"
      PASSWORD: "123456"
      DISK_SIZE: "92G"
      CPU_CORES: "4"
      RAM_SIZE: "11G"
      REGION: "en-US"
      KEYBOARD: "en-US"
      VERSION: "$version_url"
    volumes:
      - /tmp/winmoon:/storage
    devices:
      - /dev/kvm
    cap_add:
      - NET_ADMIN
    ports:
      - 8006:8006
      - 3389:3389/tcp
      - 3389:3389/udp
    stop_grace_period: 2m
EOF

# Enkripsi file docker-compose.yml
encrypt_file "docker-compose.yml"

# Jalankan Docker Compose
echo "Menjalankan Docker Compose..."
if [[ -f "docker-compose.yml.enc" ]]; then
    openssl enc -aes-256-cbc -d -in docker-compose.yml.enc -out docker-compose.yml -k "supersecurepassword"
    docker-compose up -d
    rm -f docker-compose.yml  # Hapus file plaintext setelah digunakan
else
    echo "File konfigurasi tidak ditemukan atau enkripsi gagal."
    exit 1
fi

echo "Layanan Docker berhasil dijalankan."

# Timer Python untuk loop tanpa akhir
python3 - <<EOF
import datetime
import time

def print_elapsed_time():
    start_time = datetime.datetime.now()
    print("Timer dimulai. Tekan Ctrl+C untuk menghentikan.")

    while True:
        current_time = datetime.datetime.now()
        elapsed_time = current_time - start_time
        seconds_elapsed = elapsed_time.total_seconds()

        print(f"Waktu berlalu: {int(seconds_elapsed)} detik", end="\r", flush=True)
        time.sleep(1)

if __name__ == "__main__":
    print_elapsed_time()
EOF
