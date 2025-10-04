// =============================================================================
// 1. 設定要使用的雲端服務商 (Provider)
// =============================================================================
// 類似 package.json 裡的 dependencies 區塊
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" // 使用 5.0 以上的 AWS Provider 版本
    }
  }
}

// 設定 AWS Provider 的區域
// 推薦使用離台灣近的東京區域
provider "aws" {
  region = "ap-northeast-1"
}

// =============================================================================
// 2. 尋找要使用的 AMI (Amazon Machine Image)
// 這是更進階且穩健的做法，避免寫死 AMI ID
// =============================================================================
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"] // AWS 官方擁有的 AMI

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

// =============================================================================
// 3. 建立一個 EC2 執行個體 (Resource)
// =============================================================================
resource "aws_instance" "my_first_server" {
  // ami: 指定機器的作業系統映像檔，我們使用上面 data block 找到的最新版
  ami           = data.aws_ami.amazon_linux_2023.id

  // instance_type: 指定機器的規格大小，t2.micro 在免費方案額度內
  instance_type = "t3.micro"

  // tags: 為你的資源加上標籤，方便管理與辨識
  tags = {
    Name = "MyFirstTerraformServer"
    ManagedBy = "Terraform"
  }
}