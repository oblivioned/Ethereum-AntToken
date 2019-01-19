const ConvertLib = artifacts.require("ConvertLib");
const MetaCoin = artifacts.require("MetaCoin");

const PALToken = artifacts.require("ERC20TokenImpl");

module.exports = function(deployer) {
  deployer.deploy(PALToken);
};
