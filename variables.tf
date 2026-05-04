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
  description = "踏み台サーバへのSSHを許可する自分のグローバルIP"
  type        = string
}

variable "restore_db_endpoint" {
  description = "復元DBに切り替えるときのエンドポイント（通常は空）"
  type        = string
  default     = ""
}