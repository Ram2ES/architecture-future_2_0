# ============================================================
# Значения переменных для инфраструктуры «Будущее 2.0»
# ============================================================

cloud_id  = "b1g000000000000example"
folder_id = "b1g000000000000folder"

zone           = "ru-central1-a"
secondary_zone = "ru-central1-b"

network_name = "future20-network"

ssh_public_key_path = "~/.ssh/id_rsa.pub"
vm_image_id         = "fd8emvfmfoaordspe1jr"

# --- Подсети (по доменам + платформа) ---

subnets = {
  clinic = {
    zone       = "ru-central1-a"
    cidr_block = "10.10.1.0/24"
  }
  fintech = {
    zone       = "ru-central1-a"
    cidr_block = "10.10.2.0/24"
  }
  ai = {
    zone       = "ru-central1-a"
    cidr_block = "10.10.3.0/24"
  }
  hq = {
    zone       = "ru-central1-a"
    cidr_block = "10.10.4.0/24"
  }
  platform = {
    zone       = "ru-central1-a"
    cidr_block = "10.10.5.0/24"
  }
  platform-b = {
    zone       = "ru-central1-b"
    cidr_block = "10.10.6.0/24"
  }
}

# --- VM (можно переопределить конфигурации) ---

vm_configs = {
  kafka-1 = {
    cores       = 4
    memory      = 8
    disk_size   = 100
    disk_type   = "network-ssd"
    subnet_key  = "platform"
    platform_id = "standard-v3"
    preemptible = false
    description = "Kafka broker 1"
  }
  kafka-2 = {
    cores       = 4
    memory      = 8
    disk_size   = 100
    disk_type   = "network-ssd"
    subnet_key  = "platform-b"
    platform_id = "standard-v3"
    preemptible = false
    description = "Kafka broker 2 (реплика)"
  }
  db-clinic = {
    cores       = 4
    memory      = 16
    disk_size   = 200
    disk_type   = "network-ssd"
    subnet_key  = "clinic"
    platform_id = "standard-v3"
    preemptible = false
    description = "PostgreSQL - Клиники"
  }
  db-fintech = {
    cores       = 4
    memory      = 16
    disk_size   = 200
    disk_type   = "network-ssd"
    subnet_key  = "fintech"
    platform_id = "standard-v3"
    preemptible = false
    description = "PostgreSQL - Финтех"
  }
  db-hq = {
    cores       = 2
    memory      = 8
    disk_size   = 100
    disk_type   = "network-ssd"
    subnet_key  = "hq"
    platform_id = "standard-v3"
    preemptible = false
    description = "PostgreSQL - Головной офис"
  }
  clickhouse = {
    cores       = 8
    memory      = 32
    disk_size   = 500
    disk_type   = "network-ssd"
    subnet_key  = "platform"
    platform_id = "standard-v3"
    preemptible = false
    description = "ClickHouse - OLAP"
  }
  ai-worker = {
    cores       = 8
    memory      = 32
    disk_size   = 200
    disk_type   = "network-ssd"
    subnet_key  = "ai"
    platform_id = "gpu-standard-v2"
    preemptible = true
    description = "GPU - ИИ-домен"
  }
  keycloak = {
    cores       = 2
    memory      = 4
    disk_size   = 20
    disk_type   = "network-hdd"
    subnet_key  = "platform"
    platform_id = "standard-v3"
    preemptible = false
    description = "Keycloak - IAM"
  }
  portal = {
    cores       = 4
    memory      = 8
    disk_size   = 50
    disk_type   = "network-ssd"
    subnet_key  = "platform"
    platform_id = "standard-v3"
    preemptible = false
    description = "Superset - портал"
  }
  api-gateway = {
    cores       = 2
    memory      = 4
    disk_size   = 20
    disk_type   = "network-hdd"
    subnet_key  = "platform"
    platform_id = "standard-v3"
    preemptible = false
    description = "Kong - API Gateway"
  }
}

# --- S3-бакеты ---

s3_buckets = {
  medical-images = {
    acl         = "private"
    description = "Мед. изображения для ИИ-домена"
  }
  ml-models = {
    acl         = "private"
    description = "ML-модели и артефакты"
  }
  backups = {
    acl         = "private"
    description = "Резервные копии БД"
  }
}
