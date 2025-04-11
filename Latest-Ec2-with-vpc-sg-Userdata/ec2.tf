provider "aws" {
    region = "ap-south-1"
    

  
}
data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

}

resource "aws_vpc" "Public" {
    cidr_block = "10.0.0.0/16"
    
  tags = {
    Name = "Public-VPC"
  }
}
resource "aws_subnet" "Publick-Subnet" {
    vpc_id = aws_vpc.Public.id
    cidr_block = "10.0.0.0/24"
    tags = {
      Name = "Public-Subnet"
    }
  
}

resource "aws_instance" "app-server" {
    ami = data.aws_ami.amazon-linux.id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.Publick-Subnet.id
    associate_public_ip_address = true  
    user_data = file("${path.module}/app1-install.sh")
    vpc_security_group_ids = [aws_security_group.allow.id]
    tags = {
      name = "AppServer"
    }
      
}
resource "aws_security_group" "allow" {
    name = "Allow HTTP"
    vpc_id = aws_vpc.Public.id
}
/*
    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
      Name = "Allow HTTP"
    }  
}
*/

resource "aws_vpc_security_group_ingress_rule" "http-Allow" {
  security_group_id = aws_security_group.allow.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  
}

resource "aws_internet_gateway" "Public-IGW" {
  vpc_id = aws_vpc.Public.id
}


resource "aws_route_table" "Public-Table" {
  vpc_id = aws_vpc.Public.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Public-IGW.id
  }

  
}
resource "aws_route_table_association" "name" {
  subnet_id = aws_subnet.Publick-Subnet.id
  route_table_id = aws_route_table.Public-Table.id
}
output "Public-IP" {
    value = aws_instance.app-server.public_ip
  
}
output "SG-ID" {
    value = aws_security_group.allow.id
  
}