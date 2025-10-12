resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH from my IP to Bastion"
  vpc_id      = aws_vpc.main.id

  # "ingress" 代表「傳入」的規則
  ingress {
    from_port   = 22      # SSH 服務的 port
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 允許任何 IP 連進來
  }

  # "egress" 代表「傳出」的規則
  egress {
    from_port   = 0       # 0 代表所有 port
    to_port     = 0
    protocol    = "-1"    # -1 代表所有協定
    cidr_blocks = ["0.0.0.0/0"] # 允許連到任何地方
  }

  tags = {
    Name = "bastion-sg"
  }
}

# 防火牆 2: 給私有主機使用
resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "Allow SSH from Bastion SG only"
  vpc_id      = aws_vpc.main.id

  # 這是最關鍵的安全規則！
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # 注意這一行
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg"
  }
}