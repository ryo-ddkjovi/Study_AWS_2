output "alb_dns" {
  description = "ALBのDNS名。CloudFrontを使わずALBで直接確認したい場合に使う。"
  value       = aws_lb.alb.dns_name
}

output "alb_url" {
  description = "ALBで直接WordPressを確認するURL"
  value       = "http://${aws_lb.alb.dns_name}"
}

output "cloudfront_domain" {
  description = "CloudFrontのドメイン名"
  value       = aws_cloudfront_distribution.wordpress.domain_name
}

output "cloudfront_url" {
  description = "ブラウザで開く本命のWordPress URL"
  value       = "https://${aws_cloudfront_distribution.wordpress.domain_name}"
}

output "rds_endpoint" {
  description = "WordPressが接続するRDS MySQLのエンドポイント。ブラウザで開くものではない。"
  value       = aws_db_instance.mysql.address
}

output "bastion_public_ip" {
  description = "踏み台サーバのパブリックIP"
  value       = aws_instance.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "踏み台サーバへSSH接続するコマンド"
  value       = "ssh -i bastion-key.pem ubuntu@${aws_instance.bastion.public_ip}"
}

output "rds_mysql_command" {
  description = "踏み台サーバ内でRDSへ接続するコマンド"
  value       = "mysql -h ${aws_db_instance.mysql.address} -u ${var.db_user} -p"
}