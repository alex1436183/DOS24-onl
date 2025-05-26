provider "google" {
  project = "ordinal-reason-457811-u0"
  region  = "europe-north1"
}

resource "google_compute_instance" "ubuntu_zabbix" {
  name         = "zabbix"
  machine_type = "e2-medium"
  zone         = "europe-north1-b"

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20
    }
  }

  metadata = {
    startup-script = file("./user-data.sh")
    ssh-keys = join("\n", [
      "alex1743tms:${file("./key-pub.pub")}",
      "docker-swarm:${file("./id_rsa.pub")}"
    ])
  }

  tags = ["ssh", "zabbix"]

  network_interface {
    network    = google_compute_network.avl_vpc.self_link
    subnetwork = google_compute_subnetwork.avl_subnet.self_link
    access_config {}
  }
}

resource "google_compute_instance" "ubuntu_jenkins" {
  name         = "jenkins"
  machine_type = "custom-1-3072"
  zone         = "europe-north1-b"

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20
    }
  }

  metadata = {
    startup-script = file("./user-data.sh")
    ssh-keys = join("\n", [
      "alex1743tms:${file("./key-pub.pub")}",
      "docker-swarm:${file("./id_rsa.pub")}"
    ])
  }

  tags = ["ssh", "jenkins"]

  network_interface {
    network    = google_compute_network.avl_vpc.self_link
    subnetwork = google_compute_subnetwork.avl_subnet.self_link
  }
}

resource "google_compute_instance" "ubuntu_gitlab" {
  name         = "gitlab"
  machine_type = "custom-2-8192"
  zone         = "europe-north1-b"

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20
    }
  }

  metadata = {
    startup-script = file("./user-data.sh")
    ssh-keys       = "alex1743tms:${file("./key-pub.pub")}"
  }

  tags = ["ssh", "jenkins"]

  network_interface {
    network    = google_compute_network.avl_vpc.self_link
    subnetwork = google_compute_subnetwork.avl_subnet.self_link
    access_config {}
  }
}

resource "google_compute_instance" "ubuntu_ce" {
  count        = 3
  name         = "${var.instance_name}-${count.index + 2}"
  machine_type = "e2-micro"
  zone         = "europe-north1-b"

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
    }
  }

  metadata = {
    startup-script = file("./user-data.sh")
    ssh-keys = join("\n", [
      "alex1743tms:${file("./key-pub.pub")}",
      "docker-swarm:${file("./id_rsa.pub")}"
    ])
  }

  service_account {
    email  = google_service_account.gcs_storage.email
    scopes = ["https://www.googleapis.com/auth/devstorage.full_control"]
  }

  tags = ["docker-swarm"]

  network_interface {
    network    = google_compute_network.avl_vpc.self_link
    subnetwork = google_compute_subnetwork.avl_subnet.self_link

    dynamic "access_config" {
      for_each = count.index == 2 ? [] : [1]
      content {}
    }
  }
}


