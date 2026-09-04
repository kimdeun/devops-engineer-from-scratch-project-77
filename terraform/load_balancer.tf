resource "terraform_data" "duckdns_a_record" {
  triggers_replace = [
    var.domain_name,
    var.domain_ipv4_address,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      response=$(curl --fail --silent --show-error --get "https://www.duckdns.org/update" \
        --data-urlencode "domains=${trimsuffix(var.domain_name, ".duckdns.org")}" \
        --data-urlencode "token=${var.duckdns_token}" \
        --data-urlencode "ip=${var.domain_ipv4_address}")
      test "$response" = "OK"
    EOT
  }
}

resource "tls_private_key" "acme_account" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "acme_registration" "main" {
  account_key_pem = tls_private_key.acme_account.private_key_pem
  email_address   = var.acme_email
}

resource "acme_certificate" "https" {
  account_key_pem = acme_registration.main.account_key_pem
  common_name     = var.domain_name

  dns_challenge {
    provider = "duckdns"
    config = {
      DUCKDNS_TOKEN = var.duckdns_token
    }
  }

  depends_on = [terraform_data.duckdns_a_record]
}

resource "yandex_cm_certificate" "https_public" {
  name = "project-77-letsencrypt"

  self_managed {
    certificate = "${acme_certificate.https.certificate_pem}${acme_certificate.https.issuer_pem}"
    private_key = acme_certificate.https.private_key_pem
  }
}

resource "yandex_alb_target_group" "web" {
  name = "project-77-web"

  dynamic "target" {
    for_each = yandex_compute_instance.web
    content {
      subnet_id  = yandex_vpc_subnet.main.id
      ip_address = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_alb_backend_group" "web" {
  name = "project-77-web"

  http_backend {
    name             = "project-77-web"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web.id]

    load_balancing_config {
      panic_threshold = 50
    }

    healthcheck {
      timeout  = "3s"
      interval = "5s"
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web" {
  name = "project-77-router"
}

resource "yandex_alb_virtual_host" "web" {
  name           = "project-77-vhost"
  http_router_id = yandex_alb_http_router.web.id

  route {
    name = "project-77-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web.id
        timeout          = "60s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web" {
  name               = "project-77-alb"
  network_id         = yandex_vpc_network.main.id
  security_group_ids = [yandex_vpc_security_group.alb.id]

  allocation_policy {
    location {
      zone_id   = var.zone
      subnet_id = yandex_vpc_subnet.main.id
    }
  }

  listener {
    name = "https"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [443]
    }
    tls {
      default_handler {
        certificate_ids = [yandex_cm_certificate.https_public.id]
        http_handler {
          http_router_id = yandex_alb_http_router.web.id
        }
      }
    }
  }
}
