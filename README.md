# ShowPage - HTML页面展示项目

这个项目用于管理和部署多个静态HTML文件到远程服务器，并通过nginx主配置文件提供统一的案例管理。项目采用**主配置文件架构**，所有静态案例项目都通过 `case.coderboot.xyz` 域名的不同路径进行访问。

## 🚀 项目特性
- ✅ **主配置文件架构** - 使用单一nginx配置管理所有静态案例
- ✅ **路径分离访问** - 通过不同路径区分各个案例项目
- ✅ **自动化部署脚本** - 智能检测和创建主配置文件
- ✅ **响应式主页设计** - 动态加载案例列表
- ✅ **RESTful API接口** - 提供JSON格式的页面列表
- ✅ **nginx性能优化** - gzip压缩、缓存策略
- ✅ **安全头部配置** - 完整的Web安全防护
- ✅ **完整的错误处理** - 优雅的错误页面
- ✅ **版本控制管理** - Git管理和SSH密钥安全

## 🏗 架构设计

### 主配置文件架构
```
case.coderboot.xyz (主域名)
├── /showpage/          # ShowPage 案例
├── /postereditor/      # PostEditor 案例 (规划中)
├── /案例3/             # 未来案例
└── /案例N/             # ...更多案例
```

### 配置文件结构
```
nginx/
├── sites-available/
│   ├── case.conf       # 主配置文件 (管理所有静态案例)
│   └── echo.conf       # 独立服务配置
└── sites-enabled/
    ├── case.conf -> ../sites-available/case.conf
    └── echo.conf -> ../sites-available/echo.conf
```

## 项目结构

```
showpage/
├── case.example.conf                                   # nginx配置文件示例
├── deploy.sh                                           # 自动部署脚本
├── README.md                                           # 项目说明文档
├── SSH_SETUP.md                                        # SSH密钥设置指南
├── promptbase-link-refly-guizang-v2-claude4.html      # HTML页面1
├── arxivlicense-link-refly-guizang-v2-claude4.html    # HTML页面2
├── openevals-link-sumbuddy-refly-guizang-v3-claude4.html # HTML页面3
├── openevals-link-refly-guizang-v3-claude4.html       # HTML页面4
└── openevals-link-refly-guizang-v2-claude4.html       # HTML页面5
```

### 📋 nginx配置文件

项目包含了一个完整的nginx配置文件示例 `case.example.conf`，这个文件包含：

- **🔧 完整配置**：包含所有必要的location块、安全头部、缓存策略
- **📝 详细注释**：每个配置项都有详细的中文注释说明
- **🚀 部署指南**：包含完整的使用说明和部署步骤
- **🔒 安全配置**：防止XSS、点击劫持等安全威胁
- **⚡ 性能优化**：gzip压缩、智能缓存策略
- **📈 扩展支持**：为未来案例预留了配置模板

#### 使用方法

```bash
# 复制配置文件到nginx目录
sudo cp case.example.conf /etc/nginx/sites-available/case.conf

# 启用配置
sudo ln -sf /etc/nginx/sites-available/case.conf /etc/nginx/sites-enabled/case.conf

# 测试配置
sudo nginx -t

# 重载nginx
sudo systemctl reload nginx
```

此配置文件是项目架构的核心，建议在手动部署或故障排除时参考使用。

## 服务器配置信息

- **服务器地址**: 114.55.150.44
- **用户名**: root
- **SSH别名**: aliyun-ecs-showpage（需配置）
- **部署目录**: /root/www/showpage
- **访问域名**: case.coderboot.xyz/showpage
- **主配置文件**: /etc/nginx/sites-available/case.conf

### SSH密钥配置

项目使用SSH密钥认证进行安全连接：
- **私钥**: `~/.ssh/aliyun_ecs_id_rsa`
- **公钥**: `~/.ssh/aliyun_ecs_id_rsa.pub`
- **SSH配置**: `~/.ssh/config` 中的 `aliyun-ecs-showpage` 别名
- **设置指南**: [`SSH_SETUP.md`](./SSH_SETUP.md)

## 快速部署

### 前提条件

1. 确保本地已安装SSH客户端
2. 确保可以通过SSH密钥登录到远程服务器（避免密码输入）
3. 远程服务器已安装nginx

### 部署步骤

1. **设置SSH密钥认证**（推荐）：
   
   按照以下步骤设置SSH密钥：
   
   ```bash
   # 生成专用SSH密钥对
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/aliyun_ecs_id_rsa -C "showpage-deploy@aliyun-ecs"
   
   # 上传公钥到服务器
   ssh-copy-id -i ~/.ssh/aliyun_ecs_id_rsa.pub aliyun-ecs-showpage
   ```
   
   📖 **详细设置说明**：请参考 [`SSH_SETUP.md`](./SSH_SETUP.md) 文档获取完整的SSH密钥设置指南，包含SSH客户端配置等步骤。

2. **运行部署脚本**：
   ```bash
   # 赋予执行权限
   chmod +x deploy.sh
   
   # 执行部署
   ./deploy.sh
   ```

### 部署脚本功能

部署脚本会自动执行以下操作：

