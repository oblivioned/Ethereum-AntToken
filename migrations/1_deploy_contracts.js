const ERC20TokenImpl = artifacts.require("ERC20TokenImpl");

module.exports = function(deployer)
{
  deployer.deploy(ERC20TokenImpl, "0xca35b7d915458ef540ade6068dfe2f44e8fa733c");
};
