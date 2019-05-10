/**
 * 打印grn-cli版本
 * @module printVersion
 */
const Promise = require("promise");
const packageJson= require("./../package.json");


 /**
 * 打印grn-cli版本
 * @returns {promise} 
 */
function printVersion() {
  console.log(`${packageJson.version}`);
  return Promise.resolve();
}
module.exports=printVersion;
