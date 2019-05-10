/**
 * 日志输出
 * @module logOutput
 */
'use strict';
const chalk = require('chalk');

/**
 * 输出错误日志
 */
function error() {
	const message = Array.prototype.slice.call(arguments).join(' ');
	if (message) {
		console.log(chalk.red("[grn-cli error]: " + message));
	}
}

/**
 * 输出警告日志
 */
function warn() {
	const message = Array.prototype.slice.call(arguments).join(' ');
	if (message) {
		console.log(chalk.yellow("[grn-cli warn]: " + message));
	}
}

/**
 * 输出普通日志
 */
function log() {
	const message = Array.prototype.slice.call(arguments).join(' ');
	if (message) {
		console.log("[grn-cli]: " + message);
	}
}

module.exports = {
	error,
	warn,
	log
};