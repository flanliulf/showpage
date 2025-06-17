#!/bin/bash

# 部署脚本 - 将HTML文件上传到远程服务器并配置nginx
# 服务器信息
SERVER_HOST="aliyun-ecs-showpage"  # 使用SSH配置别名
REMOTE_PATH="/root/www/showpage"
DOMAIN="case.coderboot.xyz"

echo "========================================="
echo "开始部署HTML文件到远程服务器"
echo "服务器: $SERVER_HOST"
echo "目标目录: $REMOTE_PATH"
echo "域名: $DOMAIN (通过主配置文件 case.conf 管理)"
echo "========================================="

# 1. 创建远程目录
echo "1. 创建远程目录..."
ssh $SERVER_HOST "mkdir -p $REMOTE_PATH"

if [ $? -eq 0 ]; then
    echo "✓ 远程目录创建成功"
else
    echo "✗ 远程目录创建失败"
    exit 1
fi

# 2. 上传HTML文件
echo "2. 上传HTML文件..."
scp *.html $SERVER_HOST:$REMOTE_PATH/

if [ $? -eq 0 ]; then
    echo "✓ HTML文件上传成功"
else
    echo "✗ HTML文件上传失败"
    exit 1
fi

# 3. 设置文件权限
echo "3. 设置文件权限..."
ssh $SERVER_HOST "chmod 644 $REMOTE_PATH/*.html && chown -R root:root $REMOTE_PATH && chmod 755 /root /root/www && chmod 755 $REMOTE_PATH"

if [ $? -eq 0 ]; then
    echo "✓ 文件权限设置成功"
else
    echo "✗ 文件权限设置失败"
fi

# 4. 检查主配置文件是否存在
echo "4. 检查主配置文件..."
ssh $SERVER_HOST "test -f /etc/nginx/sites-available/case.conf"

if [ $? -eq 0 ]; then
    echo "✓ 主配置文件 case.conf 已存在"
