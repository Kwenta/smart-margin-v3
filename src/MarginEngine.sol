// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Dispatcher} from "src/base/Dispatcher.sol";

contract MarginEngine is Dispatcher {
    function execute(bytes calldata commands, bytes[] calldata inputs) external {
        uint256 numCommands = commands.length;
        
        assert(inputs.length == numCommands);

        for (uint256 index = 0; index < numCommands; ) {
            bytes1 command = commands[index];

            bytes calldata input = inputs[index];

            _dispatch(command, input);

            unchecked {
                ++index;
            }
        }
    }
}
