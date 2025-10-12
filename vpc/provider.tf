terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" // 使用 5.0 以上的 AWS Provider 版本
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}