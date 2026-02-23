# ============================================================
# Инфраструктура «Будущее 2.0» - Yandex Cloud (IaaS)
# ============================================================
#
# Компоненты, управляемые Terraform:
#   - VPC (сеть, подсети, NAT-шлюз, таблица маршрутизации)
#   - VM (Kafka, PostgreSQL, ClickHouse, GPU, Keycloak, Portal, API GW)
#   - Диски (загрузочные - внутри VM)
#   - S3-бакеты (мед. изображения, ML-модели, бэкапы)
#   - Security Groups (сетевые правила по доменам)
#
# Компоненты, разворачиваемые вручную:
#   - DNS-записи (зависят от корпоративного DNS-провайдера)
#   - SSL-сертификаты (Let's Encrypt / корпоративный CA)
#   - Настройка ПО на VM (Ansible/скрипты после provisioning)
#   - Мониторинг (Prometheus + Grafana - устанавливаются поверх VM)
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100.0"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

# ============================================================
# 1. СЕТЬ (VPC)
# ============================================================

resource "yandex_vpc_network" "main" {
  name        = var.network_name
  description = "VPC-сеть для всех доменов «Будущее 2.0»"
}

# --- Подсети (по доменам) ---

resource "yandex_vpc_subnet" "subnets" {
  for_each = var.subnets

  name           = "${var.network_name}-${each.key}"
  description    = "Подсеть домена: ${each.key}"
  network_id     = yandex_vpc_network.main.id
  zone           = each.value.zone
  v4_cidr_blocks = [each.value.cidr_block]
  route_table_id = yandex_vpc_route_table.nat.id
}

# --- NAT Gateway (доступ в интернет для VM без публичных IP) ---

resource "yandex_vpc_gateway" "nat" {
  name = "${var.network_name}-nat-gw"

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat" {
  name       = "${var.network_name}-nat-rt"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

# ============================================================
# 2. SECURITY GROUPS (сетевые правила)
# ============================================================

# --- Базовая группа: SSH + исходящий трафик ---
resource "yandex_vpc_security_group" "base" {
  name       = "sg-base"
  network_id = yandex_vpc_network.main.id

  ingress {
    description    = "SSH (администрирование)"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    description    = "Исходящий трафик"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Kafka ---
resource "yandex_vpc_security_group" "kafka" {
  name       = "sg-kafka"
  network_id = yandex_vpc_network.main.id

  ingress {
    description    = "Kafka broker"
    protocol       = "TCP"
    port           = 9092
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description    = "Kafka inter-broker"
    protocol       = "TCP"
    port           = 9093
    v4_cidr_blocks = ["10.10.5.0/24", "10.10.6.0/24"]
  }
}

# --- PostgreSQL ---
resource "yandex_vpc_security_group" "postgres" {
  name       = "sg-postgres"
  network_id = yandex_vpc_network.main.id

  ingress {
    description    = "PostgreSQL"
    protocol       = "TCP"
    port           = 5432
    v4_cidr_blocks = ["10.10.0.0/16"]
  }
}

# --- ClickHouse ---
resource "yandex_vpc_security_group" "clickhouse" {
  name       = "sg-clickhouse"
  network_id = yandex_vpc_network.main.id

  ingress {
    description    = "ClickHouse HTTP"
    protocol       = "TCP"
    port           = 8123
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description    = "ClickHouse native"
    protocol       = "TCP"
    port           = 9000
    v4_cidr_blocks = ["10.10.0.0/16"]
  }
}

# --- Web (портал, Keycloak, API GW) ---
resource "yandex_vpc_security_group" "web" {
  name       = "sg-web"
  network_id = yandex_vpc_network.main.id

  ingress {
    description    = "HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================================================
# 3. ВИРТУАЛЬНЫЕ МАШИНЫ
# ============================================================

resource "yandex_compute_instance" "vms" {
  for_each = var.vm_configs

  name        = each.key
  hostname    = each.key
  platform_id = each.value.platform_id
  zone        = var.subnets[each.value.subnet_key].zone
  description = each.value.description

  resources {
    cores  = each.value.cores
    memory = each.value.memory
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = each.value.disk_size
      type     = each.value.disk_type
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnets[each.value.subnet_key].id
    security_group_ids = local.vm_security_groups[each.key]
  }

  scheduling_policy {
    preemptible = each.value.preemptible
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

# --- Маппинг VM -> Security Groups ---

locals {
  vm_security_groups = {
    kafka-1     = [yandex_vpc_security_group.base.id, yandex_vpc_security_group.kafka.id]
    kafka-2     = [yandex_vpc_security_group.base.id, yandex_vpc_security_group.kafka.id]
    db-clinic   = [yandex_vpc_security_group.base.id, yandex_vpc_security_group.postgres.id]
    db-fintech  = [yandex_vpc_security_group.base.id, yandex_vpc_security_group.postgres.id]
    db-hq       = [yandex_vpc_security_group.base.id, yandex_vpc_security_group.postgres.id]
    clickhouse  = [yandex_vpc_security_group.base.id, yandex_vpc_security_group.clickhouse.id]
    ai-worker   = [yandex_vpc_security_group.base.id]
    keycloak    = [yandex_vpc_security_group.base.id, yandex_vpc_security_group.web.id]
    portal      = [yandex_vpc_security_group.base.id, yandex_vpc_security_group.web.id]
    api-gateway = [yandex_vpc_security_group.base.id, yandex_vpc_security_group.web.id]
  }
}

# ============================================================
# 4. S3-БАКЕТЫ (объектное хранилище)
# ============================================================

resource "yandex_storage_bucket" "buckets" {
  for_each = var.s3_buckets

  bucket = "future20-${each.key}"
  acl    = each.value.acl

  versioning {
    enabled = true
  }
}

# ============================================================
# 5. СТАТИЧЕСКИЙ IP (для API Gateway - точка входа партнёров)
# ============================================================

resource "yandex_vpc_address" "api_gw_ip" {
  name = "api-gateway-public-ip"

  external_ipv4_address {
    zone_id = var.zone
  }
}
