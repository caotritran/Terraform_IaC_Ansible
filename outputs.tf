output "Jenkin-main-node-public-ip" {
  value = aws_instance.jenkins-master.public_ip
}

output "Jenkin-worker-nodes-public-ip" {
  value = {
    for instance in aws_instance.jenkins-worker-oregon :
    instance.id => instance.public_ip
  }
}

output "dns-ALB" {
  value = aws_lb.application-lb.dns_name
}