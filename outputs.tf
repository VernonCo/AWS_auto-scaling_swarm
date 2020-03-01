

output "swarm_master" {
  value = aws_eip.swarm-master.public_ip
}

output "service_url" {
  value = format("http://%s",aws_eip.swarm-master.public_ip)
}

output "swarmpit_url" {
  value = format("http://%s:8080",aws_eip.swarm-master.public_ip)
}

output "portainer_url" {
  value = format("http://%s:9000",aws_eip.swarm-master.public_ip)
}

output "rte_53_lb_alias" {
  value = aws_alb.project.zone_id
}

output "alb_dns" {
  value = aws_alb.project.name
}
