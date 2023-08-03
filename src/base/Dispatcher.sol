// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

abstract contract Dispatcher {
    function _dispatch(bytes1 _command, bytes calldata _input) internal {}
}