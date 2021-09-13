var assert = require('assert');

const Exchange = artifacts.require("./Exchange.sol");
const Factory = artifacts.require("./Factory.sol");
const SampleToken1 = artifacts.require("./SampleToken1.sol");

const getEthReserve = async (address) => {
    return await web3.eth.getBalance(address);
}

const ethToWei = (eth) => {
    return web3.utils.toWei(eth.toString());
}

const weiToEth = (wei) => {
    return web3.utils.fromWei(wei);
}

contract("Exchange", accounts => {
    let factory;
    let sampleToken1;
    let exchange;
    
    beforeEach('setup contract for each test',  async () => {
        factory = await Factory.new();
        sampleToken1 = await SampleToken1.new("SampleToken1", "TOK1", ethToWei(100));
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

    it("Error add no liquidity", async () => {
        try {
            await exchange.addLiquidity(0, {value: 0});
        } catch (err) {
            assert.ok(err.message);
        }
    });

    it("Add liquidity empty pool", async () => {
        assert.ok(await sampleToken1.approve(exchange.address, ethToWei(20)));

        await exchange.addLiquidity(ethToWei(20), {value: ethToWei(10)});
    
        const lpAmount = weiToEth(await exchange.balanceOf(accounts[0]));
        assert.equal(weiToEth(await exchange.totalSupply()), lpAmount);
        assert.equal(lpAmount, 10);

        const tokenReserves = weiToEth(await exchange.getTokenReserves());
        assert.equal(tokenReserves, 20);

        const ethReserves = weiToEth(await getEthReserve(exchange.address));
        assert.equal(ethReserves, 10);
    });
    
    it("Add liquidity non-empty pool", async () => {
        // tok = 20, eth = 10, lpMint = ethReserve = 10
        assert.ok(await sampleToken1.approve(exchange.address, ethToWei(20)));
        await exchange.addLiquidity(ethToWei(20), {value: ethToWei(10)});

        // lpMint = ethDeposited / ethPool * lpSupply = 5 / 10 * 10 = 5
        assert.ok(await sampleToken1.approve(exchange.address, ethToWei(10)));
        await exchange.addLiquidity(ethToWei(10), {value: ethToWei(5)});

        const lpAmount = weiToEth(await exchange.balanceOf(accounts[0]));
        assert.equal(weiToEth(await exchange.totalSupply()), lpAmount);
        assert.equal(lpAmount, 15);

        const tokenReserves = weiToEth(await exchange.getTokenReserves());
        assert.equal(tokenReserves, 30);

        const ethReserves = weiToEth(await getEthReserve(exchange.address));
        assert.equal(ethReserves, 15);
    });
});