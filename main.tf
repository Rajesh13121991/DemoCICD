terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider for OHIO region
provider "aws" {
  region = "us-east-2"
  alias = "ohio"
}

# Configure the AWS Provider for N.VIRGINIA region
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "primary" {
  depends_on = [ aws_security_group.default ]
  ami             = "ami-0230bd60aa48260c6" 
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public-subnet-1.id
  security_groups = [aws_security_group.default.id]

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd.x86_64
  systemctl start httpd.service
  systemctl enable httpd.service
  echo “Hello World from Primary Server” > /var/www/html/index.html
  EOF

  tags = {
    Name = "Primary_Server"
  }
}

////// SECONDARY SERVER //////

resource "aws_instance" "secondary" {
    provider = aws.ohio
  ami             = "ami-06d4b7182ac3480fa" 
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.secondary.name]

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd.x86_64
  systemctl start httpd.service
  systemctl enable httpd.service
  echo “Hello World from Secondary Server” > /var/www/html/index.html
  EOF

  tags = {
    Name = "Secondary_Server"
  }
}

data "aws_vpc" "secondary" {
    provider = aws.ohio
  default = true
} 

resource "aws_security_group" "secondary" {
    provider = aws.ohio
  name        = "secondary_allow_ssh_http"
  description = "Allow ssh http inbound traffic"
  vpc_id      = data.aws_vpc.secondary.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

    ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "secondary_allow_ssh_http"
  }
}
