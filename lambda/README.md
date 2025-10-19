# 目標
嘗試使用 lambda 實作，在圖片上傳 S3 bucket 時，通知使用者的功能（打 discord），以通知會計人員有單據上傳。

# handler
這東西在自己定義的區塊內不一定要叫做 handler，可以在 terraform 裡面指定要用哪個 function 當作 entry point。
包含檔案名稱也是，可以自己定義

```terraform
resource "aws_lambda_function" "s3_discord_notifier" {
  ...
  # 對應到我們選擇的 Runtime 和 handler
  handler = "index.handler"
  ...
}
```
而 event 裡面有什麼內容，可以參考官方文件：https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-content-structure.html

# 如何把 code 給 lambda 用
如果只有很單純的 code，寫完後壓成 zip 就好。但如果 code 比較複雜，像是有第三方套件的話，就需要 build 完後打包成 zip 檔案給 lambda 使用！

# 為甚麼不用特別寫 cloudwatch 相關設定就能把 lambda 執行相關內容 log 起來呢？
如果沒有特別要做什麼，只要把 lambda 綁定 AWSLambdaBasicExecutionRole 這個 policy 就可以了，裡面已經包含把 log 寫到 cloudwatch 的權限了！
```terraform
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

# 備註
path.module 這東西會自動帶入目前 module 的路徑，所以就不需要自行手動設定路徑了。