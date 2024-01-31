%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (
    get_caller_address, 
    get_block_timestamp
)

from starkware.cairo.common.bitwise import bitwise_and

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import (
    unsigned_div_rem,
    assert_nn_le,
    split_felt
)
from starkware.cairo.common.math_cmp import (
    is_in_range,
    is_le_felt
)

// CONSTANTS
const PIPE_START_X = 100;
const PIPE_END_X = 120;
const BOTTOM_Y = 0;
const TOP_Y = 100;
const JUMP_VELOCITY = 6;
const X_VELOCITY = 4;
const GRAVITY = -1;
const MAX_PIPE_Y_VARIANCE = 40;
const PIPES_COUNT = 8;
const PIPE_GAP_Y = 60;
const INIT_Y_VELOCITY = 0;
const INIT_BIRD_X = 0;
const INIT_BIRD_Y = 40;
const MIN_X_TO_WIN = 500;
const TOKEN_MULT = 1000000000;

// GAME STATE STRUCT

struct Position {
    x : felt,
    y : felt,
}

struct State {
    pos : Position,
    yVelocity : felt,
    pipesOffset: felt*,
}

struct Notarization {
    startHash: felt,
    movesHash: felt,
    timestamp: felt,
}

@storage_var
func isMember(user : felt) -> (res : felt){
}

@storage_var
func notarizedMoves(user : felt) -> (res : Notarization){
}

