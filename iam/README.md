# 學習目標

- 嘗試了解 root user 跟 iam user 的差別。
- 嘗試了解 policy、role、group、user 的差別。
- 嘗試新增一個 ReadOnly 的 user，並且將 credential (password) 透過 discord 傳給我。
- (進階) 嘗試透過 EC2 使用 aws-cli 存取 S3 資源，並且透過 attach role 的方式給予 ec2 權限。

# Root User

擁有對帳號內所有服務和資源的無限制存取權限，沒有任何例外。有些特殊操作，例如關閉整個 AWS 帳號或變更付款資訊，也只有 root user 能做

因為 root user 的權力如此之大，最佳安全實踐是不要在日常工作中使用它。
在團隊合作中，或甚至只是自己為了避免操作失誤，需要一種方法來限制權限

# IAM user

只給予一個使用者完成其工作所必需的、最小的權限集合，不多也不少，也符合 AWS 安全性中的一個核心原則：「最小權限原則 (Principle of Least Privilege)」

# Policy

上面會清楚地寫著：

- 誰 (Principal)：通常是某個 IAM user 或 role。
- 可以做什麼 (Action)：例如 ec2:StartInstances (啟動 EC2) 或 s3:GetObject (讀取 S3 物件)。
- 對什麼資源 (Resource)：例如某一台特定的 EC2 伺服器，或某一個特定的 S3 儲存桶。
- 結果是允許還是拒絕 (Effect)：Allow / Deny。

一份允許讀取 S3 儲存桶資料的 Policy 可能會長這樣：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-example-bucket/*"
    }
  ]
}
```

接下來只要把這個 policy 附加 (attach) 到某個 IAM user 上，這個 user 就能讀取 my-example-bucket 裡的資料了

# Group

假設公司來了 5 位新的開發者，他們都需要一模一樣的權限。此時就可以用 Group 的方式來管理權限，這樣就不用相同的權限操作 5 次了！

有點像是下面的例子：
不用把 Policy 一個一個地貼到 user 身上，而是把 user 放到一個「籃子」裡，然後只要把 Policy 貼在這個「籃子」上，籃子裡的所有 user 就自動擁有了這個權限。

# IAM Role

除了可以給機器權限以外 (像是 EC2 需要自動去讀取 S3 儲存桶裡的資料)，也可以給人權限。

假如有一個外包需要存取 AWS 的資訊，就可以建立 IAM Role，然後把這個 Role 的權限給外包，這樣就不用建立一個真正的 IAM user 給他。這樣一來就不用擔心外包離職後忘記把 user 刪掉的問題。也不用擔心外包會把 user 的密碼記錄下來，然後在離職後繼續存取公司的 AWS 資源，導致重要資訊外洩。

# 新增 s3 read only user

1. 前往 IAM Management Console
2. 點選 Users -> Add users
3. 輸入使用者名稱 (例如 readonly-user)
4. 選擇存取類型 (Access type) 為 Programmatic access
5. 點選 Next: Permissions
6. 選擇 Attach existing policies directly
7. 在搜尋欄輸入 "ReadOnlyAccess"

接下來設定密碼要到 Security credentials tab 裡面設定
進去後要在 console sign-in 區塊那邊，會有一個 manage 按鈕，點進去後就可以設定密碼

# Terraform 中 EC2 綁定 IAM Role 的問題與解決方案

## 1. 問題描述 (Problem Description)

在使用 Terraform 建立 `aws_ec2_instance` 時，直覺上會認為可以直接在 EC2 資源中綁定一個 `aws_iam_role`。然而，Terraform 的 `aws_ec2_instance` 資源並沒有直接接受 IAM Role ARN 或名稱的 `iam_role` 參數。

如果嘗試直接賦值，Terraform 會在 `plan` 或 `apply` 階段報錯，指出 `iam_role` 不是 `aws_ec2_instance` 的有效參數。這導致 EC2 實例啟動後，無法獲得預期的 AWS API 操作權限，應用程式因此失敗。

## 2. 問題根源 (Root Cause)

AWS 的設計中，EC2 實例並非直接與 IAM Role 關聯。其關聯是透過一個中介層 ——**IAM Instance Profile** 來完成的。

流程如下：

1. 建立一個 **IAM Role**，並定義其信任關係 (Trust Policy)，允許 EC2 服務擔任 (Assume) 這個角色。
2. 建立一個 **IAM Instance Profile**，它像一個容器或載體。
3. 你將建立好的 **IAM Role** **附加 (Attach)**  到這個 **IAM Instance Profile** 上。
4. 最後，在建立 **EC2 實例**時，將這個 **IAM Instance Profile** **關聯 (Associate)**  到 EC2 實例上。

因此，Terraform 的資源設計也遵循了這個架構，我們無法跳過 Instance Profile 這一步。
會這樣寫是因為清晰的定義關聯關係，在日後管理和維護上更為方便。若是在 console 透過點選方式建立，雖然不需要自行建立這段 IAM Instance Profile，但背後其實也是做了這些步驟。只是在 terraform 中需要明確地定義這些資源和關聯。

## 3. 解決方案 (Solution)

解決此問題的標準做法是依序建立 `aws_iam_role`、`aws_iam_instance_profile`，最後在 `aws_ec2_instance` 中引用 Instance Profile。

### 解決步驟的 Terraform HCL 範例

以下是完整的 Terraform 設定檔，展示了正確的解決流程：

```hcl
# 步驟 1: 建立 IAM Role 給 EC2 使用
# Trust Policy 允許 ec2.amazonaws.com 擔任此角色
resource "aws_iam_role" "ec2_app_role" {
  name = "my-app-ec2-role"

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

  tags = {
    Name = "EC2 Application Role"
  }
}

# (可選) 附加權限策略到 Role 上
# 例如，允許讀取 S3
resource "aws_iam_role_policy_attachment" "s3_read_policy_attachment" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}


# 步驟 2: 建立 IAM Instance Profile 並將 Role 附加進去
resource "aws_iam_instance_profile" "ec2_app_profile" {
  name = "my-app-ec2-profile"
  role = aws_iam_role.ec2_app_role.name
}


# 步驟 3: 建立 EC2 實例，並在參數中綁定 Instance Profile
resource "aws_ec2_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0" # 請替換成您的 AMI ID
  instance_type = "t2.micro"

  # 關鍵步驟：使用 `iam_instance_profile` 參數，並傳入 Instance Profile 的名稱
  iam_instance_profile = aws_iam_instance_profile.ec2_app_profile.name

  # Terraform 會自動處理依賴關係，但若遇到 race condition 問題，
  # 可以手動加上 depends_on 來確保建立順序。
  depends_on = [
    aws_iam_instance_profile.ec2_app_profile
  ]

  tags = {
    Name = "My App Server"
  }
}
```