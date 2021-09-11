const HelloContract = artifacts.require("./HelloContract.sol");

contract("HelloContract", accounts => {
  it("...should return Hello World!.", async () => {
    const instance = await HelloContract.deployed();

    // Get stored value
    const ret = await instance.get.hello();

    assert.equal(ret, "Hello World!", "Incorrect response.");
  });
});
