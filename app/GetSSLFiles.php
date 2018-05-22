<?php
/**
 * Created by IntelliJ IDEA.
 * User: xrain
 * Date: 2018/5/22
 * Time: 12:39
 */

namespace App;

use League\Flysystem\Adapter\Local;
use League\Flysystem\Filesystem;

class GetSSLFiles
{
    public static function run($redis, $console)
    {
        $ssls = $redis->keys("swg_ssl_*_name");
        self::_clearFiles();
        foreach ($ssls as $item) {
            $tmp = explode('_', $item);
            $kpart = $tmp[2];
            $name = $redis->get("swg_ssl_${kpart}_name");
            $cert = $redis->get("swg_ssl_${kpart}_cert");
            $key = $redis->get("swg_ssl_${kpart}_key");
            if ($name and $cert and $key) {
                self::_writeFile(["${name}.crt" => $cert, "${name}.key" => $key]);
            }
        }
        $console->log("ssl证书文件更新完成 ....");
    }

    private static function _writeFile($kv)
    {
        $fs = new Filesystem(new Local(__DIR__ . '/../config/ssl/'));
        $respose = true;
        foreach ($kv as $k => $v) {
            if (!$fs->put($k, $v)) {
                $respose = false;
            }
        }
        return $respose;
    }

    private static function _clearFiles()
    {
        $fs = new Filesystem(new Local(__DIR__ . '/../config/'));
        $fs->deleteDir('ssl');
    }
}