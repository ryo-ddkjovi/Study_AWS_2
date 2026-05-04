variable "db_user" {
  description = "RDS MySQLのユーザー名"
  type        = string
}

variable "db_pass" {
  description = "RDS MySQLのパスワード"
  type        = string
  sensitive   = true
}

variable "my_ip" {
  description = "踏み台サーバへのSSHを許可する自分のグローバルIP。例: 203.0.113.10/32"
  type        = string
}