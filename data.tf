data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default_subnet" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = var.az
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
