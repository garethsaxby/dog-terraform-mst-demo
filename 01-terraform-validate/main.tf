provider "aws" {
  region = "us-west-2"
}

# data "aws_ami" "ubuntu" {
#     most_recent = true
#   filter {
#       name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
#   }
#   filter {
#       name   = "virtualization-type"
#     values = ["hvm"]
#   }
#   owners = ["099720109477"] # Canonical
# }

resource "aws_instance" "aws_instance" {
  # This should fail to validate as the AMI resource is commented out
  # To work, the aws_ami data object above should be uncommented
  ami = data.aws_ami.ubuntu.id

  # This should fail as the instance_type is not defined
  # To work, the line below should be uncommented
  # instance_type = "t2.micro"
}
