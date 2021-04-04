data "template_file" "metadata_startup_script_staging" {
  template = file("start-up-script_staging.sh")
}

data "template_file" "metadata_startup_script_prod" {
  template = file("start-up-script_prod.sh")
}

resource "google_compute_address" "ip_address_staging" {
  name = "ipv4-address-staging"
}

resource "google_compute_address" "ip_address_prod" {
  name = "ipv4-address-prod"
}

resource "google_compute_instance" "vm_instance" {
  name         = "staging"
  machine_type = "n1-standard-1"
  zone         = var.zone

  metadata = {
    ssh-keys = "${var.gce_ssh_user}:${var.gce_ssh_pub_key_file}"
  }

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  metadata_startup_script = data.template_file.metadata_startup_script_staging.rendered

  network_interface {
    network       = google_compute_network.vpc_network.self_link
    subnetwork       = google_compute_subnetwork.vpc_subnet.self_link
    access_config {
      nat_ip = google_compute_address.ip_address_staging.address
    }
  }
}

resource "google_compute_instance" "vm_instance2" {
  name         = "production"
  machine_type = "n1-standard-1"
  zone         = var.zone

  metadata = {
    ssh-keys = "${var.gce_ssh_user}:${var.gce_ssh_pub_key_file}"
  }

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  metadata_startup_script = data.template_file.metadata_startup_script_prod.rendered

  network_interface {
    network       = google_compute_network.vpc_network.self_link
    subnetwork       = google_compute_subnetwork.vpc_subnet.self_link
    access_config {
      nat_ip = google_compute_address.ip_address_prod.address
    }
  }
}