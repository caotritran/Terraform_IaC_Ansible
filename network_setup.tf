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
