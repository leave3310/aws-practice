resource "aws_s3_bucket" "my_website_bucket" {
  bucket = "kk-s3-bucket-2025"
}

resource "aws_s3_bucket_public_access_block" "my_website_access_block" {
  bucket = aws_s3_bucket.my_website_bucket.id

  # 我們只把這一項關掉，允許 bucket policy
  block_public_policy = false

  # 其他的選項我們先維持開啟，增加安全性
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "my_website_ownership" {
  bucket = aws_s3_bucket.my_website_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.my_website_bucket.id
  key          = "index.html"
  source       = "index.html" # 記得改成你本地檔案的路徑
  content_type = "text/html"
  etag         = filemd5("index.html")
}

resource "aws_s3_bucket_website_configuration" "my_website_config" {
  # 這裡需要告訴 Terraform 這個設定是對應到哪個 bucket
  bucket = aws_s3_bucket.my_website_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.my_website_bucket.id

  # policy 需要一個 JSON 格式的字串
  # 我們可以用 Terraform 的 jsonencode 函數來產生
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow" // 
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource = [
          "${aws_s3_bucket.my_website_bucket.arn}/*" # 代表 bucket 裡的所有物件
        ]
        Condition = {
          StringEquals = {
            # 限制來源必須是我們的 CloudFront Distribution
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.my_website_access_block,
    aws_s3_bucket_ownership_controls.my_website_ownership # 加上新的依賴
  ]
}

