#!/bin/bash

# 增强版部署脚本 - 自动检测HTML文件并更新nginx配置
# 服务器信息
SERVER_HOST="aliyun-ecs-showpage"  # 使用SSH配置别名
REMOTE_PATH="/root/www/showpage"
DOMAIN="case.coderboot.xyz"

echo "========================================="
echo "开始增强版部署HTML文件到远程服务器"
echo "服务器: $SERVER_HOST"
echo "目标目录: $REMOTE_PATH"
echo "域名: $DOMAIN"
echo "========================================="

# 1. 自动检测本地HTML文件并生成页面列表
echo "1. 检测本地HTML文件..."
HTML_FILES=($(ls *.html 2>/dev/null))

if [ ${#HTML_FILES[@]} -eq 0 ]; then
    echo "✗ 没有发现HTML文件"
    exit 1
fi

echo "发现 ${#HTML_FILES[@]} 个HTML文件:"
for file in "${HTML_FILES[@]}"; do
    echo "  - $file"
done

# 2. 生成JSON格式的页面列表
echo "2. 生成页面列表JSON..."
JSON_PAGES=""
for i in "${!HTML_FILES[@]}"; do
    file="${HTML_FILES[$i]}"
    # 从HTML文件中提取title（简单方法）
    title=$(grep -o '<title>[^<]*</title>' "$file" 2>/dev/null | sed 's/<title>\(.*\)<\/title>/\1/' | head -1)
    if [ -z "$title" ]; then
        # 如果没有找到title，使用文件名生成标题
        title=$(echo "$file" | sed 's/\.html$//' | sed 's/-/ /g' | sed 's/\b\w/\U&/g')
    fi
    
    # 转义JSON特殊字符
    title=$(echo "$title" | sed 's/"/\\"/g')
    
    if [ $i -eq 0 ]; then
        JSON_PAGES="                {\"name\": \"$file\", \"title\": \"$title\"}"
    else
        JSON_PAGES="$JSON_PAGES,\n                {\"name\": \"$file\", \"title\": \"$title\"}"
    fi
done

echo "✓ 页面列表JSON生成完成"

# 3. 创建远程目录
echo "3. 创建远程目录..."
ssh $SERVER_HOST "mkdir -p $REMOTE_PATH"

if [ $? -eq 0 ]; then
    echo "✓ 远程目录创建成功"
else
    echo "✗ 远程目录创建失败"
    exit 1
fi

# 4. 上传HTML文件
echo "4. 上传HTML文件..."
scp *.html $SERVER_HOST:$REMOTE_PATH/

if [ $? -eq 0 ]; then
    echo "✓ HTML文件上传成功"
else
    echo "✗ HTML文件上传失败"
    exit 1
fi

# 5. 设置文件权限
echo "5. 设置文件权限..."
ssh $SERVER_HOST "chmod 644 $REMOTE_PATH/*.html && chown -R root:root $REMOTE_PATH && chmod 755 /root /root/www && chmod 755 $REMOTE_PATH"

if [ $? -eq 0 ]; then
    echo "✓ 文件权限设置成功"
else
    echo "✗ 文件权限设置失败"
fi

# 6. 动态生成nginx配置文件
echo "6. 生成更新的nginx配置文件..."
cat > /tmp/case.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/html;
    
    # ========== 压缩和性能优化 ==========
    # 启用gzip压缩，提升传输效率
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # ========== 路由配置 ==========
    # 根路径重定向到主要案例 /showpage
    location = / {
        return 301 /showpage/;
    }
    
    # ========== ShowPage 案例 ==========
    # showpage HTML页面展示案例
    # 文件实际路径: $REMOTE_PATH (通过符号链接映射)
    # 访问地址: http://$DOMAIN/showpage/
    # 重要：需要先创建符号链接 ln -sf $REMOTE_PATH /var/www/html/showpage
    location /showpage {
        # 使用root + try_files的方式，避免nginx alias配置的坑
        try_files \$uri \$uri/ \$uri/index.html =404;
        
        # 安全头部配置，防止XSS、点击劫持等攻击
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'; style-src 'self' 'unsafe-inline' https://lf3-cdn-tos.bytecdntp.com https://lf6-cdn-tos.bytecdntp.com https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com https://lf6-cdn-tos.bytecdntp.com; script-src 'self' 'unsafe-inline' https://lf3-cdn-tos.bytecdntp.com;" always;
    }
    
    # showpage 页面列表API接口
    # 返回当前可用的HTML页面列表（JSON格式）
    # 访问地址: http://$DOMAIN/showpage/api/pages
    location /showpage/api/pages {
        default_type application/json;
        return 200 '{
            "pages": [
$(echo -e "$JSON_PAGES")
            ]
        }';
    }
    
    # ========== 缓存策略 ==========
    # 静态资源缓存（图片、CSS、JS等）
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # HTML文件不缓存，确保内容更新能及时生效
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate";
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
EOF

echo "✓ nginx配置文件生成成功"

# 7. 上传并更新nginx配置
echo "7. 上传nginx配置文件..."
scp /tmp/case.conf $SERVER_HOST:/etc/nginx/sites-available/case.conf

if [ $? -eq 0 ]; then
    echo "✓ nginx配置文件上传成功"
else
    echo "✗ nginx配置文件上传失败"
    exit 1
fi

# 8. 创建符号链接
echo "8. 创建符号链接..."
ssh $SERVER_HOST "mkdir -p /var/www/html && rm -rf /var/www/html/showpage && ln -sf $REMOTE_PATH /var/www/html/showpage"

if [ $? -eq 0 ]; then
    echo "✓ 符号链接创建成功 ($REMOTE_PATH -> /var/www/html/showpage)"
else
    echo "✗ 符号链接创建失败"
    exit 1
fi

# 9. 启用网站配置
echo "9. 启用nginx网站配置..."
ssh $SERVER_HOST "ln -sf /etc/nginx/sites-available/case.conf /etc/nginx/sites-enabled/case.conf"

if [ $? -eq 0 ]; then
    echo "✓ nginx配置启用成功"
else
    echo "✗ nginx配置启用失败"
fi

# 10. 测试nginx配置
echo "10. 测试nginx配置..."
ssh $SERVER_HOST "nginx -t"

if [ $? -eq 0 ]; then
    echo "✓ nginx配置测试通过"
else
    echo "✗ nginx配置测试失败"
    exit 1
fi

# 11. 重载nginx
echo "11. 重载nginx服务..."
ssh $SERVER_HOST "systemctl reload nginx"

if [ $? -eq 0 ]; then
    echo "✓ nginx重载成功"
else
    echo "✗ nginx重载失败"
    exit 1
fi

# 12. 生成动态索引页面
echo "12. 生成动态索引页面..."
INDEX_HTML=""
for file in "${HTML_FILES[@]}"; do
    title=$(grep -o '<title>[^<]*</title>' "$file" 2>/dev/null | sed 's/<title>\(.*\)<\/title>/\1/' | head -1)
    if [ -z "$title" ]; then
        title=$(echo "$file" | sed 's/\.html$//' | sed 's/-/ /g' | sed 's/\b\w/\U&/g')
    fi
    INDEX_HTML="$INDEX_HTML                <li><a href=\"$file\" class=\"page-link\">$title</a></li>\n"
done

ssh $SERVER_HOST "cat > $REMOTE_PATH/index.html << 'EOF'
<!DOCTYPE html>
<html lang=\"zh-CN\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>ShowPage - 静态网页案例展示</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; }
        .container { background: rgba(255,255,255,0.95); padding: 2rem; border-radius: 15px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); max-width: 600px; width: 90%; }
        h1 { color: #333; text-align: center; margin-bottom: 1.5rem; font-size: 2rem; }
        .subtitle { text-align: center; color: #666; margin-bottom: 2rem; }
        ul { list-style: none; }
        li { margin: 0.8rem 0; }
        .page-link { display: block; padding: 1rem; background: #f8f9fa; border-radius: 8px; text-decoration: none; color: #333; transition: all 0.3s ease; border-left: 4px solid #667eea; }
        .page-link:hover { background: #e9ecef; transform: translateX(5px); box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
        .api-info { margin-top: 2rem; padding: 1rem; background: #e3f2fd; border-radius: 8px; font-size: 0.9rem; color: #1976d2; }
        .footer { text-align: center; margin-top: 2rem; color: #666; font-size: 0.8rem; }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1>📄 ShowPage</h1>
        <p class=\"subtitle\">静态网页案例展示平台</p>
        <ul>
$(echo -e "$INDEX_HTML")        </ul>
        <div class=\"api-info\">
            <strong>API接口:</strong> <a href=\"/showpage/api/pages\">/showpage/api/pages</a><br>
            <strong>访问统计:</strong> 共 ${#HTML_FILES[@]} 个页面
        </div>
        <div class=\"footer\">
            © 2024 ShowPage | 最后更新: $(date '+%Y-%m-%d %H:%M:%S')
        </div>
    </div>
</body>
</html>
EOF"

if [ $? -eq 0 ]; then
    echo "✓ 动态索引页面生成成功"
else
    echo "✗ 动态索引页面生成失败"
fi

# 13. 清理临时文件
rm -f /tmp/case.conf

echo "========================================="
echo "增强版部署完成！"
echo ""
echo "访问信息："
echo "• 主页面: http://$DOMAIN/showpage/"
echo "• API接口: http://$DOMAIN/showpage/api/pages"
echo "• 配置文件: /etc/nginx/sites-available/case.conf"
echo ""
echo "部署的页面列表："
for file in "${HTML_FILES[@]}"; do
    echo "• http://$DOMAIN/showpage/$file"
done
echo ""
echo "架构说明："
echo "• 自动检测本地HTML文件并生成页面列表"
echo "• 动态更新nginx配置文件"
echo "• 自动生成美观的索引页面"
echo "• 完整的权限和安全配置"
echo "=========================================" 