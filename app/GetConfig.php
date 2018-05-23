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
        $sites = $redis->get('swg_web_config');
        $fs->put('auto.conf', $sites);
        $console->log("配置文件更新完成 ....");
    }

    public static function init()
    {
        $fs = new Filesystem(new Local(__DIR__ . '/../config/'));
        $fs->put('auto.conf', '');
    }

}