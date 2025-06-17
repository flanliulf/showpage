#!/bin/bash

# 部署脚本 - 将HTML文件上传到远程服务器并配置nginx
# 服务器信息
SERVER_HOST="aliyun-ecs-showpage"  # 使用SSH配置别名
REMOTE_PATH="/usr/share/nginx/html/showpage"
DOMAIN="case.coderboot.xyz"

echo "========================================="
echo "开始部署HTML文件到远程服务器"
echo "服务器: $SERVER_HOST"
echo "目标目录: $REMOTE_PATH"
echo "域名: $DOMAIN"
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
ssh $SERVER_HOST "chmod 644 $REMOTE_PATH/*.html && chown -R root:root $REMOTE_PATH"

if [ $? -eq 0 ]; then
    echo "✓ 文件权限设置成功"
else
    echo "✗ 文件权限设置失败"
fi

# 4. 创建nginx配置文件
echo "4. 创建nginx配置文件..."
ssh $SERVER_HOST "cat > /etc/nginx/sites-available/showpage.conf << 'EOF'
server {
    listen 80;
    server_name $DOMAIN;
    
    # 启用gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # 设置缓存策略
    location ~* \.(html|css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control \"public, immutable\";
    }
    
    # 根路径重定向到 /showpage
    location = / {
        return 301 /showpage/;
    }
    
    # showpage 应用路径
    location /showpage {
        alias $REMOTE_PATH;
        index index.html;
        try_files \$uri \$uri/ =404;
        
        # 设置安全头
        add_header X-Frame-Options \"SAMEORIGIN\" always;
        add_header X-XSS-Protection \"1; mode=block\" always;
        add_header X-Content-Type-Options \"nosniff\" always;
        add_header Referrer-Policy \"no-referrer-when-downgrade\" always;
        add_header Content-Security-Policy \"default-src 'self' http: https: data: blob: 'unsafe-inline'\" always;
    }
    
    # 页面列表接口（返回JSON格式的页面列表）
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
    
    # 错误页面
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    # 日志配置
    access_log /var/log/nginx/$DOMAIN.access.log;
    error_log /var/log/nginx/$DOMAIN.error.log;
}
EOF"

if [ $? -eq 0 ]; then
    echo "✓ nginx配置文件创建成功"
else
    echo "✗ nginx配置文件创建失败"
    exit 1
fi

# 5. 启用网站配置
echo "5. 启用nginx网站配置..."
ssh $SERVER_HOST "ln -sf /etc/nginx/sites-available/showpage.conf /etc/nginx/sites-enabled/showpage.conf"

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
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 25px;
            margin-top: 30px;
        }
        
        .page-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
            border: 1px solid rgba(0, 0, 0, 0.1);
        }
        
        .page-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.15);
        }
        
        .page-card h3 {
            color: #1d1d1f;
            margin-bottom: 10px;
            font-size: 1.3rem;
        }
        
        .page-card p {
            color: #666;
            margin-bottom: 15px;
            line-height: 1.6;
        }
        
        .page-link {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            padding: 12px 24px;
            border-radius: 25px;
            font-weight: 600;
            transition: all 0.3s ease;
        }
        
        .page-link:hover {
            transform: scale(1.05);
            box-shadow: 0 8px 20px rgba(102, 126, 234, 0.4);
        }
        
        .stats {
            text-align: center;
            margin: 40px 0;
            padding: 20px;
            background: rgba(102, 126, 234, 0.1);
            border-radius: 15px;
        }
        
        .stats h2 {
            color: #1d1d1f;
            margin-bottom: 10px;
        }
        
        .stats p {
            color: #666;
            font-size: 1.1rem;
        }
        
        @media (max-width: 768px) {
            .container {
                padding: 20px;
            }
            
            .header h1 {
                font-size: 2rem;
            }
            
            .pages-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class=\"container\">
        <div class=\"header\">
            <h1>ShowPage - HTML页面展示站点</h1>
            <p>浏览和访问项目中的各个HTML页面</p>
        </div>
        
        <div class=\"stats\">
            <h2>页面统计</h2>
            <p>当前共有 <strong>5</strong> 个HTML页面可供浏览</p>
        </div>
        
        <div class=\"pages-grid\">
            <div class=\"page-card\">
                <h3>PromptBase Link Refly v2</h3>
                <p>PromptBase相关的链接重构页面，第二版本设计</p>
                <a href=\"./promptbase-link-refly-guizang-v2-claude4.html\" class=\"page-link\">查看页面</a>
            </div>
            
            <div class=\"page-card\">
                <h3>ArxivLicense Link Refly v2</h3>
                <p>ArxivLicense许可证相关的链接页面，重构版本</p>
                <a href=\"./arxivlicense-link-refly-guizang-v2-claude4.html\" class=\"page-link\">查看页面</a>
            </div>
            
            <div class=\"page-card\">
                <h3>OpenEvals Link Sumbuddy v3</h3>
                <p>OpenEvals评估系统，集成Sumbuddy功能的第三版</p>
                <a href=\"./openevals-link-sumbuddy-refly-guizang-v3-claude4.html\" class=\"page-link\">查看页面</a>
            </div>
            
            <div class=\"page-card\">
                <h3>OpenEvals Link Refly v3</h3>
                <p>OpenEvals评估系统，链接重构的第三版本</p>
                <a href=\"./openevals-link-refly-guizang-v3-claude4.html\" class=\"page-link\">查看页面</a>
            </div>
            
            <div class=\"page-card\">
                <h3>OpenEvals Link Refly v2</h3>
                <p>OpenEvals评估系统，链接重构的第二版本</p>
                <a href=\"./openevals-link-refly-guizang-v2-claude4.html\" class=\"page-link\">查看页面</a>
            </div>
        </div>
    </div>
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
echo "访问地址: http://$DOMAIN/showpage/"
echo "页面列表API: http://$DOMAIN/showpage/api/pages"
echo ""
echo "已部署的页面："
echo "- promptbase-link-refly-guizang-v2-claude4.html"
echo "- arxivlicense-link-refly-guizang-v2-claude4.html"
echo "- openevals-link-sumbuddy-refly-guizang-v3-claude4.html"
echo "- openevals-link-refly-guizang-v3-claude4.html"
echo "- openevals-link-refly-guizang-v2-claude4.html"
echo "=========================================" 