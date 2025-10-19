# 1. 建立 Lambda 的執行角色 (Execution Role)
# 這就像是給 Lambda 一頂「帽子」，告訴 AWS 誰可以「戴」上它 (Lambda 服務)
resource "aws_iam_role" "lambda_exec_role" {
  name = "s3-discord-lambda-role"

  # Trust Policy: 允許 AWS Lambda 服務擔任這個角色
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 2. 附加 Lambda 基本執行權限 (用來寫日誌到 CloudWatch)
# 這就像是給「帽子」附加一個「權力徽章」
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}