output "url" {
  value       = "http://${aws_elb.web_clb.dns_name}"
  description = "Address of the loadbalancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.web_asg.name
  description = "The name of the Auto Scaling Group"
}
