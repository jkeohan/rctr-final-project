var assert = require('assert');

const Exchange = artifacts.require("./Exchange.sol");
const Factory = artifacts.require("./Factory.sol");
const SampleToken1 = artifacts.require("./SampleToken1.sol");

contract("Exchange", accounts => {
    let factory;
    let sampleToken1;
    let exchange;
    
    beforeEach('setup contract for each test',  async () => {
        factory = await Factory.new();
        sampleToken1 = await SampleToken1.new("SampleToken1", "TOK1", 100);
        await factory.createExchange(sampleToken1.address);
        exchange = await Exchange.at(await factory.getExchange(sampleToken1.address));
    });

    it("Correct setup", async () => {
        const name = await exchange.name();
        assert.equal(name, "Sandman Swap");

        const symbol = await exchange.symbol();
        assert.equal(symbol, "DREAM");

        const supply = await exchange.totalSupply();
        assert.equal(supply, 0);

        assert.equal(await exchange.factory(), factory.address);
    });

    // TODO: test methods

});