data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/index.mjs"
  output_path = "${path.module}/function.zip"
}

resource "aws_lambda_function" "s3_discord_notifier" {
  function_name = "s3-discord-notifier"
  role          = aws_iam_role.lambda_exec_role.arn

  # 指向我們用 data block 產生的 zip 檔
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # 對應到我們選擇的 Runtime 和 handler
  handler = "index.handler"
  runtime = "nodejs20.x"

  # 設定環境變數
  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }
}

# 3. 建立一個權限，允許 S3 服務可以呼叫我們的 Lambda
# 這是非常關鍵的一步，手動設定時 AWS 會自動幫我們處理
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_discord_notifier.function_name
  principal     = "s3.amazonaws.com"

  # 只允許來自我們指定的 S3 儲存桶的呼叫
  source_arn = "arn:aws:s3:::${var.bucket_name}"
}