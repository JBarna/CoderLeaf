terraform {
  required_providers {
    pgp = {
      source = "ekristen/pgp"
      version = "0.2.4"
    }
  }
}

provider "pgp" {}

