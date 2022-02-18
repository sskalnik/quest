provider "aws" {
  region  = "us-west-2"
  shared_config_files      = ["/home/sskalnik/.aws/config"]
  shared_credentials_files = ["/home/sskalnik/.aws/credentials"]
  profile = "tf"
}
