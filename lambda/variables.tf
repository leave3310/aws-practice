# variables.tf

variable "bucket_name" {
  description = "The name for the S3 bucket. Must be globally unique."
  type        = string
  default     = "lambda-discord-bucket" # 請改成一個全域唯一的名稱
}

variable "discord_webhook_url" {
  description = "The Discord Webhook URL"
  type        = string
  sensitive   = true # 設定為 sensitive，這樣 Terraform 在 plan/apply 時不會直接顯示它
}