# security credentials
provider "aws"{}
# variables declaration
variable  vpc_cidr_block {}
variable  subnet_cidr_block {}
variable  avail_zone {}  
variable  env_prefix {}
variable my_ip {}
variable instance_type {}
# step 1 : create VPC
resource "aws_vpc" "myapp-vpc" {
  cidr_block =  var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}
# step 2 : create custom subnet 
resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}
# step 3 : using the default route table & the internet gateway
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

# step 4 : creating security group  and then using defaul security group
resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id  #to reference, use the vpc

ingress {                                      #incoming traffic rule
  from_port = 22               #range of port is also available 
  to_port = 22
  protocol = "tcp"
  cidr_blocks = [var.my_ip]
}
ingress {                                      #incoming traffic rule
  from_port = 8080               #range of port is also available 
  to_port = 8080
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]            # can be accessed from anywhere
 }
egress {                                      #outgoing traffic rule
  from_port = 0                
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]            
  prefix_list_ids = []
 }
 tags = {
      Name: "${var.env_prefix}-sg"
   }  
}
#step5 : provision EC2 instance
resource "aws_instance" "myapp-server" {
ami = "ami-0c4f7023847b90238"
instance_type = var.instance_type
subnet_id = aws_subnet.myapp-subnet-1.id
vpc_security_group_ids = [aws_default_security_group.default-sg.id] 
availability_zone = var.avail_zone
associate_public_ip_address = true 
key_name = "server-key-pair"
user_data = <<EOF
            #!/bin/bash
            sudo apt-get update -y && sudo apt install docker-ce
            sudo systemctl start docker
            sudo usermod aG docker ec2-user
            docker run -p 8080:80 nginx
            EOF  
tags = {
      Name: "${var.env_prefix}-server"
   }   
}

