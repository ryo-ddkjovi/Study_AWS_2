output "alb_dns" {
  description = "ALBのDNS名"
  value       = aws_lb.alb.dns_name
}

output "alb_url" {
  description = "ALBでアクセスするURL"
  value       = "http://${aws_lb.alb.dns_name}"
}

output "cloudfront_domain" {
  description = "CloudFrontのドメイン"
  value       = aws_cloudfront_distribution.wordpress.domain_name
}

output "cloudfront_url" {
  description = "WordPressのURL（これを使う）"
  value       = "https://${aws_cloudfront_distribution.wordpress.domain_name}"
}

output "rds_endpoint" {
  description = "元のRDSのエンドポイント"
  value       = aws_db_instance.mysql.address
}

output "bastion_public_ip" {
  description = "踏み台サーバのIP"
  value       = aws_instance.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "SSH接続コマンド"
  value       = "ssh -i bastion-key.pem ubuntu@${aws_instance.bastion.public_ip}"
}

output "rds_mysql_command" {
  description = "RDS接続コマンド"
  value       = "mysql -h ${aws_db_instance.mysql.address} -u ${var.db_user} -p"
}