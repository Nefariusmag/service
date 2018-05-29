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

variable disk_size {
  description = "Disk size"
  default     = "70"
}

variable machine_type {
  description = "Machine type for CPU and RAM"
  default     = "n1-standard-2"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
  default     = "~/.ssh/id_rsa"
}

variable user {
  description = "Name user"
}

variable developer_id {
  description = "ID developer"
}

variable token {
  description = "Token of telegram bot"
}
