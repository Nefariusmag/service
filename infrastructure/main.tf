provider "google" {
  version     = "1.4.0"
  credentials = "${file("docker.json")}"
  project     = "${var.project}"
  region      = "${var.region}"
}

resource "google_compute_firewall" "firewall_bot_infrastructure" {
  name = "allow-bot-infrastructure"

  # Название сети, в которой действует правило
  network = "default"

  # Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  allow {
    protocol = "tcp"
    ports    = ["9200"]
  }
  allow {
    protocol = "tcp"
    ports    = ["5044"]
  }
  allow {
    protocol = "tcp"
    ports    = ["5601"]
  }
  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }
  allow {
    protocol = "tcp"
    ports    = ["9093"]
  }
  allow {
    protocol = "tcp"
    ports    = ["9087"]
  }
  allow {
    protocol = "tcp"
    ports    = ["9187"]
  }
  # Каким адресам разрешаем доступ
  source_ranges = ["0.0.0.0/0"]

  # Правило применимо для инстансов с тегом ...
  target_tags = ["bot-infrastructure"]
}

resource "google_compute_instance" "infrastructure" {
  # создаем два экземпляра
  count = 1

  # обозначиваем в имени индекс
  name         = "bot-infrastructure"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["bot-infrastructure"]

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
      size  = "${var.disk_size}"
    }
  }

  # определение сетевого интерфейса
  network_interface {
    # сеть, к которой присоединить данный интерфейс
    network = "default"

    # использовать ephemeral IP для доступа из Интернет
    access_config {}
  }

  connection {
    type        = "ssh"
    user        = "${var.user}"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  # Centos7
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y yum-utils device-mapper-persistent-data lvm2",
      "sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo",
      "sudo yum install -y docker-ce",
      "sudo systemctl start docker",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo ln -s /usr/local/bin/docker-compose /usr/bin/",
    ]
  }

  provisioner "local-exec" {
    command = "echo \"GITLAB_URL=${google_compute_instance.infrastructure.0.network_interface.0.access_config.0.assigned_nat_ip}\" > env"
  }

  provisioner "file" {
    source      = "./"
    destination = "/tmp/"
  }

# настройка гитлаба и логирования
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/docker-compose.yml /opt/docker-compose.yml",
      "sudo mv /tmp/env /opt/.env",
      "sudo mv /tmp/register-gitlab-runner.sh /opt/register-gitlab-runner.sh",
      "sudo chmod +x /opt/register-gitlab-runner.sh",
      "sudo mv /tmp/logstash/ /opt/",
      "sudo mkdir -p /opt/gitlab/data",
      "sudo mkdir -p /opt/gitlab/logs",
      "sudo mkdir -p /opt/gitlab/config",
      "sudo mkdir -p /opt/elasticsearch/data",
      "cd /opt",
      "sudo yum install -y unzip wget",
      "sudo wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip -O /opt/terraform_0.11.7_linux_amd64.zip",
      "sudo unzip terraform_0.11.7_linux_amd64.zip",
      "sudo docker-compose up -d",
    ]
  }

# настройка мониторинга
  provisioner "remote-exec" {
    inline = [
      "sudo sed -i \"s|DEVELOPER_ID|${var.developer_id}|\" /tmp/monitoring/alertmanager/config.yml",
      "sudo sed -i \"s|TOKEN|${var.token}|\" /tmp/monitoring/prometheus_bot/config.yaml",
      "sudo mkdir -p /tmp/monitoring/grafana/",
      "sudo mv /tmp/monitoring /opt/",
      "sudo mv /tmp/docker-compose-monitoring.yml /opt/docker-compose-monitoring.yml",
      "sudo mv /tmp/add_prod_to_monitoring.sh /opt/add_prod_to_monitoring.sh",
      "sudo chmod +x /opt/add_prod_to_monitoring.sh"
    ]
  }

  provisioner "local-exec" {
    command = "rm -rf env"
  }

}
