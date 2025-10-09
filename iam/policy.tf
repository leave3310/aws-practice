resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3-full-access-policy"
  description = "Allows full access to S3"

  # 這裡就是我們用程式碼寫的 JSON "權限說明書"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:*", # 代表所有 S3 相關操作
        Resource = "*"     # 代表所有資源
      }
    ]
  })
}

resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2-s3-access-role"

  # This is the most critical part: the trust relationship
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attach" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}
