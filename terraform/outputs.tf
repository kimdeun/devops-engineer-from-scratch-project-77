output "web_server_ips" {
  description = "Public IP addresses used by the Ansible inventory."
  value       = yandex_compute_instance.web[*].network_interface[0].nat_ip_address
}

output "load_balancer_ip" {
  description = "Public IPv4 address of the HTTPS load balancer."
  value       = yandex_alb_load_balancer.web.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "application_url" {
  description = "Application endpoint. Certificate hostname should point to this address."
  value       = "https://${var.domain_name}"
}

output "datadog_monitor_id" {
  description = "ID of the application HTTP service-check monitor."
  value       = datadog_monitor.application_http.id
}
