terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  required_version = ">= 0.13"
}

provider "aws" {
    profile = "awsplaypen"
    region = "ap-southeast-2"
}

resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      Name = "production"
      Owner = "harzIlu"
    }
}

resource "aws_internet_gateway" "prod-gw" {
    vpc_id = aws_vpc.prod-vpc.id

    tags = {
      Name = "production"
      Owner = "harzIlu"
    }
}

resource "aws_route_table" "prod-route-table" {
    vpc_id = aws_vpc.prod-vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.prod-gw.id
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.prod-gw.id
    }

    tags = {
        Name = "production"
        Owner = "harzIlu"
    }
}

resource "aws_subnet" "prod-subnet" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-southeast-2a"

    tags = {
      Name = "production"
      Owner = "harzIlu"
    }
}

resource "aws_route_table_association" "prod-route-table-association" {
    subnet_id = aws_subnet.prod-subnet.id
    route_table_id = aws_route_table.prod-route-table.id
}

resource "aws_security_group" "prod-security-group" {
    name = "Allow HTTP, HTTPs and SSH"
    description = "Allow Internet Secure and Unsecure. Also allow SSH Access"
    vpc_id = aws_vpc.prod-vpc.id

    ingress {
      description = "HTTPs"
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
    }

    ingress {
      description = "HTTP"
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
    }

    ingress {
      description = "SSH"
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    tags = {
      Name = "production"
      Owner = "harzIlu"
    }
}

resource "aws_network_interface" "prod-network-interface" {
    subnet_id = aws_subnet.prod-subnet.id
    private_ips = [ "10.0.1.50" ]
    security_groups = [ aws_security_group.prod-security-group.id ]

    tags = {
      Name = "production"
      Owner = "harzIlu"
    }
}

resource "aws_eip" "prod-elastic-ip" {
    vpc = true
    network_interface = aws_network_interface.prod-network-interface.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [ aws_internet_gateway.prod-gw ]

    tags = {
      Name = "production"
      Owner = "harzIlu"
    }
}

resource "aws_instance" "harz_learn_terra" {
    ami = "ami-0b55fc9b052b03618"
    instance_type = "t2.micro"
    availability_zone = "ap-southeast-2a"
    key_name = "tmp_key_to_learn_stored_in_secret_manager_rsa_pem_file"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.prod-network-interface.id
    }

    user_data = <<-EOF
                sudo yum update -y
                sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
                sudo yum install -y httpd mariadb-server
                sudo systemctl start httpd
                sudo systemctl enable httpd
                sudo systemctl is-enabled httpd
                sudo usermod -a -G apache ec2-user
                source groups
                sudo chown -R ec2-user:apache /var/www
                sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
                sudo find /var/www -type f -exec sudo chmod 0664 {} \;
                EOF

    tags = {
        Name = "production"
        Owner = "harzIlu"
    }
}