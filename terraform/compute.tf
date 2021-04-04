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

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A FIREWALL RULE TO ALLOW TRAFFIC FROM ALL ADDRESSES
# ---------------------------------------------------------------------------------------------------------------------

resource "google_compute_firewall" "firewall" {
  project = var.project_name
  name    = "${var.name}-fw"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  # These IP ranges are required for health checks
  source_ranges = ["0.0.0.0/0"]

  # Target tags define the instances to which the rule applies
  target_tags = [var.name]
}

# ------------------------------------------------------------------------------
# CREATE THE INTERNAL TCP LOAD BALANCER
# ------------------------------------------------------------------------------

module "lb" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "github.com/gruntwork-io/terraform-google-load-balancer.git//modules/network-load-balancer?ref=v0.2.0"
  source = "github.com/gruntwork-io/terraform-google-load-balancer.git/modules/network-load-balancer"

  name    = var.name
  region  = var.region
  project = var.project_name

  enable_health_check = true
  health_check_port   = "5000"
  health_check_path   = "/vm_instance2"

  firewall_target_tags = [var.name]

  instances = [google_compute_instance.vm_instance2.self_link]

  custom_labels = var.custom_labels
}
