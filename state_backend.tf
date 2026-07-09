terraform {
  backend "s3" {
    bucket = "elden-state-bucket"
    key    = "remote-state-lab/terraform.tfstate"
    region = "ap-southeast-1"
    
  }
}
