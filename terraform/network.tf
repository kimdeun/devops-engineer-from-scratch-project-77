resource "yandex_vpc_network" "main" {
  name = "project-77-network"
}

resource "yandex_vpc_subnet" "main" {
  name           = "project-77-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.20.0.0/24"]
}

resource "yandex_vpc_security_group" "web" {
  name       = "project-77-web"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "Application Load Balancer health checks"
    port              = 80
    predefined_target = "loadbalancer_healthchecks"
  }

  ingress {
    protocol          = "TCP"
    description       = "Traffic from Application Load Balancer nodes"
    port              = 80
    security_group_id = yandex_vpc_security_group.alb.id
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH administration"
    port           = 22
    v4_cidr_blocks = var.ssh_allowed_cidrs
  }

  egress {
    protocol       = "ANY"
    description    = "Outbound access"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "alb" {
  name       = "project-77-alb"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Public HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    description    = "Traffic to web servers"
    port           = 80
    v4_cidr_blocks = ["10.20.0.0/24"]
  }
}
