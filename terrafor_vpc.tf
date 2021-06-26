## Configuring a VPC and EC2 Through Terraform ##

provider "aws" {
    region = "ap-southeast-1"
}

resource "aws_vpc" "myvpc" {
    cidr_block       = "10.0.0.0/16"
    instance_tenancy = "default" 
    tags = {
        Name = "myvpc"
    }
}

resource "aws_subnet" "pubsub" {
    
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.1.0.0/24"
   tags = {
        Name = "pubsub"
    }   
}

resource "aws_subnet" "pvtsub" {

    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.1.0.0/24"
   tags = {
        Name = "pubsub"
    }   
}
resource "aws_internet_gateway" "mygway" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "pubrt" {
    vpc_id = aws_vpc.myvpc.id

    route {
       cider_block = "0.0.0.0/0"
       gateway_id = aws_internet_gateway.mygway.id
   }    
    tags = {
        Name = "pubrt"
    }
}

resource "aws_route_table_association" "pubassociation" {
    subnet_id = aws_subnet.pubsub.id
    route_table_id = aws_route_table.pubsub.id  
}

resource "aws_eip" "eip" {
    vpc = true 
}

resource "aws_nat_gateway" "tnat" {
    allocation_id = aws_eip.eip.id
    subnet_id = aws_subnet.pubsub.id 
}

resource "aws_route_table" "pvtrt" {
    vpc_id = aws_vpc.myvpc.id

    route {
       cider_block = "0.0.0.0/0"
       gateway_id = aws_internet_gateway.mygway.id
   }    
    tags = {
        Name = "pvt"
    }
}

resource "aws_route_table_association" "privateassociation" {
    subnet_id = aws_subnet.pvtsub.id
    route_table_id = aws_route_table.pvtrt.id
  
}

resource "aws_security_group" "callsecugp" {
    name = "callsecugp"
    description = "Allow TLS inbound traffic"
    vpc_id = aws_vpc.myvpc.id

    ingress {
        from_port = 22
        to_port   = 22
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port   = 80
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
} 

resource "aws_instance" "Publicec2" {
    ami = "ami-02f26adf094f51167"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.pubsub.id
    keyname = "ec2-webserv"
    vpc_security_group_ids = ["${aws_security_group.callsecugp.id}"]
    associate_public_ip_address = true
}

resource "aws_instance" "Pvtec2" {
    ami = "ami-02f26adf094f51167"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.pvtsub.id
    keyname   = "ec2-webserv"
    vpc_security_group_ids = ["${aws_security_group.callsecugp.id}"]
  
}









