variable "db_user" {
  description = "RDS MySQLのユーザー名"
  type        = string
}

variable "db_pass" {
  description = "RDS MySQLのパスワード"
  type        = string
  sensitive   = true
}