#get AMI id using SSM parameter in us-east-1
data "aws_ssm_parameter" "linuxAmi" {
  provider = aws.region-master
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#get AMI id using SSM parameter in us-west-2
data "aws_ssm_parameter" "linuxAmiOregon" {
  provider = aws.region-worker
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#create key pair in us-east-1
resource "aws_key_pair" "master-key" {
  provider = aws.region-master
  key_name   = "jenkins"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiNdgoKnX13LipucnX1jXk/YFvmtgTlHmDGqvJZ9Pfv+EIKt3LlCdYIMSle6+QgGK1QcmNLqSUaACIsRvUAWUBC+yS5mY3GiC6p9I/GAdNdg5omVtA0dabsgcbQixnrSQqxvq+WgtmEMBXmeKM8fmIZ4nyRH2VD49r/iC+Bnc9b7uDafnff37wZi6bqG55wVWOLA88mZvqYAzcq5ccd1wV014zTVCeEY1tEgM4u+jYw1W/fc0U2gxViaJ0fPFrBxdKUXPUgNi6VTZbDb0C0cE4GVAstOl5jBsqBvdnQykHpOjqfON2KV2g2WBdQRaM2OWOoJVOaEhZzy8Z2rLI+W55"
}

#create key pair in us-west-2
resource "aws_key_pair" "worker-key" {
  provider = aws.region-worker
  key_name   = "jenkins"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiNdgoKnX13LipucnX1jXk/YFvmtgTlHmDGqvJZ9Pfv+EIKt3LlCdYIMSle6+QgGK1QcmNLqSUaACIsRvUAWUBC+yS5mY3GiC6p9I/GAdNdg5omVtA0dabsgcbQixnrSQqxvq+WgtmEMBXmeKM8fmIZ4nyRH2VD49r/iC+Bnc9b7uDafnff37wZi6bqG55wVWOLA88mZvqYAzcq5ccd1wV014zTVCeEY1tEgM4u+jYw1W/fc0U2gxViaJ0fPFrBxdKUXPUgNi6VTZbDb0C0cE4GVAstOl5jBsqBvdnQykHpOjqfON2KV2g2WBdQRaM2OWOoJVOaEhZzy8Z2rLI+W55"
}

#Create and bootstrap EC2 in us-east-1
resource "aws_instance" "jenkins-master" {
	provider = aws.region-master
	ami = data.aws_ssm_parameter.linuxAmi.value
	instance_type = var.instance_type
	key_name = aws_key_pair.master-key.key_name
	associate_public_ip_address = true
	vpc_security_group_ids = [aws_security_group.sg-jenkins-master.id]
	subnet_id = aws_subnet.subnet-1.id

	tags = {
      Name = "jenkins_master_tf"
    }
    depends_on = [aws_main_route_table_association.set-master-default-rt-assoc]
}

#Create and bootstrap EC2 in us-west-2
resource "aws_instance" "jenkins-worker-oregon" {
	provider = aws.region-worker
	ami = data.aws_ssm_parameter.linuxAmiOregon.value
	instance_type = var.instance_type
	key_name = aws_key_pair.worker-key.key_name
	associate_public_ip_address = true
	vpc_security_group_ids = [aws_security_group.sg-jenkins-worker.id]
	subnet_id = aws_subnet.subnet-1-oregon.id
	count = var.workers-count

	tags = {
      Name = join("_", ["jenkins_worker_tf", count.index + 1])
    }
    depends_on = [aws_main_route_table_association.set-worker-default-rt-assoc, aws_instance.jenkins-master]
}
