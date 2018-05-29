provider "google" {
  version     = "1.4.0"
  credentials = "${file("docker.json")}"
  project     = "${var.project}"
  region      = "${var.region}"
}

resource "google_compute_firewall" "firewall_bot_services" {
  name = "allow-bot-services-${var.environment}"

  # Название сети, в которой действует правило
  network = "default"

  # Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  allow {
    protocol = "tcp"
    ports    = ["9323"]
  }
  # Каким адресам разрешаем доступ
  source_ranges = ["0.0.0.0/0"]

  # Правило применимо для инстансов с тегом ...
  target_tags = ["bot-services"]
}

resource "google_compute_instance" "app" {
  # создаем экземпляры
  count = 1

  # обозначиваем в имени индекс
  # name         = "bot-services-${count.index}"
  name = "bot-services-${var.environment}"

  machine_type = "g1-small"
  zone         = "${var.zone}"
  tags         = ["bot-services"]

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
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
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
    ]
  }

  provisioner "file" {
    source      = "daemon.json"
    destination = "/tmp/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/daemon.json /etc/docker/daemon.json",
      "sudo systemctl restart docker",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo ln -s /usr/local/bin/docker-compose /usr/bin/",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir /tmp/bot_services/",
    ]
  }

  provisioner "local-exec" {
    command = "cp ../.env ../env"
  }

  provisioner "file" {
    source      = "../"
    destination = "/tmp/bot_services/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp -r /tmp/bot_services/* /opt/",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt",
      "sudo mv env .env",
      "sudo docker-compose up -d",
    ]
  }

  provisioner "local-exec" {
    command = "rm ../env"
  }

  # Centos7
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm",
      "sudo yum install -y postgresql10",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y wget",
      "cd /opt",
      "sudo wget https://storage.googleapis.com/${var.project_dump}.appspot.com/dump_scheme.sql.tar.gz",
      "sudo tar xzvf dump_scheme.sql.tar.gz",
      "sleep 60",
      "PGPASSWORD=${var.postgres_password} psql -h 127.0.0.1 -U postgres -f dump_scheme.sql",
    ]
  }

  # Centos7
  provisioner "remote-exec" {
    inline = [
      "cd /tmp",
      "sudo curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-5.5.3-x86_64.rpm",
      "sudo rpm -vi filebeat-5.5.3-x86_64.rpm",
      "sudo cp /tmp/bot_services/devops/filebeat.yml /etc/filebeat/filebeat.yml",
      "sudo sed -i \"s|ELK_HOST|${var.elk_host}|g\" /etc/filebeat/filebeat.yml",
      "sudo systemctl enable filebeat",
      "sudo systemctl restart filebeat",
    ]
  }
}
