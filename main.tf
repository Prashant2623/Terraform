# security credentials
provider "aws"{
region = "us-east-1"
}

# variables declaration
variable  vpc_cidr_block {}
variable  subnet_cidr_block {}
variable  avail_zone {}  
variable  env_prefix {}
variable instance_type {}
variable my_ip {}
variable my_public_key {}

# VPC
resource "aws_vpc" "myapp-vpc" {
  cidr_block =  var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

# SUBNET 
resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

# ROUTE TABLE AND INTERNET GATEWAY
resource "aws_default_route_table" "main-rtb" {
  default_route_table_id =  aws_vpc.myapp-vpc.default_route_table_id
   route {
     cidr_block = "0.0.0.0/0" 
     gateway_id = aws_internet_gateway.myapp-igw.id
   }
   tags = {
      Name: "${var.env_prefix}-main-rtb"
   }
}
resource "aws_internet_gateway" "myapp-igw" {
   vpc_id = aws_vpc.myapp-vpc.id
   tags = {
      Name: "${var.env_prefix}-igw"
   }
}

# SECURITY GROUP
resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id  #to reference, use the vpc

ingress {                                      #incoming traffic rule
  from_port = 22             
  to_port = 22
  protocol = "tcp"
  cidr_blocks = [var.my_ip]
}
ingress {                                      #incoming traffic rule
  from_port = 8080                
  to_port = 8080
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]          
 }
egress {                                      #outgoing traffic rule
  from_port = 0                
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]            
  prefix_list_ids = [var.my_ip]
 }
 tags = {
      Name: "${var.env_prefix}-sg"
   }  
}

# EC2 INSTANCE
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["137112412989"]
  filter {
    name   = "name"
    values = ["Amazon Linux 2 AMI-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "ssh-key" {
key_name = "server-key"
public key = "var.my_public_key"
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true   # access the server from the browser
  key_name =  aws_key_pair.ssh-key.key_name  
  user_data = file("entry-script.sh")
tags = {
      Name: "${var.env_prefix}-server"
   }   
}