@view
func get_balance{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(user : felt) -> (res : felt){
    let (res) = isMember.read(user=user);
    return (res=res);
}

@external
func validateGame{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
        }(startHash: felt, moves_len : felt, moves : felt*) -> (pos: Position){

    alloc_locals;
    
    let (local address) = get_caller_address();
    let (local notarization) = notarizedMoves.read(address);

    let (hash) = calcHash(moves_len,moves,0);

    assert notarization.movesHash = hash;

    let (initState : State) = getInitState(address,startHash);

    let (local finalState: State) = getFinalState(moves_len, moves, initState);

    isMember.write(address, finalState.pos.x);
    return(pos=finalState.pos);
}

@external
func notarize{syscall_ptr : felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
        }(moves_len : felt, moves : felt*, startHash: felt) -> (res: felt){

    alloc_locals;
    
    let (local address) = get_caller_address();

    let (movesHash) = calcHash(moves_len,moves,0);

    let (block_timestamp) = get_block_timestamp();
    notarizedMoves.write(address, Notarization(startHash,movesHash,block_timestamp));
    return (res=TRUE);
}

func calcHash{
        syscall_ptr : felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
        }(moves_len : felt, moves : felt*, current: felt) -> (hash: felt){

    if(moves_len == 0){
        return (hash=current);
    } else {
        let (movesHash) = hash2{hash_ptr=pedersen_ptr}(current,moves[0]);
        return calcHash(moves_len-1,&moves[1],movesHash);
    }
}

@view
func D_showFinalState{
        syscall_ptr : felt*, range_check_ptr
        }(moves_len : felt, moves : felt*, address : felt, startHash: felt) -> (finalPos : Position){

    let (initState: State) = getInitState(address,startHash);
    let (finalState: State) = getFinalState(moves_len, moves, initState);
    return (finalPos=finalState.pos);
}

func getFinalState{syscall_ptr : felt*, range_check_ptr
        }(moves_len : felt, moves : felt*, state : State) -> (finalState : State){

    if (moves_len == 0) {
        return (finalState=state);
    } else {
        let (isFinal) = isStateFinal(state);
        
        if (isFinal == TRUE) {
            return (finalState=state);
        } else {
            let (next_state : State) = transitionFunction(state, moves[0]);
            return getFinalState(moves_len-1, &moves[1], next_state);
        }
    }
}

func transitionFunction{syscall_ptr : felt*, range_check_ptr
        }(s : State, move: felt) -> (state : State){
    alloc_locals;
    
    let (local yVelocity) = getNextVelocity(s.yVelocity, move);

    let (next_pos : Position) = getNextPosition(s.pos, yVelocity);
    
    return (state=State(next_pos,yVelocity,s.pipesOffset));
}


func getNextPosition{syscall_ptr : felt*, range_check_ptr}(prev_pos : Position, yVelocity: felt)
         -> (pos : Position){

    return (pos=Position(prev_pos.x + X_VELOCITY, prev_pos.y + yVelocity));
}

func getNextVelocity{syscall_ptr : felt*, range_check_ptr}(prev : felt, move: felt) -> (yVelocity : felt){
    if (move == 0){
        return (yVelocity=prev + GRAVITY);
    } else {
        return (yVelocity=JUMP_VELOCITY);
    }
}

func isStateFinal{
        syscall_ptr : felt*, range_check_ptr}(state : State) -> (bool : felt){
        alloc_locals;
        let (local check_1) = isInsideBorders(state.pos);
        let (local check_2) = hasAvoidedPipe(state);
        let isAlive = check_1 * check_2;
        if (isAlive == TRUE) {
            return (bool=FALSE);
        } else {
            return (bool=TRUE);
        }
}

func isInsideBorders{
        syscall_ptr : felt*, range_check_ptr}(pos : Position) -> (bool : felt){
        let check_1 = is_in_range(pos.y,BOTTOM_Y,TOP_Y);
        return (bool=check_1);
}

func hasAvoidedPipe{
        syscall_ptr : felt*, range_check_ptr}(state : State) -> (bool : felt){
    alloc_locals;
    let (local passedPipesCount, x) = unsigned_div_rem(state.pos.x, PIPE_END_X);
    let isInPipeRange = is_in_range(x, PIPE_START_X, PIPE_END_X);

    if (isInPipeRange == TRUE){
    
        let (_, pipeIndex) = unsigned_div_rem(passedPipesCount, PIPES_COUNT);
        let pipeOffset = state.pipesOffset[pipeIndex];
        let isInSafeRange = is_in_range(state.pos.y, 0 + pipeOffset, PIPE_GAP_Y + pipeOffset);
        return (bool=isInSafeRange);
    } else {
        return (bool=TRUE);
    }
}

@view
func showInitState{syscall_ptr : felt*, range_check_ptr}(address : felt, startHash : felt) -> 
        (pos : Position, yVelocity : felt, pipesOffset_len : felt, pipesOffset : felt*){
    
    let (state : State) = getInitState(address,startHash);
    
    return (pos=state.pos, yVelocity=state.yVelocity, pipesOffset_len=PIPES_COUNT, pipesOffset=state.pipesOffset);
}

func getInitState{syscall_ptr : felt*, range_check_ptr}(address : felt, startHash: felt) -> (state : State){

    let (_, pipesOffset : felt*) = getValuesFromSeed(address*startHash, MAX_PIPE_Y_VARIANCE, 8);
    
    return (state=State(Position(INIT_BIRD_X,INIT_BIRD_Y), INIT_Y_VELOCITY, pipesOffset));
}

@view
func getValuesFromSeed{range_check_ptr}(seed: felt, maxValue: felt, howMany: felt) -> (values_len: felt, values : felt*){
    alloc_locals;
    let (local accumulator : felt*) = alloc();
    return getValuesFromSeedHelper(seed, maxValue, howMany, 0, accumulator);
}

func getValuesFromSeedHelper{range_check_ptr}(seed: felt, maxValue: felt, howMany: felt, acc_len: felt, acc: felt*) -> (values_len: felt, values : felt*){
    alloc_locals;
    if (acc_len == howMany){
        return (values_len=acc_len, values=acc);
    }
    let (_, seed_lowerHalf) = split_felt(seed);
    let (_, local value) = unsigned_div_rem(seed_lowerHalf, maxValue);
    assert acc[acc_len] = value;
    let newSeed = seed * seed;
    return getValuesFromSeedHelper(newSeed, maxValue, howMany, acc_len + 1, acc);
}
