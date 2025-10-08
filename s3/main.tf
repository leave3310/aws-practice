// =============================================================================
// 1. 設定要使用的雲端服務商 (Provider)
// =============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" // 使用 5.0 以上的 AWS Provider 版本
    }
  }
}

// 設定 AWS Provider[內碼]  的區域
// 推薦使用離台灣近的東京區域
provider "aws" {
  region = "ap-northeast-1"
}