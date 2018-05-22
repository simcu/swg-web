function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

-- connect redis
local redis = require "resty.redis"
local redis_host = os.getenv('REDIS_HOST')
local redis_port = os.getenv('REDIS_PORT')
local redis_pass = os.getenv('REDIS_PASS')
local redis_db = os.getenv('REDIS_DB')
if redis_host == nil then
    redis_host = "127.0.0.1"
end
if redis_port == nil then
    redis_port = 6379;
end
if redis_db == nil then
    redis_db = 0;
end
local red = redis:new()
red:set_timeout(1000)
local ok, err = red:connect(redis_host, redis_port)
if not ok then
    ngx.log(ngx.ERR, "[SWG] Connet Redis Server Error: ", err)
    ngx.exit(500)
end

if redis_pass then
    local res, err = red:auth(tostring(redis_pass))
    if not res then
        ngx.log(ngx.ERR, "[SWG] Failed Auth with password: ", err)
        ngx.exit(500)
    end
end
red:select(redis_db);

-- load config
local token_expire = 600
if red:get('swg_gate_expire') ~= ngx.null then
    token_expire = tonumber(red:get('swg_gate_expire'))
end

-- 1 fresh token every request
-- 2 not fresh , token only vaild in token_expire
local auth_mode = 1
if red:get('swg_gate_mode') ~= ngx.null then
    auth_mode = tonumber(red:get('swg_gate_mode'))
end

local auth_url = red:get('swg_gate_url')
if auth_url == ngx.null then
    ngx.log(ngx.ERR, "[SWG] Failed to get config: swg_gate_url")
    ngx.exit(500)
end

-- get full url
local fullurl = ngx.var.scheme .. "://" .. ngx.var.http_host .. ngx.var.request_uri
local fullauthurl = auth_url .. "?ref=" .. encodeURI(fullurl)
-- check hostname
local host, err = red:get("swg_gate_" .. ngx.var.http_host)
if host == ngx.null then
    ngx.exit(404)
end
ngx.var.upstream = host

-- check token
local token = ngx.var.arg_swg_gate_token or ngx.var.cookie_swg_gate_token;
if token ~= nil then
    ngx.header["Set-Cookie"] = "swg_gate_token=" .. token .. "; path=/;"
else
    ngx.redirect(fullauthurl);
end

-- check login
local user, err = red:get("swg_gate_token_" .. token)
if user == ngx.null then
    ngx.redirect(fullauthurl);
end
if auth_mode == 1 then
    red:expire("swg_gate_token_" .. token, token_expire)
end

-- check acl
key = "swg_gate_" .. ngx.var.http_host .. "_" .. user
local acl, err = red:get(key)
if acl == ngx.null then
    ngx.exit(403)
end