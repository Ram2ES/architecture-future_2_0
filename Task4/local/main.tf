# ============================================================
# Инфраструктура «Будущее 2.0» - Локальная версия (Docker)
# ============================================================
#
# Локальная эмуляция облачной инфраструктуры через Docker:
#   - Docker networks  → VPC подсети
#   - Docker containers → VM (Kafka, PostgreSQL, ClickHouse, и др.)
#   - MinIO container   → S3-бакеты
#
# Запуск:
#   cd Task4/local
#   terraform init
#   terraform plan
#   terraform apply
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# ============================================================
# 1. СЕТИ (Docker networks → VPC подсети)
# ============================================================

resource "docker_network" "subnets" {
  for_each = var.subnets

  name   = "${var.network_name}-${each.key}"
  driver = "bridge"

  ipam_config {
    subnet  = each.value.cidr_block
    gateway = cidrhost(each.value.cidr_block, 1)
  }
}

# ============================================================
# 2. ОБРАЗЫ
# ============================================================

resource "docker_image" "ubuntu" {
  name         = "ubuntu:22.04"
  keep_locally = true
}

resource "docker_image" "postgres" {
  name         = "postgres:15"
  keep_locally = true
}

resource "docker_image" "kafka" {
  name         = "apache/kafka:3.7.0"
  keep_locally = true
}

resource "docker_image" "clickhouse" {
  name         = "clickhouse/clickhouse-server:23.8"
  keep_locally = true
}

resource "docker_image" "keycloak" {
  name         = "quay.io/keycloak/keycloak:23.0"
  keep_locally = true
}

resource "docker_image" "minio" {
  name         = "minio/minio:latest"
  keep_locally = true
}

resource "docker_image" "kong" {
  name         = "kong:3.5"
  keep_locally = true
}

resource "docker_image" "superset" {
  name         = "apache/superset:3.0.0"
  keep_locally = true
}

# ============================================================
# 3. КОНТЕЙНЕРЫ (Docker containers → VM)
# ============================================================

# --- Kafka брокеры ---

resource "docker_container" "kafka_1" {
  name  = "kafka-1"
  image = docker_image.kafka.image_id

  env = [
    "KAFKA_NODE_ID=1",
    "KAFKA_PROCESS_ROLES=broker,controller",
    "KAFKA_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093",
    "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka-1:9092",
    "KAFKA_CONTROLLER_QUORUM_VOTERS=1@kafka-1:9093,2@kafka-2:9093",
    "KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER",
    "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT",
    "CLUSTER_ID=local-future20-cluster-id01",
  ]

  networks_advanced {
    name = docker_network.subnets["platform"].id
  }

  ports {
    internal = 9092
    external = 9092
  }

  memory = 512
}

resource "docker_container" "kafka_2" {
  name  = "kafka-2"
  image = docker_image.kafka.image_id

  env = [
    "KAFKA_NODE_ID=2",
    "KAFKA_PROCESS_ROLES=broker,controller",
    "KAFKA_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093",
    "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka-2:9092",
    "KAFKA_CONTROLLER_QUORUM_VOTERS=1@kafka-1:9093,2@kafka-2:9093",
    "KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER",
    "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT",
    "CLUSTER_ID=local-future20-cluster-id01",
  ]

  networks_advanced {
    name = docker_network.subnets["platform"].id
  }

  ports {
    internal = 9092
    external = 9093
  }

  memory = 512
}

# --- PostgreSQL (доменные БД) ---

resource "docker_container" "db_clinic" {
  name  = "db-clinic"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_DB=clinic",
    "POSTGRES_USER=clinic_user",
    "POSTGRES_PASSWORD=clinic_pass_local",
  ]

  networks_advanced {
    name = docker_network.subnets["clinic"].id
  }

  ports {
    internal = 5432
    external = 5432
  }

  memory = 256
}

