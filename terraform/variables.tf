variable "yc_cloud_id" {
  description = "Yandex Cloud cloud ID."
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud folder ID."
  type        = string
}

variable "ssh_public_key" {
  description = "Public key installed for the ubuntu user."
  type        = string
}

variable "domain_name" {
  description = "Public DuckDNS hostname of the application."
  type        = string
  default     = "hexlet-project-77.duckdns.org"
}

variable "duckdns_token" {
  description = "DuckDNS API token used for the A record and ACME DNS challenge."
  type        = string
  sensitive   = true
}

variable "datadog_api_key" {
  description = "Datadog API key used by the provider and agents."
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Datadog application key used by the Terraform provider."
  type        = string
  sensitive   = true
}

variable "acme_email" {
  description = "Email used for the Let's Encrypt account."
  type        = string
  default     = "vongersakh@gmail.com"
}

variable "domain_ipv4_address" {
  description = "Current public IPv4 address of the application load balancer."
  type        = string
  default     = "158.160.182.170"
}

variable "zone" {
  description = "Availability zone."
  type        = string
  default     = "ru-central1-a"
}

variable "ssh_allowed_cidrs" {
  description = "Networks allowed to connect to the web servers over SSH."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_platform_id" {
  description = "Compute platform for web servers."
  type        = string
  default     = "standard-v3"
}

variable "image_family" {
  description = "Ubuntu image family."
  type        = string
  default     = "ubuntu-2204-lts"
}
