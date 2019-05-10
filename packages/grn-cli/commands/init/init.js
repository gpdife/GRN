/**
 * 初始化命令
 * @module init
 */
const fs = require('fs');
const fss = require('fs-extra');
const path = require('path');
const Promise = require("promise");
const inquirer = require('inquirer');
const chalk = require('chalk');
const spawnSync = require('child_process').spawnSync;
const logOutput = require('../../tools/logOutput');
const printHelp = require("../../tools/printHelp");


/**
 * 入口函数
 * @name init
 */
function init() {
	return new Promise(resolve => {
		let args = process.argv.slice(2);
		let projectName = args[1];
		
		if (args.length < 2 || args[1] == '--help' || args[1] == '-h' || args[1] == '-H') {
			printHelp('init');
			resolve();
			return;
		}

		validateProjectName(projectName)
		let projectPath = path.resolve(projectName);
		if (fs.existsSync(projectPath)) {
			logOutput.warn('project name is already exist');
			// 如果已存在改模块，提问开发者是否覆盖该模块
			inquirer.prompt([
				{
					name: 'merge',
					type: 'confirm',
					message: `Project named ${projectName} is already existed, are you sure to overwrite?`,
					default: false,
					validate: function (input) {
						if (input.lowerCase !== 'y' && input.lowerCase !== 'n') {
							return 'Please input y/n !'
						}
						else {
							return true;
						}
					}
				}
			])
			.then(answers => {
				// 如果确定覆盖
				if (answers['merge']) {
					create(projectPath, projectName)
				}
			})
			.catch(err => {
				logOutput.log(chalk.red(err));
			})
			resolve();
		} 
		else {
			fs.mkdirSync(projectPath);
			create(projectPath, projectName)
			resolve();
		}
	});
}

function validateProjectName(name) {
	if (!name) {
		logOutput.error('init requires a project name.');
		printHelp('init');
		process.exit(1);
	}
  if (!String(name).match(/^[$A-Z_][0-9A-Z_$]*$/i)) {
    logOutput.error(
      '"%s" is not a valid name for a project. Please use a valid identifier ' +
        'name (alphanumeric).',
      name,
		);
		printHelp('init');
    process.exit(1);
  }

  if (name === 'React') {
    logOutput.error(
      '"%s" is not a valid name for a project. Please do not use the ' +
        'reserved word "React".',
      name,
		);
		printHelp('init');
    process.exit(1);
  }
}

function create(projectPath, projectName) {
	logOutput.log('begin init...');
	fss.copySync(path.resolve(__dirname, './template'), projectPath)
	process.chdir(projectPath);
	logOutput.log('create package.json');
	createPackageJSON(projectName);
	logOutput.log('create app.json');
	createAppJSON(projectName);
	logOutput.log('install dependencies');
	installDependencies('16.8.3', '0.59.0');
	logOutput.log('end init...');
}

function createPackageJSON(projectName = 'GRNDemo') {
	const packageJson = {
		name: projectName,
		version: '0.0.1',
		private: true,
		scripts: {
			start: 'grn-cli start',
			android: 'grn-cli run-android',
			ios: 'grn-cli run-ios',
			pack:'grn-cli pack'
		},
		packConfig:{
			entryFile:'index.js',
			bundleOutput:'publish',
			packageName:'GRNDemo',
			dev:false
		}
	};
	fs.writeFileSync(path.resolve('package.json'), JSON.stringify(packageJson, null, 2));
}

function createAppJSON(projectName = 'GRNDemo') {
	var appJSON = {
		"name": projectName,
		"displayName": projectName
	};
	fs.writeFileSync(path.resolve('app.json'), JSON.stringify(appJSON, null, 2));
}

function installDependencies(reactVersion, rnVersion) {
	try {
		var params = [
			'install',
			'--save',
			'--save-exact',
			`react@${reactVersion}`,
			`react-native@${rnVersion}`,
			'@react-native-community/cli@1.4.5',//固定cli,metro版本
			"metro@0.51.0",
			"metro-config@0.51.0",
			"metro-core@0.51.0",
			"metro-memory-fs@0.51.0",
			"metro-react-native-babel-transformer@0.51.0"
		];
		var npmCmd = /^win/.test(process.platform) ? 'npm.cmd' : 'npm';

		logOutput.log(npmCmd + ' ' + params.join(' '));
		var result = spawnSync(npmCmd, params, { stdio: 'inherit' });
		if (result && result.error) {
			throw result.error;
		}
		params = [
			'install',
			'-D',
			'@babel/core',
			'@babel/runtime',
			'metro-react-native-babel-preset'
		];
		logOutput.log(npmCmd + ' ' + params.join(' '));
		result = spawnSync(npmCmd, params, { stdio: 'inherit' });
		if (result && result.error) {
			throw result.error;
		}
	} catch (error) {
		logOutput.error('install dependencies error');
		if (error) {
			logOutput.error(error.stack || error.message);
		}
		process.exit(1);
	}
}

module.exports = init;
