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

resource "aws_instance" "jenkins-master" {
  provider                    = aws.region-master
  ami                         = data.aws_ssm_parameter.linuxAmi-master.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  subnet_id                   = aws_subnet.subnet_1_master.id

  tags = {
    Name = "jenkins_master_tf"
  }
  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-master} --instance-ids ${self.id}
ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/jenkins-master.yml
EOF
  }

  depends_on = [aws_main_route_table_association.set-master-default-rt-assoc]
}

resource "aws_instance" "jenkins-worker" {
  provider                    = aws.region-worker
  ami                         = data.aws_ssm_parameter.linuxAmi-worker.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.worker-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-sg-worker.id]
  subnet_id                   = aws_subnet.subnet_1_worker.id
  count                       = var.worker-count

  tags = {
    Name = join("_", ["jenkins_worker_tf", count.index + 1])
  }

  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-worker} --instance-ids ${self.id}
ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/jenkins-worker.yml
EOF
  }
  depends_on = [aws_main_route_table_association.set-worker-default-rt-assoc, aws_instance.jenkins-master]
}

