<?php
/**
 * Created by IntelliJ IDEA.
 * User: xrain
 * Date: 2018/5/22
 * Time: 16:00
 */

namespace App;

use League\Flysystem\Adapter\Local;
use League\Flysystem\Filesystem;

class GetConfig
{
    public static function run($redis, $console)
    {
        $fs = new Filesystem(new Local(__DIR__ . '/../config/'));
        $ups = $redis->get('swg_web_upstream');
        $fs->put('upstreams.conf', $ups);
        $console->log("upstream 配置更新完成 ....");
        $sites = $redis->get('swg_web_config');
        $fs->put('sites.conf', $sites);
        $console->log("websites 配置更新完成 ....");
    }

    public static function init()
    {
        $fs = new Filesystem(new Local(__DIR__ . '/../config/'));
        $fs->put('upstreams.conf', '');
        $fs->put('sites.conf', '');
    }

}