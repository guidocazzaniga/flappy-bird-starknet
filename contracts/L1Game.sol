// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract FlappyBird  {

    struct State {
        uint x;
        uint y;
        uint velocity;
    }

    uint256 INIT_Y_VELOCITY = 0;
    uint256 INIT_BIRD_X = 0;
    uint256 INIT_BIRD_Y = 40;
    uint256 BOTTOM_Y = 0;
    uint256 TOP_Y = 100;
    uint256 JUMP_VELOCITY = 6;
    uint256 GRAVITY = 1;
    uint256 X_VELOCITY = 4;

    mapping(address=>State) public _winners;

    function validateGame(bool[] memory moves) public returns (State memory) {
        State memory finalState = getFinalState(moves, State(INIT_BIRD_X,INIT_BIRD_Y,INIT_Y_VELOCITY), 0);
        _winners[msg.sender] = finalState;
        return finalState;
    }

    function getFinalState(bool[] memory moves, State memory state, uint offset) public view returns (State memory) {
        if(moves.length == 0 || offset == moves.length){
            return state;
        } else {
            if(isStateFinal(state) == true){
                return state;
            } else {
                State memory nextState = transitionFunction(state, moves[offset]);
                return getFinalState(moves, nextState, offset+1);
            }
        }
    }

    function transitionFunction(State memory state, bool move) public view returns (State memory) {
        uint yVelocity = getNextVelocity(state.velocity, move);
        (uint newX, uint newY) = getNextPosition(state.x, state.y, yVelocity);
        return State(newX,newY,yVelocity);
    }

    function getNextVelocity(uint previous, bool move) public view returns (uint){
        uint val = move ? 1 : 0;
        if(val == 0){
            return previous - GRAVITY;
        } else {
            return JUMP_VELOCITY;
        }
    } 

    function getNextPosition(uint prevX, uint prevY, uint yVelocity) public view returns (uint x, uint y){
        return (prevX + X_VELOCITY, prevY + yVelocity);
    } 

    function isStateFinal(State memory state) public view returns (bool) {
        bool check = isInRange(state.y, TOP_Y, BOTTOM_Y);
        if(check){
            return false;
        } else {
            return true;
        }
    }

    function isInRange(uint val, uint high, uint low) public pure returns (bool) {
        return high > val && val > low;
    }

}
