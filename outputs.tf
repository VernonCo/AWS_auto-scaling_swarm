
output "allow_local_ip" {
  value = var.allow_local_ip
}
output "allowed_ip" {
  value = local.allowed_ip
}

output "has_associated_ip"{
  value = var.has_eip_id
}
output "if_associated_ip" {
  value = "change commented lines on output.tf or use the associated eip in the urls given"
}

output "swarm_master_ssh" {
  value = format("ssh -i %s.pem ec2-user@%s", var.aws_key_name, aws_instance.first_swarm_master.public_ip)
}

output "swarmpit_url_without_assoc_eip" {
  value = format("http://%s:8080", aws_instance.first_swarm_master.public_ip)
}

output "portainer_url_without_assoc_eip" {
  value = format("http://%s:9000", aws_instance.first_swarm_master.public_ip)
}


# output "swarm_master_ssh_with_assoc_eip" {
#   value = format("ssh -i %s.pem ec2-user@%s", var.aws_key_name, aws_eip_association.swarm-master[0].public_ip)
# }

# output "swarmpit_url_with_assoc_eip" {
#   value = format("http://%s:8080",aws_eip_association.swarm-master[0].public_ip)
# }

# output "portainer_url_with_assoc_eip" {
#   value = format("http://%s:9000",aws_eip_association.swarm-master[0].public_ip)
# }


output "alb_dns" {
  value = aws_alb.project.dns_name
}
