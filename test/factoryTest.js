var assert = require('assert');

const Factory = artifacts.require("./Factory.sol");
const SampleToken1 = artifacts.require("./SampleToken1.sol");

contract("Factory", accounts => {
    let factory;
    let sampleToken1;
    
    beforeEach('Setup contract for each test',  async () => {
        factory = await Factory.new();
        sampleToken1 = await SampleToken1.new("SampleToken1", "TOK1", 100);
    });

    it("Error on zero token address", async () => {
        try {
            await factory.createExchange(0x0);
        } catch (err) {
            assert.ok(err.message);
        }
    });

    it("Create a new exchange and retrieve address", async () => {
        await factory.createExchange(sampleToken1.address); 
        assert.notEqual(await factory.getExchange(sampleToken1.address), 0x0);
    });

    it("Error on duplicate exchange", async () => {
        await factory.createExchange(sampleToken1.address); 

        try {
            await factory.createExchange(sampleToken1.address);
        } catch (err) {
            assert.ok(err.message);
        }
    });

    it("Error on get invalid exchange", async () => {
        try {
            await factory.getExchange(0x1111111111111111111111111111111111111111);
        } catch (err) {
            assert.ok(err.message);
        }
    });
});