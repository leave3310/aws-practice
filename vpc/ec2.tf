data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical's Owner ID
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private.id
  key_name      = var.ssh_key_name
  
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  tags = {
    Name = "my-web-server"
  }
}

# 堡壘機 (跳板機)
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id # 放在 Public Subnet
  key_name                    = var.ssh_key_name
  
  # 自動分配一個公開 IP，只要關閉 ec2，ip 就會變動
  associate_public_ip_address = true 
  
  # 套用我們剛才建立的堡壘機防火牆
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "my-bastion-host"
  }
}