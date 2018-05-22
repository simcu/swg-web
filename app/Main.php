<?php
/**
 * Created by IntelliJ IDEA.
 * User: xrain
 * Date: 2018/5/22
 * Time: 12:47
 */

namespace App;

use Predis\Client;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Process\Process;

class Main extends Command
{

    private $_redis;
    private $_console;
    private $_version = -1;
    private $_nginx;

    protected function configure()
    {
        $this->setName("run")->setDescription("运行SWG代理");
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $this->_console = $output;
        $this->log("初始化SWG ...");
        GetConfig::init();
        $this->_connectRedis();
        $this->log("启动Nginx服务 ...");
        $this->_runNginx();
        $this->log("初始化完成,等待新更新 ...");
        while (true) {
            $this->_checkRedis();
            $this->_checkNginx();
            $rv = $this->_redis->get('swg_version');
            if ($rv != $this->_version) {
                $this->log("发现新更新,版本号: $rv");
                GetSSLFiles::run($this->_redis, $this);
                GetConfig::run($this->_redis, $this);
                if ($this->_checkNginxConfig()) {
                    $this->log("配置文件检测通过,开始加载配置 .... ");
                    if ($this->_reloadNginx()) {
                        $this->log("Nginx配置加载成功 .... ");
                    } else {
                        $this->log("Nginx配置加载失败 .... ", "ERROR");
                    }
                } else {
                    $this->log("配置文件检测失败 .... ", "ERROR");
                }
                $this->_version = $rv;
            }
            sleep(3);
        }
    }

    private function _connectRedis()
    {
        $config = [
            'schema' => 'tcp',
            'host' => $this->_env('REDIS_HOST', '127.0.0.1'),
            'port' => $this->_env('REDIS_PORT', 6379),
            'database' => $this->_env('REDIS_DB', 0)
        ];
        if ($this->_env('REDIS_PASS', false)) {
            $config['password'] = $this->_env('REDIS_PASS');
        }
        $this->_redis = new Client($config);
        $this->log("开始连接Redis ...");
        $this->_redis->connect();
        $this->log("连接Redis成功 ...");
    }

    private function _checkRedis()
    {
        if (!$this->_redis or !$this->_redis->isConnected()) {
            $this->log("Redis连接断开,开始重连...");
            $this->_connectRedis();
        }
    }

    public function log($str, $type = "INFO")
    {
        $formatter = $this->getHelper('formatter');
        $result = $formatter->formatSection(
            date('Y-m-d H:i:s') . ' ' . $type,
            $str
        );
        $this->_console->writeln($result);
    }

    private function _arrGet(array $arr, $key, $default = null)
    {
        return isset($arr[$key]) ? $arr[$key] : $default;
    }

    private function _env($key, $default = null)
    {
        return $this->_arrGet(getenv(), $key, $default);
    }

    private function _checkNginxConfig()
    {
        $process = new Process(["/usr/local/openresty/bin/openresty", "-c", "/home/config/default.conf", "-t"]);
        $process->run();
        return $process->isSuccessful();
    }

    private function _checkNginx()
    {
        if (!$this->_nginx->isRunning()) {
            $this->log("Nginx服务异常,重启中...");
            $this->_runNginx();
        }
    }

    private function _runNginx()
    {
        $process = new Process(["/usr/local/openresty/bin/openresty", "-c", "/home/config/default.conf"]);
        $process->start();
        $this->_nginx = $process;
    }

    private function _reloadNginx()
    {
        $process = new Process(["/usr/local/openresty/bin/openresty", "-c", "/home/config/default.conf", "-s", "reload"]);
        $process->run();
        return $process->isSuccessful();
    }
}