1. ✅ **创建远程目录** - 在服务器上创建 `/root/www/showpage` 目录
2. ✅ **上传HTML文件** - 将所有 `*.html` 文件上传到服务器
3. ✅ **设置文件权限** - 设置适当的文件权限和所有者
4. ✅ **检查主配置文件** - 智能检测 `/etc/nginx/sites-available/case.conf` 是否存在
5. ✅ **创建/更新主配置** - 自动创建或保持现有的主配置文件
6. ✅ **启用网站配置** - 创建软链接到 `sites-enabled` 目录
7. ✅ **测试nginx配置** - 验证配置文件语法正确
8. ✅ **重载nginx服务** - 应用新的配置
9. ✅ **创建索引页面** - 生成美观的案例导航主页

## 主配置文件详情

`/etc/nginx/sites-available/case.conf` 是核心配置文件，包含以下功能：

### 基本配置
- 监听80端口
- 服务器名称：`case.coderboot.xyz`
- 主域名管理所有静态案例

### ShowPage 案例配置
- **应用路径**：`/showpage`
- **网站根目录**：`/root/www/showpage`
- **默认首页**：`index.html`
- **API端点**：`/showpage/api/pages`

### 性能优化
- **Gzip压缩**：启用文件压缩，减少传输大小
- **缓存策略**：静态文件缓存30天，HTML文件不缓存
- **安全头部**：设置各种安全相关的HTTP头部

### 扩展能力
- **模块化设计**：新案例可轻松添加到主配置文件
- **路径隔离**：每个案例通过独立路径访问
- **统一管理**：所有静态案例使用同一配置文件

## 访问方式

部署完成后，您可以通过以下方式访问：

### 主页面
- **URL**: http://case.coderboot.xyz/showpage/
- **功能**: 显示所有页面的导航界面，动态加载案例信息

### 具体页面
- 🏠 **主页导航**: http://case.coderboot.xyz/showpage/
- 📄 **PromptBase页面**: http://case.coderboot.xyz/showpage/promptbase-link-refly-guizang-v2-claude4.html
- 📄 **ArxivLicense页面**: http://case.coderboot.xyz/showpage/arxivlicense-link-refly-guizang-v2-claude4.html
- 📄 **OpenEvals Sumbuddy页面**: http://case.coderboot.xyz/showpage/openevals-link-sumbuddy-refly-guizang-v3-claude4.html
- 📄 **OpenEvals v3页面**: http://case.coderboot.xyz/showpage/openevals-link-refly-guizang-v3-claude4.html
- 📄 **OpenEvals v2页面**: http://case.coderboot.xyz/showpage/openevals-link-refly-guizang-v2-claude4.html

### API接口
- **页面列表**: http://case.coderboot.xyz/showpage/api/pages

## 新案例添加指南

当需要添加新的静态案例项目时，按照以下步骤操作：

### 1. 准备案例文件
```bash
# 创建新案例目录
mkdir /root/www/新案例名称

# 上传案例文件到目录
```

### 2. 更新主配置文件
在 `/etc/nginx/sites-available/case.conf` 中添加新的location块：

```nginx
# ========== 新案例名称 ==========
# 新案例应用路径
location /新案例路径 {
    alias /root/www/新案例目录;
    index index.html;
    try_files $uri $uri/ =404;
    
    # 设置安全头 (复制现有的安全头配置)
}

# 新案例API接口 (可选)
location /新案例路径/api/pages {
    default_type application/json;
    return 200 '{"pages": [...]}';
}
```

### 3. 重新加载配置
```bash
nginx -t && systemctl reload nginx
```

## 手动操作指南

如果需要手动执行操作，可以参考以下命令：

### 上传文件
```bash
# 使用SSH别名（推荐）
scp *.html aliyun-ecs-showpage:/root/www/showpage/

# 或使用IP地址
scp *.html root@114.55.150.44:/root/www/showpage/
```

### 管理主配置文件
```bash
# 使用SSH别名（推荐）
ssh aliyun-ecs-showpage

# 编辑主配置文件
vim /etc/nginx/sites-available/case.conf

# 测试配置
nginx -t

# 重新加载配置
systemctl reload nginx
```

### 启用配置
```bash
ln -sf /etc/nginx/sites-available/case.conf /etc/nginx/sites-enabled/case.conf
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
   - 检查主配置文件语法
   - 查看错误日志：`tail -f /var/log/nginx/error.log`

4. **域名无法访问**
   - 确认域名DNS解析正确
   - 检查防火墙80端口开放
   - 验证nginx服务运行状态：`systemctl status nginx`

5. **新案例无法访问**
   - 检查主配置文件中的location路径
   - 确认案例目录权限正确
   - 验证nginx配置重新加载

### 日志查看
```bash
# nginx访问日志
tail -f /var/log/nginx/case.coderboot.xyz.access.log

# nginx错误日志
tail -f /var/log/nginx/case.coderboot.xyz.error.log

# nginx服务状态
systemctl status nginx

# 检查主配置文件
nginx -T | grep -A 50 "case.coderboot.xyz"
```

## 项目优势

### 🎯 **统一管理**
- 单一主配置文件管理所有静态案例
- 避免多个配置文件的冲突和维护复杂性
- 统一的域名和访问入口

### 🚀 **易于扩展**
- 新案例只需添加location块到主配置
- 标准化的案例结构和API接口
- 自动化的部署流程

### 🔒 **安全可靠**
- SSH密钥认证，避免密码泄露风险
- 完整的Web安全头部配置
- 文件权限和访问控制

### ⚡ **性能优化**
- Gzip压缩减少传输大小
- 智能缓存策略提高访问速度
- 针对静态文件的专门优化

---

**©️ 2025 ShowPage Project - 基于nginx主配置文件的静态案例管理系统** 