resource "docker_container" "db_fintech" {
  name  = "db-fintech"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_DB=fintech",
    "POSTGRES_USER=fintech_user",
    "POSTGRES_PASSWORD=fintech_pass_local",
  ]

  networks_advanced {
    name = docker_network.subnets["fintech"].id
  }

  ports {
    internal = 5432
    external = 5433
  }

  memory = 256
}

resource "docker_container" "db_hq" {
  name  = "db-hq"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_DB=hq",
    "POSTGRES_USER=hq_user",
    "POSTGRES_PASSWORD=hq_pass_local",
  ]

  networks_advanced {
    name = docker_network.subnets["hq"].id
  }

  ports {
    internal = 5432
    external = 5434
  }

  memory = 256
}

# --- ClickHouse ---

resource "docker_container" "clickhouse" {
  name  = "clickhouse"
  image = docker_image.clickhouse.image_id

  networks_advanced {
    name = docker_network.subnets["platform"].id
  }

  ports {
    internal = 8123
    external = 8123
  }

  ports {
    internal = 9000
    external = 9000
  }

  memory = 512
}

# --- AI Worker (эмуляция GPU-сервера обычным Ubuntu-контейнером) ---

resource "docker_container" "ai_worker" {
  name    = "ai-worker"
  image   = docker_image.ubuntu.image_id
  command = ["sleep", "infinity"]

  networks_advanced {
    name = docker_network.subnets["ai"].id
  }

  memory = 256
}

# --- Keycloak (IAM) ---

resource "docker_container" "keycloak" {
  name  = "keycloak"
  image = docker_image.keycloak.image_id

  command = ["start-dev"]

  env = [
    "KEYCLOAK_ADMIN=admin",
    "KEYCLOAK_ADMIN_PASSWORD=admin",
  ]

  networks_advanced {
    name = docker_network.subnets["platform"].id
  }

  ports {
    internal = 8080
    external = 8080
  }

  memory = 512
}

# --- Portal (Apache Superset) ---

resource "docker_container" "portal" {
  name  = "portal"
  image = docker_image.superset.image_id

  env = [
    "SUPERSET_SECRET_KEY=local-secret-key-for-dev",
  ]

  networks_advanced {
    name = docker_network.subnets["platform"].id
  }

  ports {
    internal = 8088
    external = 8088
  }

  memory = 512
}

# --- API Gateway (Kong) ---

resource "docker_container" "api_gateway" {
  name  = "api-gateway"
  image = docker_image.kong.image_id

  env = [
    "KONG_DATABASE=off",
    "KONG_PROXY_ACCESS_LOG=/dev/stdout",
    "KONG_ADMIN_ACCESS_LOG=/dev/stdout",
    "KONG_PROXY_ERROR_LOG=/dev/stderr",
    "KONG_ADMIN_ERROR_LOG=/dev/stderr",
    "KONG_ADMIN_LISTEN=0.0.0.0:8001",
    "KONG_PROXY_LISTEN=0.0.0.0:8000, 0.0.0.0:8443 ssl",
  ]

  networks_advanced {
    name = docker_network.subnets["platform"].id
  }

  ports {
    internal = 8000
    external = 80
  }

  ports {
    internal = 8443
    external = 443
  }

  ports {
    internal = 8001
    external = 8001
  }

  memory = 256
}

# ============================================================
# 4. S3 (MinIO → эмуляция Yandex Object Storage)
# ============================================================

resource "docker_container" "minio" {
  name  = "minio-s3"
  image = docker_image.minio.image_id

  command = ["server", "/data", "--console-address", ":9001"]

  env = [
    "MINIO_ROOT_USER=minioadmin",
    "MINIO_ROOT_PASSWORD=minioadmin",
  ]

  networks_advanced {
    name = docker_network.subnets["platform"].id
  }

  ports {
    internal = 9000
    external = 9010
  }

  ports {
    internal = 9001
    external = 9011
  }

  volumes {
    host_path      = abspath("${path.module}/minio-data")
    container_path = "/data"
  }

  memory = 256
}
