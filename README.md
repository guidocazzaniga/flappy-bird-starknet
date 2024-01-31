# A Decentralized Approach to Award Game Achievements - PoC 

## Getting started

In order to use the application, you need to install a browser wallet, either [Argent](https://www.argent.xyz/) or [Braavos](https://braavos.app/). After that, you need to get some test eth from the [Faucet](https://faucet.goerli.starknet.io/) to pay for transactions.

This application uses a pre-deployed instance of the game contract at address 0x67cbff9203c0d1c44816c39f78444d7f13653686cd3d7a1bc63e0a85be8e11b  

## Running the application
In order to run the application, first clone this repository, then install the dependencies with
```bash
cd <path-to-repo>
npm i
```
then run
```bash
npm run dev
```
Now open the browser and go to localhost:3000 to start using the application. 

## Proving game duration
You can start a new game by clicking "Play Game". After the game has ended, click on "Notarize" to notarize on-chain your moves along with an upper bound for game end time (i.e. the timestamp of the current block). After this, you can click on "Send moves to contract" to validate your game and save your score on-chain. Thanks to the data notarized on-chain at the previous step, it's possible to prove that the game run has taken no more than X seconds, since:
- the block hash used to calculate the initial state is stored in the contract, and its timestamp can be used as game start time
- the timestamp of the block in which the notarization transaction has been included is stored directly in the contract, and can be considered the game end time
Therefore, we can determine an upper bound on game duration by subtracting game start time from game end time.
