terraform {
  required_providers {
    pgp = {
      source = "ekristen/pgp"
      version = "0.2.4"
    }

    aws = {
      source  = "hashicorp/aws"
    }

    time = {
      source = "hashicorp/time"
      version = "0.7.2"
    }
  }

  experiments = [module_variable_optional_attrs]
}