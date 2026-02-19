# ============================================================
# Выходные параметры локальной инфраструктуры «Будущее 2.0»
# ============================================================

# --- Сети ---

output "network_ids" {
  description = "ID Docker-сетей по доменам"
  value = {
    for k, v in docker_network.subnets : k => v.id
  }
}

# --- Kafka ---

output "kafka_brokers" {
  description = "Kafka-брокеры (localhost)"
  value = [
    "localhost:9092",
    "localhost:9093",
  ]
}

# --- Базы данных ---

output "db_endpoints" {
  description = "Эндпоинты PostgreSQL (localhost)"
  value = {
    clinic  = "localhost:5432"
    fintech = "localhost:5433"
    hq      = "localhost:5434"
  }
}

output "clickhouse_endpoint" {
  description = "Эндпоинт ClickHouse HTTP (localhost)"
  value       = "localhost:8123"
}

# --- S3 (MinIO) ---

output "s3_endpoint" {
  description = "MinIO S3 API endpoint"
  value       = "localhost:9010"
}

output "s3_console" {
  description = "MinIO Web Console"
  value       = "localhost:9011"
}

# --- Web-сервисы ---

output "keycloak_url" {
  description = "Keycloak Admin Console"
  value       = "http://localhost:8080"
}

output "portal_url" {
  description = "Apache Superset (портал самообслуживания)"
  value       = "http://localhost:8088"
}

output "api_gateway_url" {
  description = "API Gateway (Kong) proxy"
  value       = "http://localhost:80"
}

output "api_gateway_admin_url" {
  description = "Kong Admin API"
  value       = "http://localhost:8001"
}
