# 1. 建立 S3 儲存桶
resource "aws_s3_bucket" "receipts_bucket" {
  bucket = var.bucket_name
}

# 2. 設定 S3 事件通知 (我們的觸發器)
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.receipts_bucket.id

  # 設定當有新物件建立時，要去觸發我們的 Lambda
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_discord_notifier.arn
    events              = ["s3:ObjectCreated:*"] # 對應到 "All object create events"
  }

  # 確保 Lambda 權限先建立好，再建立這個通知
  depends_on = [aws_lambda_permission.allow_s3]
}
