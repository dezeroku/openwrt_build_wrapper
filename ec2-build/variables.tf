variable "ssh_pub_key_path" {
  default = "~/.ssh/id_ed25519.pub"
}

variable "ssh_priv_key_path" {
  default = "~/.ssh/id_ed25519"
}

variable "instance_type" {
  # 64 G RAM
  # 32 vCPUs
  # This builds mainrouter from scratch in about 20 minutes
  #default = "c6gd.8xlarge"
  default = "c6a.8xlarge"
}

# You want this variable to match the arch of instance_type
variable "architecture" {
  default = "x86_64"
  #default = "arm64"
}

# Look at https://instances.vantage.sh/aws/ec2/c6a.8xlarge?region=us-east-2&os=linux&cost_duration=hourly&reserved_term=Standard.noUpfront
# to find the cheapest region for spot scheduling
variable "aws_region" {
  #default = "eu-north-1"
  default = "us-east-2"
}

variable "spot_price" {
  default = "0.60"
}
