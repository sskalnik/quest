terraform {
  required_version = "~> 1.0"

  required_providers {
    # AWS provider version 4.0 was released 3 days ago; hope this doesn't bite me, but YOLO lol XD
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}

