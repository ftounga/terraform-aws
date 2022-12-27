data "aws_ssm_parameter" "linuxAmi-master" {
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
  provider = aws.region-master
}

data "aws_ssm_parameter" "linuxAmi-worker" {
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
  provider = aws.region-worker
}

resource "aws_key_pair" "master-key" {
  public_key = file("~/.ssh/id_rsa.pub")
  key_name   = "jenkins"
  provider   = aws.region-master
}

resource "aws_key_pair" "worker-key" {
  public_key = file("~/.ssh/id_rsa.pub")
  key_name   = "jenkins"
  provider   = aws.region-worker
}


