terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

variable "project_id" {
  type = string
  default = "us-central1"
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

resource "google_storage_bucket" "lab" {
  name                        = "${var.project_id}-ace-tf-2026"
  location                    = "US"
  uniform_bucket_level_access = true
  force_destroy               = true

  labels = {
    managed_by = "terraform"
  }
}
