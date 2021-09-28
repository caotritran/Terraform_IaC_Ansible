#create vpc in us-east-1
resource "aws_vpc" "vpc_master" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master-vpc-jenkins"
  }
}

#create vpc in us-west-2
resource "aws_vpc" "vpc_worker_oregon" {
  provider             = aws.region-worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins"
  }
}

#creat internet gateway in us-east-1
resource "aws_internet_gateway" "igw" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id

  tags = {
    Name = "igw-master"
  }
}

#creat IGW in us-west-2
resource "aws_internet_gateway" "igw-oregon" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker_oregon.id

  tags = {
    Name = "igw-oregon"
  }
}

# Declare the data source
data "aws_availability_zones" "azs" {
  state    = "available"
  provider = aws.region-master
}

#create subnet # 1 in us-east-1
resource "aws_subnet" "subnet-1" {
  provider          = aws.region-master
  vpc_id            = aws_vpc.vpc_master.id
  availability_zone = data.aws_availability_zones.azs.names[0]
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "subnet-1"
  }
}

#create subnet # 2 in us-east-1
resource "aws_subnet" "subnet-2" {
  provider          = aws.region-master
  vpc_id            = aws_vpc.vpc_master.id
  availability_zone = data.aws_availability_zones.azs.names[1]
  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = "subnet-2"
  }
}

#create subnet # 1 in us-west-2
resource "aws_subnet" "subnet-1-oregon" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_worker_oregon.id
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "subnet-1-oregon"
  }
}

#create peering connection from us-east-1 to us-west-2
resource "aws_vpc_peering_connection" "useast1-uswest2" {
  provider    = aws.region-master
  peer_vpc_id = aws_vpc.vpc_worker_oregon.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.region-worker
  tags = {
    Name = "VPC-peering-useast1-uswest2"
  }
}

#create accept connection from us-east-1 to us-west-2
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  auto_accept               = true
}

#create route table in us-east-1
resource "aws_route_table" "internet_route" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  }

  tags = {
    Name = "Master-Region-RT"
  }
}


#create table associate in us-east-1
resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  provider       = aws.region-master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route.id
}

#create route table in us-west-2
resource "aws_route_table" "internet_route_oregon" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker_oregon.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-oregon.id
  }
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  }

  tags = {
    Name = "Worker-Region-RT"
  }
}


#create table associate in us-east-1
resource "aws_main_route_table_association" "set-worker-default-rt-assoc" {
  provider       = aws.region-worker
  vpc_id         = aws_vpc.vpc_worker_oregon.id
  route_table_id = aws_route_table.internet_route_oregon.id
}

#create SG for LB, only allow 80 and 443 and outbound access
resource "aws_security_group" "lb-sg" {
  provider    = aws.region-master
  name        = "lg-sg"
  description = "Allow port HTTP and HTTPS to jenkins"
  vpc_id      = aws_vpc.vpc_master.id

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http_https"
  }
}

#create SG for jenkins master, allow 8080 from ALB and allow all to jenkins worker
resource "aws_security_group" "sg-jenkins-master" {
  provider    = aws.region-master
  name        = "allow_traffic_jenkins_master"
  description = "Allow 8080 and peering"
  vpc_id      = aws_vpc.vpc_master.id

  ingress {
    description     = "allow port 8080"
    from_port       = var.webserver-port
    to_port         = var.webserver-port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb-sg.id]
  }
  ingress {
    description = "allow port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "allow traffic from us-west-2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_traffic_jenkins_master"
  }
}

#create SG for jenkins worker, allow traffice from jenkins master and port 22
resource "aws_security_group" "sg-jenkins-worker" {
  provider    = aws.region-worker
  name        = "allow_traffic_jenkins_worker"
  description = "Allow traffic from jenkins master"
  vpc_id      = aws_vpc.vpc_worker_oregon.id

  ingress {
    description = "Allow traffic from jenkins master"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }
  ingress {
    description = "allow port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_traffic_jenkins_worker"
  }
}