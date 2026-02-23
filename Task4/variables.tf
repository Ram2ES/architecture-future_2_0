# ============================================================
# Переменные Terraform для инфраструктуры «Будущее 2.0»
# ============================================================

# --- Общие ---

variable "cloud_id" {
  description = "ID облака Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "ID каталога Yandex Cloud"
  type        = string
}

variable "zone" {
  description = "Зона доступности по умолчанию"
  type        = string
  default     = "ru-central1-a"
}

variable "secondary_zone" {
  description = "Вторая зона доступности (для отказоустойчивости)"
  type        = string
  default     = "ru-central1-b"
}

# --- Сеть ---

variable "network_name" {
  description = "Имя VPC-сети"
  type        = string
  default     = "future20-network"
}

variable "subnets" {
  description = "Подсети по доменам"
  type = map(object({
    zone       = string
    cidr_block = string
  }))
  default = {
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
}

# --- Виртуальные машины ---

variable "vm_configs" {
  description = "Конфигурации VM по ролям"
  type = map(object({
    cores         = number
    memory        = number
    disk_size     = number
    disk_type     = string
    subnet_key    = string
    platform_id   = string
    preemptible   = bool
    description   = string
  }))
  default = {
    # Kafka-брокер (событийная шина между доменами)
    kafka-1 = {
      cores       = 4
      memory      = 8
      disk_size   = 100
      disk_type   = "network-ssd"
      subnet_key  = "platform"
      platform_id = "standard-v3"
      preemptible = false
      description = "Kafka broker 1 - событийная шина"
    }
    kafka-2 = {
      cores       = 4
      memory      = 8
      disk_size   = 100
      disk_type   = "network-ssd"
      subnet_key  = "platform-b"
      platform_id = "standard-v3"
      preemptible = false
      description = "Kafka broker 2 - событийная шина (реплика)"
    }

    # PostgreSQL (доменные БД)
    db-clinic = {
      cores       = 4
      memory      = 16
      disk_size   = 200
      disk_type   = "network-ssd"
      subnet_key  = "clinic"
      platform_id = "standard-v3"
      preemptible = false
      description = "PostgreSQL - домен Клиники"
    }
    db-fintech = {
      cores       = 4
      memory      = 16
      disk_size   = 200
      disk_type   = "network-ssd"
      subnet_key  = "fintech"
      platform_id = "standard-v3"
      preemptible = false
      description = "PostgreSQL - домен Финтех"
    }
    db-hq = {
      cores       = 2
      memory      = 8
      disk_size   = 100
      disk_type   = "network-ssd"
      subnet_key  = "hq"
      platform_id = "standard-v3"
      preemptible = false
      description = "PostgreSQL - домен Головной офис"
    }

    # ClickHouse (аналитическая СУБД для портала)
    clickhouse = {
      cores       = 8
      memory      = 32
      disk_size   = 500
      disk_type   = "network-ssd"
      subnet_key  = "platform"
      platform_id = "standard-v3"
      preemptible = false
      description = "ClickHouse - OLAP для портала самообслуживания"
    }

    # ИИ-сервер (GPU)
    ai-worker = {
      cores       = 8
      memory      = 32
      disk_size   = 200
      disk_type   = "network-ssd"
      subnet_key  = "ai"
      platform_id = "gpu-standard-v2"
      preemptible = true
      description = "GPU-сервер - ИИ-домен (прерываемая, для экономии)"
    }

    # Keycloak (IAM)
    keycloak = {
      cores       = 2
      memory      = 4
      disk_size   = 20
      disk_type   = "network-hdd"
      subnet_key  = "platform"
      platform_id = "standard-v3"
      preemptible = false
      description = "Keycloak - IAM, SSO, ролевой доступ"
    }

    # Портал самообслуживания (Superset)
    portal = {
      cores       = 4
      memory      = 8
      disk_size   = 50
      disk_type   = "network-ssd"
      subnet_key  = "platform"
      platform_id = "standard-v3"
      preemptible = false
      description = "Apache Superset - портал самообслуживания"
    }

    # API Gateway
    api-gateway = {
      cores       = 2
      memory      = 4
      disk_size   = 20
      disk_type   = "network-hdd"
      subnet_key  = "platform"
      platform_id = "standard-v3"
      preemptible = false
      description = "API Gateway (Kong) - точка входа для партнёров"
    }
  }
}

# --- S3 (объектное хранилище) ---

variable "s3_buckets" {
  description = "S3-бакеты для хранения объектов"
  type = map(object({
    acl         = string
    description = string
  }))
  default = {
    medical-images = {
      acl         = "private"
      description = "Мед. изображения (рентген, МРТ) - передаются в ИИ-домен"
    }
    ml-models = {
      acl         = "private"
      description = "ML-модели и артефакты обучения"
    }
    backups = {
      acl         = "private"
      description = "Резервные копии доменных БД"
    }
  }
}

# --- SSH ---

variable "ssh_public_key_path" {
  description = "Путь к публичному SSH-ключу для доступа к VM"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# --- Образ ОС ---

variable "vm_image_id" {
  description = "ID образа ОС (Ubuntu 22.04 LTS)"
  type        = string
  default     = "fd8emvfmfoaordspe1jr"
}
