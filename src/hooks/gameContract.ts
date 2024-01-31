import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import CounterAbi from '~/abi/counter.json'
/*
$0.018950
$0.026530
*/
export function useGameContract() {
  return useContract({
    abi: CounterAbi as Abi,
    address: '0x67cbff9203c0d1c44816c39f78444d7f13653686cd3d7a1bc63e0a85be8e11b'
  })
}
