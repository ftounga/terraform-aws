output "jenkins-master-node-public-ip" {
  value = aws_instance.jenkins-master.public_ip
}

output "jenkins-worker-node-public-ip" {
  value = aws_instance.jenkins-worker[*].public_ip
}

output "LB-DNS-NAME" {
  value = aws_lb.application-lb.dns_name
}
