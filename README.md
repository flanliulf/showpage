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
├── DEPLOYMENT_VALIDATION.md                            # 部署验证流程文档
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

## 技术架构说明

### 符号链接方案 vs Alias方案

项目最初尝试使用nginx的 `alias` 指令，但遇到了路径解析和配置复杂性问题。最终采用了更可靠的**符号链接 + root配置**方案：

#### ❌ Alias方案问题
```nginx
# 容易出现路径解析错误的配置
location /showpage/ {
    alias /root/www/showpage/;
    try_files $uri $uri/ /showpage/index.html;  # 易错的路径引用
}
```

#### ✅ 符号链接方案优势
```nginx
# 更可靠的配置方式
server {
    root /var/www/html;  # 全局root设置
}

location /showpage {
    try_files $uri $uri/ $uri/index.html =404;  # 简洁的路径处理
}
```

**实现原理**：
1. 文件实际存储：`/root/www/showpage/`
2. 符号链接映射：`/var/www/html/showpage -> /root/www/showpage`
3. nginx配置：使用 `root /var/www/html` 统一处理所有location

**技术优势**：
- 🔧 **配置简洁**：避免复杂的alias路径映射
- 🚀 **路径可靠**：不会出现try_files的路径解析错误
- 🔒 **权限清晰**：文件保持在 `/root/www` 下由root管理
- 📈 **易于扩展**：新案例只需创建符号链接和添加location块

## 服务器配置信息

- **服务器地址**: 114.55.150.44
- **用户名**: root
- **SSH别名**: aliyun-ecs-showpage（需配置）
- **部署目录**: /root/www/showpage (文件实际存储位置)
- **nginx映射**: /var/www/html/showpage (通过符号链接)
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

### 部署方式选择

项目提供两种部署脚本：

#### 1. 基础部署脚本 (`deploy.sh`)
适用于首次部署或手动控制配置更新：
```bash
chmod +x deploy.sh && ./deploy.sh
```

#### 2. 增强版部署脚本 (`deploy-enhanced.sh`) ⭐ **推荐**
自动检测HTML文件并动态更新配置，适用于日常开发和新页面添加：
```bash
chmod +x deploy-enhanced.sh && ./deploy-enhanced.sh
```

**增强版特性**：
- 🔍 **自动检测**：自动扫描本地所有 `*.html` 文件
- 📝 **智能提取**：自动从HTML文件中提取页面标题
- 🔄 **动态更新**：自动更新nginx配置中的页面列表API
- 🎨 **美观主页**：自动生成包含所有页面的美观索引页面
- ⚡ **一键部署**：无需手动更新配置文件

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
   
   📋 **部署验证流程**：请参考 [`DEPLOYMENT_VALIDATION.md`](./DEPLOYMENT_VALIDATION.md) 文档获取完整的部署验证流程和技术问题解决方案。

2. **运行部署脚本**：
   ```bash
   # 推荐：使用增强版部署脚本
   chmod +x deploy-enhanced.sh && ./deploy-enhanced.sh
   
   # 或者：使用基础部署脚本
   chmod +x deploy.sh && ./deploy.sh
   ```

## 📄 新增HTML页面的完整流程

### 开发阶段
1. **创建HTML文件**：在项目根目录中创建新的HTML文件
2. **本地测试**：在浏览器中打开文件进行本地测试
3. **版本控制**：
   ```bash
   git add your-new-page.html
   git commit -m "添加新页面: your-new-page.html"
   git push origin main
   ```

### 部署阶段
使用增强版部署脚本进行一键部署：
```bash
chmod +x deploy-enhanced.sh && ./deploy-enhanced.sh
```

**增强版脚本会自动**：
- ✅ 检测新的HTML文件
- ✅ 提取页面标题（从`<title>`标签）
- ✅ 更新nginx配置中的API页面列表
- ✅ 上传所有文件到服务器
- ✅ 更新服务器配置并重载nginx
- ✅ 生成包含新页面的美观索引页面

### 验证部署
1. **访问主页**：http://case.coderboot.xyz/showpage/
2. **访问新页面**：http://case.coderboot.xyz/showpage/your-new-page.html
3. **检查API**：http://case.coderboot.xyz/showpage/api/pages

### 手动配置更新（仅当自动化失败时）
如果需要手动更新配置：
1. 编辑 `case.example.conf` 中的页面列表
2. 使用基础部署脚本：`./deploy.sh`

### 最佳实践
- 🎯 **文件命名**：使用描述性的文件名，便于识别
- 📝 **页面标题**：确保HTML文件包含清晰的`<title>`标签
- 🔄 **增量部署**：推荐使用增强版脚本进行日常部署
- 📋 **版本控制**：所有新页面都应提交到Git仓库
- 🧪 **本地测试**：部署前在本地浏览器中测试页面

### 部署脚本功能

部署脚本会自动执行以下操作：

1. ✅ **创建远程目录** - 在服务器上创建 `/root/www/showpage` 目录
2. ✅ **上传HTML文件** - 将所有 `*.html` 文件上传到服务器
3. ✅ **设置文件权限** - 设置适当的文件权限和所有者
4. ✅ **检查主配置文件** - 智能检测 `/etc/nginx/sites-available/case.conf` 是否存在
5. ✅ **创建/更新主配置** - 自动创建或保持现有的主配置文件(使用符号链接方案)
6. ✅ **创建符号链接** - 建立 `/var/www/html/showpage -> /root/www/showpage` 映射
7. ✅ **启用网站配置** - 创建软链接到 `sites-enabled` 目录
8. ✅ **测试nginx配置** - 验证配置文件语法正确
9. ✅ **重载nginx服务** - 应用新的配置
10. ✅ **创建索引页面** - 生成美观的案例导航主页

## 主配置文件详情

`/etc/nginx/sites-available/case.conf` 是核心配置文件，包含以下功能：

### 基本配置
- 监听80端口
- 服务器名称：`case.coderboot.xyz`
- 主域名管理所有静态案例

### ShowPage 案例配置
- **应用路径**：`/showpage`
- **文件实际目录**：`/root/www/showpage` (通过符号链接映射)
- **nginx访问路径**：`/var/www/html/showpage` (符号链接指向实际目录)
- **默认首页**：`index.html`
- **API端点**：`/showpage/api/pages`

### 符号链接架构说明
项目采用符号链接方案解决nginx alias配置的复杂性：
- **文件存储**：实际文件存储在 `/root/www/showpage/`
- **访问映射**：nginx通过符号链接 `/var/www/html/showpage -> /root/www/showpage` 访问文件
- **配置优势**：使用 `root /var/www/html` + `location /showpage` 替代复杂的 `alias` 配置
- **维护便利**：文件权限由 `root:root` 管理，避免权限问题

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

### 2. 创建符号链接
```bash
# 创建符号链接（关键步骤）
ln -sf /root/www/新案例名称 /var/www/html/新案例名称
```

### 3. 更新主配置文件
在 `/etc/nginx/sites-available/case.conf` 中添加新的location块：

```nginx
# ========== 新案例名称 ==========
# 新案例应用路径
# 文件实际路径：/root/www/新案例名称 (通过符号链接映射)
# 重要：需要先创建符号链接 ln -sf /root/www/新案例名称 /var/www/html/新案例名称
location /新案例路径 {
    # 使用root + try_files的方式，避免nginx alias配置的坑
    try_files $uri $uri/ $uri/index.html =404;
    
    # 安全头部配置 (复制现有的安全头配置)
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}

# 新案例API接口 (可选)
location /新案例路径/api/pages {
    default_type application/json;
    return 200 '{"pages": [...]}';
}
```

### 4. 重新加载配置
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