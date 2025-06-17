# SSH密钥认证设置指南

本指南将帮助您为阿里云ECS服务器设置SSH密钥认证，以便无密码部署ShowPage项目。

> ⚠️ **安全提醒**：SSH密钥是重要的安全凭证，请勿将私钥文件或公钥内容分享给他人或提交到公共代码仓库。

## 步骤概览

1. 🔲 **待完成** - 生成SSH密钥对
2. 🔲 **待完成** - 配置本地SSH客户端
3. 🔲 **待完成** - 将公钥上传到阿里云ECS服务器
4. 🔲 **待完成** - 测试SSH连接

## 1. 生成SSH密钥对

运行以下命令生成专用于ShowPage部署的SSH密钥对：

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aliyun_ecs_id_rsa -C "showpage-deploy@aliyun-ecs"
```

这将创建：
- **私钥文件**: `~/.ssh/aliyun_ecs_id_rsa`
- **公钥文件**: `~/.ssh/aliyun_ecs_id_rsa.pub`

## 2. 配置SSH客户端

在 `~/.ssh/config` 文件中添加以下配置：

```
# Aliyun ECS for ShowPage deployment
Host aliyun-ecs-showpage
	User root
	HostName 114.55.150.44
	IdentityFile ~/.ssh/aliyun_ecs_id_rsa
	PreferredAuthentications publickey
	AddKeysToAgent yes
	UseKeychain yes
```

如果文件不存在，请先创建：
```bash
touch ~/.ssh/config
chmod 600 ~/.ssh/config
```

## 3. 上传公钥到阿里云ECS服务器

### 方法一：使用ssh-copy-id（推荐）

```bash
ssh-copy-id -i ~/.ssh/aliyun_ecs_id_rsa.pub aliyun-ecs-showpage
```

### 方法二：手动复制公钥

1. **查看您的公钥内容**：
   ```bash
   cat ~/.ssh/aliyun_ecs_id_rsa.pub
   ```

2. **登录到阿里云ECS服务器**：
   ```bash
   ssh root@114.55.150.44
   ```

3. **创建.ssh目录**（如果不存在）：
   ```bash
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   ```

4. **将公钥添加到authorized_keys**：
   ```bash
   # 使用vi/nano编辑器
   vi ~/.ssh/authorized_keys
   # 然后粘贴您的公钥内容
   ```

5. **设置正确的权限**：
   ```bash
   chmod 600 ~/.ssh/authorized_keys
   ```

6. **退出服务器**：
   ```bash
   exit
   ```

## 4. 测试SSH连接

完成上述步骤后，测试SSH连接：

```bash
ssh aliyun-ecs-showpage
```

如果连接成功且无需输入密码，说明SSH密钥认证设置成功！

## 5. 运行部署脚本

SSH密钥认证设置完成后，您就可以无密码运行部署脚本了：

```bash
./deploy.sh
```

## 故障排除

### 连接被拒绝
- 确认服务器IP地址和端口正确
- 检查阿里云安全组是否开放22端口
- 确认服务器SSH服务正在运行

### 仍然要求输入密码
- 检查公钥是否正确添加到 `~/.ssh/authorized_keys`
- 确认文件权限正确：
  - `~/.ssh` 目录权限：700
  - `~/.ssh/authorized_keys` 文件权限：600
- 查看服务器SSH日志：`tail -f /var/log/auth.log`

### SSH密钥权限问题
```bash
# 设置正确的本地密钥权限
chmod 600 ~/.ssh/aliyun_ecs_id_rsa
chmod 644 ~/.ssh/aliyun_ecs_id_rsa.pub
```

## 安全建议

1. **保护密钥安全** - 永远不要分享私钥文件，不要将密钥内容提交到代码仓库
2. **定期轮换密钥** - 建议每6个月更换一次SSH密钥
3. **禁用密码登录** - 设置成功后，建议在服务器上禁用密码登录
4. **启用防火墙** - 确保只允许必要的端口访问
5. **监控登录日志** - 定期检查SSH登录日志
6. **备份密钥** - 将私钥安全备份到加密存储中

## 附录：禁用密码登录（可选）

在SSH密钥认证设置成功后，您可以考虑禁用密码登录以提高安全性：

1. **编辑SSH配置**：
   ```bash
   sudo vim /etc/ssh/sshd_config
   ```

2. **修改以下配置**：
   ```
   PasswordAuthentication no
   ChallengeResponseAuthentication no
   UsePAM no
   ```

3. **重启SSH服务**：
   ```bash
   sudo systemctl restart sshd
   ```

⚠️ **警告**：在禁用密码登录之前，请确保SSH密钥认证工作正常，否则可能无法再登录服务器！ 