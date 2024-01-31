import { useAccount, useContractWrite, useProvider, useWaitForTransaction } from '@starknet-react/core'
import * as starknet from 'starknet'
import React, { useEffect, useMemo } from 'react';
import { useGameContract } from '~/hooks/gameContract'

interface FlappyProps {
  moves: number[],
  startHash: string,
  setLastTx: (s: string) => void
}

export function SendMoves(props: FlappyProps) {
  const { account } = useAccount()
  const { provider } = useProvider()
  const { contract: counter } = useGameContract()
  const calls = useMemo(() => {
    if (!account || !counter) return [];
    return counter.populateTransaction["validateGame"]!(props.startHash, props.moves);
  }, [account, counter, props.startHash, props.moves]);
  const { writeAsync, data, isPending } = useContractWrite({ calls });
  const { isLoading: isTxLoading, data: txData } = useWaitForTransaction({ hash: data?.transaction_hash, watch: true });

  useEffect(() => {
    if (data) {
      props.setLastTx(data.transaction_hash);
    }
  }, [data])

  useEffect(() => {
    if (data && txData && !isTxLoading) {
      console.log(txData)
      provider.getTransactionReceipt(data.transaction_hash).then(async (rec: any) => {
        let startBlock = await provider.getBlock(props.startHash)
        let block = await provider.getBlock(rec.block_hash)
        alert(`Game started at ${startBlock.timestamp} and ended at ${block.timestamp}.\nDuration: ${block.timestamp - startBlock.timestamp} seconds`)
      })
    }
  }, [data, props.startHash, isTxLoading, txData, provider])

  if (!account) {
    return null
  }

  return (
    <button
      className="ml-2 rounded-md w-80 px-2 py-1 bg-slate-700 text-white"
      onClick={() => writeAsync()}>
      Send moves to contract
    </button>
  )
}
