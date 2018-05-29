variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west3"
}

variable zone {
  description = "Zone"
  default     = "europe-west3-c"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
  default     = "~/.ssh/id_rsa.pub"
}

variable disk_image {
  description = "Disk image"
  default     = "centos-7"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
  default     = "~/.ssh/id_rsa"
}

variable user {
  description = "Name user"
  default     = "gitlab-runner"
}

variable postgres_password {
  description = "Passwored for Postgres"
  default     = "postgres"
}

variable version_app {
  description = "Version tag of app"
  default     = "0.0.0"
}

variable elk_host {
  description = "Host server logs"
  default     = "localhost"
}

variable environment {
  description = "Select test or prod"
  default     = "test"
}

variable project_dump {
  description = "ID project with dump"
}
