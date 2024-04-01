# This is the code repository for CREDIT: A Credible Trust Framework for Dynamic Mobile Data Pricing Enforcement
# CREDIT Smart Contracts

This repository contains two Solidity smart contract files: `CREDITAuditorSC.sol` and `CREDITNetworkSC.sol`. 
These contracts interact with each other based on the interface that calls a particular function  and accesses its variables.

## CREDITAuditorSC.sol 

`AuditorPool` is a smart contract that deals with the auditor committee selection  and payoff. 

## CREDITNetworkSC.sol

`NetworkSLA` is a smart contract that deals with the generation of Network Service agreement between the Mobile Network Operator (MNO) and the user.

## How to Compile and Run in Remix IDE

To compile and run these smart contracts in Remix IDE, follow these steps:

1. **Open Remix IDE**: Go to https://remix.ethereum.org/ to open Remix IDE in your web browser.

2. Import the `CREDITAuditorSC.sol` and `CREDITNetworkSC.sol`.

3. **Compile Contracts**: In Remix IDE, go to the Solidity Compiler tab on the left sidebar. Select the version of Solidity for both contracts and click the "Compile" button to compile them. The compiler version must be compatible with the code.

4. **Deploy Contracts**: Go to the Deploy & Run Transactions tab on the left sidebar. Select the Smart Contract from the dropdown menu. Click on the "Deploy" button to deploy it to the Ethereum Virtual Machine (EVM). 

5. **Interact with Contracts**: Once deployed, you can interact with Smart Contracts using the provided interface in Remix IDE. Different accounts must be chosen as MNO, user, and auditors and the appropriate interface must be carefully chosen to run a function.

6. **Run Transactions**: In Remix IDE, you can run transactions to call functions from both the Smart Contracts and see the results of those interactions. The balance for different accounts, the updated value of different variable, and the gas consumption can be observed interactively. 

By following these steps, you can compile and run the provided Solidity smart contracts in Remix IDE, allowing you to interact with them on the Ethereum blockchain.

For testing in one of the Testnets, **MetaMask** Plugin  (https://metamask.io/) can be installed. The Testnet of choice can be selected from the MetaMask and linked to the Smart contracts in Ethereum IDE. Similar to the local deployment, multiple accounts must be created for MNO, user and multiple auditor and test Ethers can be fetched using available public faucets. 
