# ============================================================
# Выходные параметры инфраструктуры «Будущее 2.0»
# ============================================================

# --- Сеть ---

output "network_id" {
  description = "ID VPC-сети"
  value       = yandex_vpc_network.main.id
}

output "subnet_ids" {
  description = "ID подсетей по доменам"
  value = {
    for k, v in yandex_vpc_subnet.subnets : k => v.id
  }
}

# --- VM ---

output "vm_internal_ips" {
  description = "Внутренние IP-адреса виртуальных машин"
  value = {
    for k, v in yandex_compute_instance.vms : k => v.network_interface[0].ip_address
  }
}

output "vm_ids" {
  description = "ID виртуальных машин"
  value = {
    for k, v in yandex_compute_instance.vms : k => v.id
  }
}

# --- Kafka ---

output "kafka_brokers" {
  description = "IP-адреса Kafka-брокеров (для bootstrap.servers)"
  value = [
    "${yandex_compute_instance.vms["kafka-1"].network_interface[0].ip_address}:9092",
    "${yandex_compute_instance.vms["kafka-2"].network_interface[0].ip_address}:9092",
  ]
}

# --- Базы данных ---

output "db_endpoints" {
  description = "Эндпоинты PostgreSQL (host:port)"
  value = {
    clinic  = "${yandex_compute_instance.vms["db-clinic"].network_interface[0].ip_address}:5432"
    fintech = "${yandex_compute_instance.vms["db-fintech"].network_interface[0].ip_address}:5432"
    hq      = "${yandex_compute_instance.vms["db-hq"].network_interface[0].ip_address}:5432"
  }
}

output "clickhouse_endpoint" {
  description = "Эндпоинт ClickHouse (HTTP)"
  value       = "${yandex_compute_instance.vms["clickhouse"].network_interface[0].ip_address}:8123"
}

# --- S3 ---

output "s3_bucket_names" {
  description = "Имена S3-бакетов"
  value = {
    for k, v in yandex_storage_bucket.buckets : k => v.bucket
  }
}

# --- API Gateway ---

output "api_gateway_public_ip" {
  description = "Публичный IP API Gateway (точка входа для партнёров)"
  value       = yandex_vpc_address.api_gw_ip.external_ipv4_address[0].address
}

# --- Портал ---

output "portal_internal_ip" {
  description = "Внутренний IP портала самообслуживания"
  value       = yandex_compute_instance.vms["portal"].network_interface[0].ip_address
}

# --- Keycloak ---

output "keycloak_internal_ip" {
  description = "Внутренний IP Keycloak (IAM)"
  value       = yandex_compute_instance.vms["keycloak"].network_interface[0].ip_address
}
