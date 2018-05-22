## ENV 配置项

1. REDIS_HOST
2. REDIS_PORT  默认 6379
3. REDIS_PASS  不填写为无密码

## REDIS 动态配置

1. swg_gate_url  获取token的地址
2. swg_gate_mode 1 为每次请求刷新 2 不刷新 (默认为 1)
3. swg_gate_expire token过期时间 默认600


## REDIS 规则配置

### 版本

> version
推荐为时间戳,或其他不相等的字符串,系统根据version的变更确认是否重新加载配置

### 用户信息

> swg_gate_token_{token} 

值为用户唯一标识符，一般为ID


### 域名配置

> swg_gate_{domain}

值为内部 proxy_pass 地址

### ACL 配置

> swg_gate_{domain}_{uid}

理论可以为任何值，只检测key


##  TOKEN 回调

当用户无登录状态时，系统会跳转到 swg_gate_url ，认证系统完成认证后，
附带 swg_gate_token 参数跳转回相关页面即可完成登录

## HTTP/HTTPS常规代理

## 证书同步

证书同步使用redis三个字段实现:

1. swg_ssl_{id}_name
    证书的名称
    
2. swg_ssl_{id}_cert
    证书的crt部分
    
3. swg_ssl_{id}_key
    证书的 key
    
只有三个元素同时存在时,系统将读取并写入 ssl 文件夹

## 配置文件同步

1. swg_web_upstream
    用于存放各种upstream的配置文件,网关同样需要本字段.
    
2. swg_web_config
    用于存放生成的最终nginx配置文件
    
系统会将内容同步到文件,并重新加载nginx配置