var HelloContract = artifacts.require("./HelloContract.sol");
var Exchange = artifacts.require("./Exchange.sol");
var Factory = artifacts.require("./Factory.sol");
var SampleToken1 = artifacts.require("./SampleToken1.sol");
var SampleToken2 = artifacts.require("./SampleToken2.sol");

module.exports = function (deployer) {
  deployer.deploy(HelloContract);
  deployer.deploy(Exchange);
  deployer.deploy(Factory);
  deployer.deploy(SampleToken1, "SampleToken1", "TOK1", 100);
  deployer.deploy(SampleToken2, "SampleToken2", "TOK2", 100);
};
