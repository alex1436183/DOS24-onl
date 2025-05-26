resource "google_compute_network" "avl_vpc" {
  name                    = "avl-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "avl_subnet" {
  name          = "avl-subnet"
  network       = google_compute_network.avl_vpc.self_link
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-north1"
}

resource "google_compute_firewall" "http_https_ssh" {
  name    = "allow-http-https-ssh"
  network = google_compute_network.avl_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "8443", "443", "22", "10050", "9000", "8000", "9443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "docker_swarm" {
  name    = "docker-swarm"
  network = google_compute_network.avl_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["2377", "7946"]
  }

  allow {
    protocol = "udp"
    ports    = ["7946", "4789"]
  }

  target_tags = ["docker-swarm"]

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_nfs" {
  name    = "allow-nfs"
  network = google_compute_network.avl_vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["2049", "111", "32765-32769"]
  }

  allow {
    protocol = "udp"
    ports    = ["2049", "111", "32765-32769"]
  }

  source_ranges = ["10.0.1.0/24"]
  target_tags   = ["docker-swarm"]
}



resource "google_compute_firewall" "allow_icmp_internal" {
  name    = "allow-icmp-internal"
  network = google_compute_network.avl_vpc.name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.1.0/24"]
  direction     = "INGRESS"
  priority      = 1000
  description   = "Allow ICMP traffic within the internal network"
}

resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  region  = "europe-north1"
  network = google_compute_network.avl_vpc.name
}

resource "google_compute_router_nat" "nat_gateway" {
  name                               = "nat-gateway"
  router                             = google_compute_router.nat_router.name
  region                             = "europe-north1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
