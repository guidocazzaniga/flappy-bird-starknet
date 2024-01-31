import { useAccount, useProvider } from '@starknet-react/core'
import type { NextPage } from 'next'
import { ConnectWallet } from '~/components/ConnectWallet'
import Game from '~/components/Game'
import { SendMoves } from '~/components/SendMoves'
import { useGameContract } from '~/hooks/gameContract'
import * as starknet from 'starknet';
import React, { useState, useEffect } from 'react';
import { Notarize } from '~/components/Notarize'

class InitState {
  pipeHeights: number[];
  startHash: string;

  constructor(pipeHeights: number[], startHash: any) {
    this.pipeHeights = pipeHeights;
    this.startHash = startHash;
  }
}

const Home: NextPage = () => {
  const { account } = useAccount();
  const {provider} = useProvider();
  const { contract: gameContract } = useGameContract()
  var contractInitState: any;
  const [initState, setInitState] = useState<InitState>();

  const [moves, setMoves] = useState<Array<number>>([]);
  const [lastTx, setLastTx] = useState('');

  const getInitStateFromContract = async (gameContract: starknet.Contract, account: any) => {
    const block = await provider.getBlock('latest')
    const contractInitState = await gameContract.call('showInitState', [account.address, block.block_hash])
    return { state: contractInitState, blockhash: block.block_hash }
  }

  const getTxLink = () => {
    if (lastTx != '') {
      const link = `https://testnet.starkscan.co/tx/${lastTx}`
      return <a className='ext-blue-600 dark:text-blue-500 hover:underline' target='_blank' rel="noreferrer" href={link}>{lastTx.slice(0, 15)}...</a>
    } else {
      return '-'
    }
  }

  const setup = async () => {
    if (gameContract && account) {
      let contractState = await getInitStateFromContract(gameContract, account)
      contractInitState = contractState.state
      if (contractInitState) {
        let pipeHeights = contractInitState.pipesOffset.map((el: any) => Number(el))
        let initState = new InitState(pipeHeights, contractState.blockhash)
        console.log("yo: " + pipeHeights)
        setInitState(initState)
      }
    }
  }

  useEffect(() => {
    setup()
  }, [account, contractInitState])


  const setMovesCallback = (move: number) => {
    if (move == undefined)
      setMoves([]);
    else
      setMoves(list => [...list, move]);
  }

  if (initState && account) {
    return (
      <div>
        <div style={{ width: '100%', padding: '1.2rem', display: 'flex', justifyContent: 'end' }}>
          <ConnectWallet />
        </div>
        <div className="grid grid-cols-3 gap-3">
          <div style={{ paddingLeft: '1.2rem', overflowX: 'auto' }}>
            <h1>{moves.length} moves:</h1>
            <p id="movesText">{moves.join(",")}</p>
            <p>Contract: {gameContract?.address}</p>
            <p style={{ marginBottom: '.2rem' }}>StartHash: {initState.startHash}</p>
            <Notarize moves={moves} startHash={initState.startHash} setLastTx={setLastTx} />
            <SendMoves moves={moves} startHash={initState.startHash} setLastTx={setLastTx} />
          </div>
          <div><Game pipeHeights={initState.pipeHeights} callback={setMovesCallback} /></div>
          <div style={{ paddingRight: '1.2rem', overflowX: 'auto' }}><p>Last Tx: {getTxLink()}</p></div>

        </div>
      </div>
    )
  }
  else {
    if (!account)
      return (
        <div style={{ width: '100%', padding: '1.2rem', display: 'flex', justifyContent: 'end' }}>
          <ConnectWallet />
        </div>
      )
    else
      return (
        <div style={{ width: '100%', padding: '1.2rem', display: 'flex', justifyContent: 'end' }}>
          <h2>Loading</h2>
        </div>
      )
  }

}

export default Home


