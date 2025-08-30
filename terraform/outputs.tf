
output "alb_dns_name" {
  description = "ALB DNS name (use this to hit the site)."
  value       = aws_lb.app.dns_name
}