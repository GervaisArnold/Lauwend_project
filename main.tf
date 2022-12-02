provider "aws" {
  region = "us-east-1"
}

variable "cidr_blocks" {
  description= "cidr blocks and name tags for vpc and subnet"
  type = list (object({
    cidr_block =string
    name =string}))
}
variable "availability_zone" {
  description = "availability_zone for dev_subnet"
  type = string 
  }
variable "my_ip" {}
variable "instance_type" {}
variable "key_name" {}
 
resource "aws_vpc" "dev_vpc" {
  cidr_block = var.cidr_blocks[0].cidr_block
  tags = {
    Name: var.cidr_blocks[0].name
  }
}

resource "aws_subnet" "dev_subnet" {
  vpc_id = aws_vpc.dev_vpc.id
  cidr_block = var.cidr_blocks[1].cidr_block
  availability_zone = var.availability_zone
   tags = {
    Name: var.cidr_blocks[1].name
 }
}

resource "aws_internet_gateway" "newapp_igw" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    "name" = "newapp_igw"
  }
  
}

resource "aws_route_table" "newapp_route_table" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.newapp_igw.id
  } 
    tags = {
    Name = "newapp_rtb"
  }
}

resource "aws_route_table_association" "a_rtb_subnet" {
  subnet_id = aws_subnet.dev_subnet.id
  route_table_id = aws_route_table.newapp_route_table.id
  
}

resource "aws_security_group" "newapp_sg" {
  name        = "newapp_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]

  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "dev_sg"
  }
}

resource "aws_instance" "newapp_server" {
  ami = "ami-0b0dcb5067f052a63"
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.newapp_sg.id]
  subnet_id = aws_subnet.dev_subnet.id
  availability_zone = var.availability_zone

  associate_public_ip_address = true 
  key_name = var.key_name

user_data = file ("entry-script.sh")
  tags = {
    "Name" = "newapp_server"
  }
}