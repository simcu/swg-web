## ENV 配置项

1. REDIS_HOST
2. REDIS_PORT  默认 6379
3. REDIS_PASS  不填写为无密码

## REDIS 动态配置

1. config_token_url  获取token的地址
2. config_token_mode 1 为每次请求刷新 2 不刷新 (默认为 1)
3. config_token_expire token过期时间 默认600


## REDIS 规则配置

### 用户信息

> user_{token} 

值为用户唯一标识符，一般为ID


### 域名配置

> host_{domain}

值为内部 proxy_pass 地址

### ACL 配置

> acl_{user}_{host}

理论可以为任何值，只检测key


##  TOKEN 回调

当用户无登录状态时，系统会跳转到 config_token_url ，认证系统完成认证后，
附带 swg_token 参数跳转回相关页面即可完成登录