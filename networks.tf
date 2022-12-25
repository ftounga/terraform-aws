#Create VPC
resource "aws_vpc" "vpc_master" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master-vpc-jenkins"
  }
}

resource "aws_vpc" "vpc_worker" {
  provider             = aws.region-worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins"
  }
}

resource "aws_internet_gateway" "igw_master" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
}

resource "aws_internet_gateway" "igw_worker" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker.id
}

data "aws_availability_zones" "azs" {
  provider = aws.region-master
  state    = "available"
}

resource "aws_subnet" "subnet_1_master" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "subnet_2_master" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.2.0/24"
}

resource "aws_subnet" "subnet_1_worker" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_worker.id
  cidr_block = "192.168.1.0/24"
}

resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id = aws_vpc.vpc_worker.id
  vpc_id      = aws_vpc.vpc_master.id
  provider    = aws.region-master
  peer_region = var.region-worker
}

resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true
}

resource "aws_route_table" "internet_route_master" {
  vpc_id   = aws_vpc.vpc_master.id
  provider = aws.region-master
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_master.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Master-Region-RT"
  }
}

resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  route_table_id = aws_route_table.internet_route_master.id
  vpc_id         = aws_vpc.vpc_master.id
  provider       = aws.region-master
}

resource "aws_route_table" "internet_route_worker" {
  vpc_id   = aws_vpc.vpc_worker.id
  provider = aws.region-worker
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_worker.id
  }
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Worker-Region-RT"
  }
}

resource "aws_main_route_table_association" "set-worker-default-rt-assoc" {
  route_table_id = aws_route_table.internet_route_worker.id
  vpc_id         = aws_vpc.vpc_worker.id
  provider       = aws.region-worker
}
