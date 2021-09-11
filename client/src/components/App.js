import React, {useState, useEffect } from "react";
import HelloContract from "../contracts/HelloContract.json";
import getWeb3 from "../getWeb3";

import "./App.css";

const App = () => {
  const [state, setState] = useState(
    { msg: "", web3: null, accounts: null, contract: null }
  );

  const loadDapp = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();

      // Get the contract instance.
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = HelloContract.networks[networkId];
      const instance = new web3.eth.Contract(
        HelloContract.abi,
        deployedNetwork && deployedNetwork.address,
      );

      let ret = await instance.methods.hello().call();

      setState({ msg: ret, web3: web3, accounts: accounts, contract: instance });
    } catch (error) {
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };

  useEffect(() => {
    loadDapp();
  }, []);

  if (!state.web3) {
    return <div>Loading Web3, accounts, and contract...</div>;
  }

  return (
    <div className="App">
      <h1>Test React DApp</h1>
      <h2>Hello Contract Test</h2>
      <div>Message: {state.msg}</div>
    </div>
  );
};

export default App;
