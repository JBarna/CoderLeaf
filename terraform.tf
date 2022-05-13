terraform {
  required_providers {
    pgp = {
      source = "ekristen/pgp"
      version = "0.2.4"
    }

    aws = {
      source  = "hashicorp/aws"
      configuration_aliases = [ aws.ses ]
    }
  }
}