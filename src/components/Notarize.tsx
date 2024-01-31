import { useAccount, useContractWrite } from '@starknet-react/core'
import React, { useEffect, useMemo } from 'react'
import { useGameContract } from '~/hooks/gameContract'

interface FlappyProps {
  moves: number[],
  startHash: string,
  setLastTx: (s: string) => void
}

export function Notarize(props: FlappyProps) {
  const { account } = useAccount()
  const { contract: counter } = useGameContract()
  const calls = useMemo(() => {
    if (!account || !counter) return [];
    return counter.populateTransaction["notarize"]!(props.moves, props.startHash);
  }, [account, counter, props.moves, props.startHash]);
  const { writeAsync, data, isPending, } = useContractWrite({ calls });

  useEffect(() => {
    if (data) {
      props.setLastTx(data.transaction_hash)
    }
  }, [data])

  if (!account) {
    return null
  }

  return (
    <button
      className="rounded-md w-32 px-2 py-1 bg-slate-700 text-white"
      onClick={() => writeAsync()}
    >Notarize</button>

  )
}