else
    echo "⚠ 主配置文件 case.conf 不存在，创建中..."
    
    # 创建主配置文件
    ssh $SERVER_HOST "cat > /etc/nginx/sites-available/case.conf << 'EOF'
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/html;
    
    # 启用gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # 根路径重定向到 /showpage
    location = / {
        return 301 /showpage/;
    }
    
    # ========== ShowPage 案例 ==========
    # showpage 应用路径 - 使用符号链接避免alias问题
    # 文件实际路径：/root/www/showpage/ (通过符号链接映射)
    # 访问地址：http://$DOMAIN/showpage/
    # 重要：需要先创建符号链接 ln -sf /root/www/showpage /var/www/html/showpage
    location /showpage {
        # 使用root + try_files的方式，避免nginx alias配置的坑
        try_files \$uri \$uri/ \$uri/index.html =404;
        
        # 安全头部配置，防止XSS、点击劫持等攻击
        add_header X-Frame-Options \"SAMEORIGIN\" always;
        add_header X-XSS-Protection \"1; mode=block\" always;
        add_header X-Content-Type-Options \"nosniff\" always;
        add_header Referrer-Policy \"no-referrer-when-downgrade\" always;
        add_header Content-Security-Policy \"default-src 'self' http: https: data: blob: 'unsafe-inline'\" always;
    }
    
    # showpage 页面列表API接口
    # 返回当前可用的HTML页面列表（JSON格式）
    # 访问地址：http://$DOMAIN/showpage/api/pages
    location /showpage/api/pages {
        default_type application/json;
        return 200 '{
            \"pages\": [
                {\"name\": \"promptbase-link-refly-guizang-v2-claude4.html\", \"title\": \"PromptBase Link Refly v2\"},
                {\"name\": \"arxivlicense-link-refly-guizang-v2-claude4.html\", \"title\": \"ArxivLicense Link Refly v2\"},
                {\"name\": \"openevals-link-sumbuddy-refly-guizang-v3-claude4.html\", \"title\": \"OpenEvals Link Sumbuddy v3\"},
                {\"name\": \"openevals-link-refly-guizang-v3-claude4.html\", \"title\": \"OpenEvals Link Refly v3\"},
                {\"name\": \"openevals-link-refly-guizang-v2-claude4.html\", \"title\": \"OpenEvals Link Refly v2\"}
            ]
        }';
    }
    
    # ========== 缓存策略 ==========
    # 静态资源缓存（图片、CSS、JS等）
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control \"public, immutable\";
    }
    
    # HTML文件不缓存，确保内容更新能及时生效
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control \"no-store, no-cache, must-revalidate, proxy-revalidate\";
    }
    
    # ========== 错误页面和日志 ==========
    # 自定义错误页面
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    # 日志文件配置
    access_log /var/log/nginx/$DOMAIN.access.log;
    error_log /var/log/nginx/$DOMAIN.error.log;
    
    # ========== 安全配置 ==========
    # 禁止访问隐藏文件（以.开头的文件）
    location ~ /\\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 禁止访问备份文件
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF"
    
    if [ $? -eq 0 ]; then
        echo "✓ 主配置文件创建成功"
    else
        echo "✗ 主配置文件创建失败"
        exit 1
    fi
fi

# 4.5. 创建符号链接
echo "4.5. 创建符号链接..."
ssh $SERVER_HOST "mkdir -p /var/www/html && rm -rf /var/www/html/showpage && ln -sf $REMOTE_PATH /var/www/html/showpage"

if [ $? -eq 0 ]; then
    echo "✓ 符号链接创建成功 ($REMOTE_PATH -> /var/www/html/showpage)"
else
    echo "✗ 符号链接创建失败"
    exit 1
fi

# 5. 启用网站配置
echo "5. 启用nginx网站配置..."
ssh $SERVER_HOST "ln -sf /etc/nginx/sites-available/case.conf /etc/nginx/sites-enabled/case.conf"

if [ $? -eq 0 ]; then
    echo "✓ nginx配置启用成功"
else
    echo "✗ nginx配置启用失败"
fi

# 6. 测试nginx配置
echo "6. 测试nginx配置..."
ssh $SERVER_HOST "nginx -t"

if [ $? -eq 0 ]; then
    echo "✓ nginx配置测试通过"
else
    echo "✗ nginx配置测试失败"
    exit 1
fi

# 7. 重载nginx
echo "7. 重载nginx服务..."
ssh $SERVER_HOST "systemctl reload nginx"

if [ $? -eq 0 ]; then
    echo "✓ nginx重载成功"
else
    echo "✗ nginx重载失败"
    exit 1
fi

# 8. 创建索引页面
echo "8. 创建索引页面..."
ssh $SERVER_HOST "cat > $REMOTE_PATH/index.html << 'EOF'
<!DOCTYPE html>
<html lang=\"zh-CN\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>ShowPage - HTML页面展示站点</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.1);
        }
        
        .header {
            text-align: center;
            margin-bottom: 40px;
        }
        
        .header h1 {
            font-size: 2.5rem;
            color: #1d1d1f;
            margin-bottom: 10px;
            font-weight: 700;
        }
        
        .header p {
            color: #666;
            font-size: 1.1rem;
        }
        
        .pages-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }
        
        .page-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .page-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
        }
        
        .page-card h3 {
            color: #1d1d1f;
            margin-bottom: 10px;
            font-size: 1.2rem;
        }
        
        .page-card a {
            color: #007aff;
            text-decoration: none;
            font-weight: 500;
        }
        
        .page-card a:hover {
            text-decoration: underline;
        }
        
        .footer {
            text-align: center;
            color: #666;
            font-size: 0.9rem;
        }
        
        .cases-info {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 30px;
            border-left: 4px solid #007aff;
        }
        
        .cases-info h2 {
            color: #1d1d1f;
            margin-bottom: 10px;
        }
        
        .cases-info p {
            color: #666;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <div class=\"container\">
        <div class=\"header\">
            <h1>ShowPage</h1>
            <p>HTML页面展示站点 - 静态案例集合</p>
        </div>
        
        <div class=\"cases-info\">
            <h2>📋 案例说明</h2>
            <p>本站点通过统一的主配置文件管理多个静态HTML案例项目，每个案例通过不同的路径进行访问。当前可用的案例项目：</p>
            <ul style=\"margin-top: 10px; margin-left: 20px;\">
                <li><strong>ShowPage</strong>: /showpage - HTML页面展示案例</li>
                <li><strong>PostEditor</strong>: /postereditor - 海报编辑器案例 (即将添加)</li>
            </ul>
        </div>
        
        <div class=\"pages-grid\" id=\"pagesGrid\">
            <!-- 页面卡片将通过JavaScript动态加载 -->
        </div>
        
        <div class=\"footer\">
            <p>© 2025 ShowPage - 基于nginx主配置文件的静态案例管理系统</p>
        </div>
    </div>
    
    <script>
        // 获取页面列表
        fetch('/showpage/api/pages')
            .then(response => response.json())
            .then(data => {
                const grid = document.getElementById('pagesGrid');
                data.pages.forEach(page => {
                    const card = document.createElement('div');
                    card.className = 'page-card';
                    card.innerHTML = \`
                        <h3>\${page.title}</h3>
                        <a href=\"/showpage/\${page.name}\" target=\"_blank\">查看页面 →</a>
                    \`;
                    grid.appendChild(card);
                });
            })
            .catch(error => {
                console.error('Failed to load pages:', error);
                document.getElementById('pagesGrid').innerHTML = '<p style=\"text-align: center; color: #666;\">加载页面列表失败</p>';
            });
    </script>
</body>
</html>
EOF"

if [ $? -eq 0 ]; then
    echo "✓ 索引页面创建成功"
else
    echo "✗ 索引页面创建失败"
fi

echo "========================================="
echo "部署完成！"
echo ""
echo "访问信息："
echo "• 主页面: http://$DOMAIN/showpage/"
echo "• API接口: http://$DOMAIN/showpage/api/pages"
echo "• 配置文件: /etc/nginx/sites-available/case.conf"
echo ""
echo "架构说明："
echo "• 使用主配置文件 case.conf 管理所有静态案例"
echo "• 通过路径 /showpage 访问 ShowPage 案例"
echo "• 后续案例将添加到同一配置文件中"
echo "=========================================" 