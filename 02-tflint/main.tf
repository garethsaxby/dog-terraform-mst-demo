provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}


resource "aws_instance" "aws-instance" {
  ami = data.aws_ami.ubuntu.id

  # tflint will capture that the instance type is invalid and return an error
  # Would not be caught by `terraform validate`
  # Change to t2.micro to pass
  instance_type = "t2.miiicro"
}