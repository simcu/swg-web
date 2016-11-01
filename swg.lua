-- connect redis
local redis = require "resty.redis"
local redis_host = os.getenv('REDIS_HOST')
local redis_port = os.getenv('REDIS_PORT')
local redis_pass = os.getenv('REDIS_PASS')
if redis_host == nil then
    ngx.log(ngx.ERR, "failed to get config , please set env REDIS_HOST")
    ngx.exit(500)
end
local red = redis:new()
red:set_timeout(1000)
local ok, err = red:connect(redis_host, redis_port)
if not ok then
    ngx.log(ngx.ERR, "failed to connect redis server: ", err)
    ngx.exit(500)
end

if redis_pass then
    local res, err = red:auth(tostring(redis_pass))
    if not res then
        ngx.log(ngx.ERR, "failed to auth config , please check env REDIS_PASS .", err)
        ngx.exit(500)
    end
end

-- load config
local token_expire = 600
if red:get('config_token_expire') ~= ngx.null then
    token_expire = tonumber(red:get('config_token_expire'))
end

-- 1 fresh token every request
-- 2 not fresh , token only vaild in token_expire
local auth_mode = 1
if red:get('config_token_mode') ~= ngx.null then
    auth_mode = tonumber(red:get('config_token_mode'))
end

local auth_url = red:get('config_token_url')
if auth_url == ngx.null then
    ngx.log(ngx.ERR, "failed to get redis config field: config_token_url")
    ngx.exit(500)
end

-- get full url
local fullurl = ngx.var.scheme .. "://" .. ngx.var.http_host .. ngx.var.request_uri
local fullauthurl = auth_url .. "?ref=" .. fullurl
-- check hostname
local host, err = red:get("host_" .. ngx.var.http_host)
if host == ngx.null then
    ngx.exit(404)
end
ngx.var.upstream = host

-- check token
local token = ngx.var.arg_swg_token or ngx.var.cookie_swg_token;
if token ~= nil then
    ngx.header["Set-Cookie"] = "swg_token=" .. token .. "; path=/;"
else
    ngx.redirect(fullauthurl);
end

-- check login
local user, err = red:get("token_" .. token)
if user == ngx.null then
    ngx.redirect(fullauthurl);
end
if auth_mode == 1 then
    red:expire("token_" .. token, token_expire)
end

-- check acl
key = "acl_" .. user .. "_" .. ngx.var.http_host
local acl, err = red:get(key)
if acl == ngx.null then
    ngx.exit(403)
end