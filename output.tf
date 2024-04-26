output "instance_id" {
  value = aws_instance.servers.*.id
}
output "public_ip" {
  value = aws_instance.servers.*.public_ip
}
output "load_balancer_dns_name" {
  value = "http://${aws_lb.web.dns_name}"
}
