# ============================================================
# Переменные для локальной инфраструктуры «Будущее 2.0»
# ============================================================

variable "network_name" {
  description = "Префикс имён Docker-сетей"
  type        = string
  default     = "future20-network"
}

variable "subnets" {
  description = "Docker-сети, эмулирующие подсети по доменам"
  type = map(object({
    zone       = string
    cidr_block = string
  }))
  default = {
    clinic = {
      zone       = "local"
      cidr_block = "10.10.1.0/24"
    }
    fintech = {
      zone       = "local"
      cidr_block = "10.10.2.0/24"
    }
    ai = {
      zone       = "local"
      cidr_block = "10.10.3.0/24"
    }
    hq = {
      zone       = "local"
      cidr_block = "10.10.4.0/24"
    }
    platform = {
      zone       = "local"
      cidr_block = "10.10.5.0/24"
    }
    platform-b = {
      zone       = "local"
      cidr_block = "10.10.6.0/24"
    }
  }
}
