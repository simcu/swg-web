#!/usr/bin/env php
<?php
/**
 * Created by IntelliJ IDEA.
 * User: xrain
 * Date: 2018/5/22
 * Time: 12:35
 */
require __DIR__ . '/vendor/autoload.php';

use Symfony\Component\Console\Application;

$main = new \App\Main();
$application = new Application('SWG', '1.0.0');
$application->add($main);
$application->setDefaultCommand($main->getName(), true);
$application->run();