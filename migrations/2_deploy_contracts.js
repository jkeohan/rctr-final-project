var HelloContract = artifacts.require("./HelloContract.sol");

module.exports = function(deployer) {
  deployer.deploy(HelloContract);
};
