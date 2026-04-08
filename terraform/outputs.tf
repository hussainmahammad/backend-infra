output "account_a" {
  value = {
    vpc_id        = aws_vpc.a_vpc.id
    subnet_id     = aws_subnet.a_pub.id
    jenkins_sg_id = aws_security_group.jenkins_master_sg.id
    jenkins_instance_id = aws_instance.jenkins_master.id
    jenkins_public_ip = aws_instance.jenkins_master.public_ip
  }
}

output "account_b" {
  value = {
    vpc_id        = aws_vpc.b_vpc.id
    subnet_id     = aws_subnet.b_pub.id
    agent_sg_id   = aws_security_group.jenkins_agent_sg.id
    agent_instance_id = aws_instance.build_node.id
    agent_public_ip = aws_instance.build_node.public_ip
  }
}

output "account_c" {
  value = {
    vpc_id    = aws_vpc.c_vpc.id
    subnet_id = aws_subnet.c_pub.id
  }
}

output "peering" {
  value = {
    a_b = aws_vpc_peering_connection.a_b.id
    b_c = aws_vpc_peering_connection.b_c.id
    a_c = aws_vpc_peering_connection.a_c.id
  }
}
