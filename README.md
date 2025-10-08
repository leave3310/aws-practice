# 學習目標
- 嘗試了解 root user 跟 iam user 的差別。
- 嘗試了解 policy、role、group、user 的差別。
- 嘗試新增一個 ReadOnly 的 user，並且將 credential (password) 透過 discord 傳給我。
- （進階）嘗試透過 EC2 使用 aws-cli 存取 S3 資源，並且透過 attach role 的方式給予 ec2 權限。

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
除了可以給機器權限以外（像是 EC2 需要自動去讀取 S3 儲存桶裡的資料），也可以給人權限。

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