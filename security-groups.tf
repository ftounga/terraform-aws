resource "aws_security_group" "lb-sg" {
  provider    = aws.region-master
  name        = "lb-sg"
  description = "Allow 443 and traffic to jenkins SG"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    description = "Allow 443 from anywhere"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    description = "Allow 80 from anywhere"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins-sg" {
  provider    = aws.region-master
  name        = "jenkins-sg"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    description = "Allow 22 from our public IP"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    from_port       = var.webserver-port
    protocol        = "tcp"
    to_port         = var.webserver-port
    description     = "Allow anyone on port 8080"
    security_groups = [aws_security_group.lb-sg.id]
  }
  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    description = "Allow traffic from eu west 2"
    cidr_blocks = ["192.168.1.0/24"]
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins-sg-worker" {
  provider    = aws.region-worker
  name        = "jenkins-sg-worker"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.vpc_worker.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "Allow traffic from eu-west-3"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["10.0.1.0/24"]
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

