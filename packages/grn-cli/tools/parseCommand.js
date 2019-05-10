'use strict';

const optimistModule = require('optimist');
// const minimistModule = require('minimist');
function parseCommandLine(config, args) {
  let optimist = new optimistModule();
  args = args || process.argv;
  console.log(args)
  // optimist default API requires you to write the command name three time
  // This is a small wrapper to accept an object instead
  for (let i = 0; i < config.length; ++i) {
    if (config[i].type === 'string') {
      optimist.string(config[i].command);
    } else {
      optimist.boolean(config[i].command);
    }

    optimist
      .default(config[i].command, config[i].default)
      .describe(config[i].command, config[i].description);

    if (config[i].required) {
      optimist.demand(config[i].command);
    }
  }
  let argv = optimist.parse(args);

  // optimist doesn't have support for --dev=false, instead it returns 'false'
  for (let i = 0; i < config.length; ++i) {
    let command = config[i].command;
    if (argv[command] === undefined) {
      argv[command] = config[i].default;
    }
    if (argv[command] === 'true') {
      argv[command] = true;
    }
    if (argv[command] === 'false') {
      argv[command] = false;
    }
    if (config[i].type === 'string') {
      // According to https://github.com/substack/node-optimist#numbers,
      // every argument that looks like a number should be converted to one.
      // var strValue = argv[command];
      // var numValue = strValue ? Number(strValue) : undefined;
      // if (typeof numValue === 'number' && !isNaN(numValue)) {
      //   argv[command] = numValue;
      // }
    }
  }

  return argv;
}

module.exports = parseCommandLine;
