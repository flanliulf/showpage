# HTML页面部署项目

这个项目用于管理和部署多个静态HTML文件到远程服务器，并配置nginx来提供外部访问。

## 项目结构

```
web-site-page/
├── deploy.sh                                           # 自动部署脚本
├── README.md                                           # 项目说明文档
├── promptbase-link-refly-guizang-v2-claude4.html      # HTML页面1
├── arxivlicense-link-refly-guizang-v2-claude4.html    # HTML页面2
├── openevals-link-sumbuddy-refly-guizang-v3-claude4.html # HTML页面3
├── openevals-link-refly-guizang-v3-claude4.html       # HTML页面4
└── openevals-link-refly-guizang-v2-claude4.html       # HTML页面5
```

## 服务器配置信息

- **服务器地址**: 114.55.150.44
- **用户名**: root
- **部署目录**: /root/www/page
- **访问域名**: show.coderboot.xyz
- **nginx配置**: /etc/nginx/sites-available/show.conf

## 快速部署

### 前提条件

1. 确保本地已安装SSH客户端
2. 确保可以通过SSH密钥登录到远程服务器（避免密码输入）
3. 远程服务器已安装nginx

### 部署步骤

1. **设置SSH密钥认证**（推荐）：
   ```bash
   # 生成SSH密钥（如果还没有）
   ssh-keygen -t rsa -b 4096
   
   # 将公钥复制到服务器
   ssh-copy-id root@114.55.150.44
   ```

2. **运行部署脚本**：
   ```bash
   # 赋予执行权限
   chmod +x deploy.sh
   
   # 执行部署
   ./deploy.sh
   ```

### 部署脚本功能

部署脚本会自动执行以下操作：

1. ✅ **创建远程目录** - 在服务器上创建 `/root/www/page` 目录
2. ✅ **上传HTML文件** - 将所有 `*.html` 文件上传到服务器
3. ✅ **设置文件权限** - 设置适当的文件权限和所有者
4. ✅ **创建nginx配置** - 生成 `/etc/nginx/sites-available/show.conf` 配置文件
5. ✅ **启用网站配置** - 创建软链接到 `sites-enabled` 目录
6. ✅ **测试nginx配置** - 验证配置文件语法正确
7. ✅ **重载nginx服务** - 应用新的配置
8. ✅ **创建索引页面** - 生成美观的主页面

## Nginx配置详情

生成的nginx配置文件包含以下功能：

### 基本配置
- 监听80端口
- 服务器名称：`show.coderboot.xyz`
- 网站根目录：`/root/www/page`
- 默认首页：`index.html`

### 性能优化
- **Gzip压缩**：启用文件压缩，减少传输大小
- **缓存策略**：静态文件缓存1年，提高访问速度
- **安全头部**：设置各种安全相关的HTTP头部

### API端点
- **页面列表API**: `http://show.coderboot.xyz/api/pages`
  - 返回JSON格式的页面列表
  - 包含页面名称和标题信息

### 错误处理
- 自定义404和50x错误页面
- 专门的访问日志和错误日志

## 访问方式

部署完成后，您可以通过以下方式访问：

### 主页面
- **URL**: http://show.coderboot.xyz
- **功能**: 显示所有页面的导航界面

### 具体页面
- http://show.coderboot.xyz/promptbase-link-refly-guizang-v2-claude4.html
- http://show.coderboot.xyz/arxivlicense-link-refly-guizang-v2-claude4.html
- http://show.coderboot.xyz/openevals-link-sumbuddy-refly-guizang-v3-claude4.html
- http://show.coderboot.xyz/openevals-link-refly-guizang-v3-claude4.html
- http://show.coderboot.xyz/openevals-link-refly-guizang-v2-claude4.html

### API接口
- **页面列表**: http://show.coderboot.xyz/api/pages

## 手动操作指南

如果需要手动执行操作，可以参考以下命令：

### 上传文件
```bash
scp *.html root@114.55.150.44:/root/www/page/
```

### 创建nginx配置
```bash
ssh root@114.55.150.44
cat > /etc/nginx/sites-available/show.conf << 'EOF'
# nginx配置内容...
EOF
```

### 启用配置
```bash
ln -sf /etc/nginx/sites-available/show.conf /etc/nginx/sites-enabled/show.conf
nginx -t
systemctl reload nginx
```

## 故障排除

### 常见问题

1. **SSH连接失败**
   - 检查服务器IP地址和端口
   - 确认SSH密钥配置正确
   - 验证服务器防火墙设置

2. **文件上传失败**
   - 检查目标目录权限
   - 确认磁盘空间足够
   - 验证文件路径正确

3. **nginx配置错误**
   - 使用 `nginx -t` 测试配置
   - 检查配置文件语法
   - 查看错误日志：`tail -f /var/log/nginx/error.log`

4. **域名无法访问**
   - 确认域名DNS解析正确
   - 检查防火墙80端口开放
   - 验证nginx服务运行状态：`systemctl status nginx`

### 日志查看
```bash
# nginx访问日志
tail -f /var/log/nginx/show.coderboot.xyz.access.log

# nginx错误日志
tail -f /var/log/nginx/show.coderboot.xyz.error.log

# nginx服务状态
systemctl status nginx
```

## 维护和更新

### 添加新页面
1. 将新的HTML文件放到项目目录
2. 运行部署脚本：`./deploy.sh`
3. 更新索引页面中的页面列表

### 更新现有页面
1. 修改本地HTML文件
2. 运行部署脚本：`./deploy.sh`

### 备份数据
```bash
# 备份远程文件
scp -r root@114.55.150.44:/root/www/page/ ./backup/

# 备份nginx配置
scp root@114.55.150.44:/etc/nginx/sites-available/show.conf ./backup/
```

## 安全建议

1. **定期更新**：保持服务器系统和nginx版本更新
2. **SSL证书**：考虑配置HTTPS证书提高安全性
3. **访问控制**：根据需要限制特定IP访问
4. **日志监控**：定期检查访问日志，发现异常访问

## 联系方式

如有问题或需要帮助，请参考文档或联系系统管理员。 