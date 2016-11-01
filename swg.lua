-- load config
local redis_host = os.getenv('REDIS_HOST')
local redis_port = os.getenv('REDIS_PORT') or 6379
local auth_url = os.getenv('AUTH_URL')
if redis_host == nil then
    ngx.log(ngx.ERR, "failed to get config : redis_host , please set env REDIS_HOST")
    ngx.exit(500)
end
if auth_url == nil then
    ngx.log(ngx.ERR, "failed to get config : auth_url , please set env AUTH_URL")
    ngx.exit(500)
end

-- connect redis
local redis = require "resty.redis"
local red = redis:new()
red:set_timeout(1000)
local ok, err = red:connect(redis_host, redis_port)
if not ok then
    ngx.log(ngx.ERR, "failed to connect redis server: ", err)
    ngx.exit(500)
end

-- check hostname
local host, err = red:get(ngx.var.http_host)
if host == ngx.null then
    ngx.exit(404)
end
ngx.var.upstream = host

-- check token
local token = ngx.var.arg_swg_token or ngx.var.cookie_swg_token;
if token ~= nil then
    local expires = ngx.cookie_time(math.ceil(ngx.now()) + 600)
    ngx.header["Set-Cookie"] = "swg_token=" .. token .. "; expires=" .. expires .. ";"
else
    ngx.redirect(auth_url);
end

-- check login
local user, err = red:get("user_token_" .. token)
if user == ngx.null then
    ngx.redirect(auth_url);
end


-- check acl
key = "user_" .. user .. "_host_" .. ngx.var.http_host
local acl, err = red:get(key)
if acl == ngx.null then
    ngx.exit(403)
end
