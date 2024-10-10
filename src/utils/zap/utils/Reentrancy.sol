// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/// @title multi-level reentrancy guard
/// @author @moss-eth
/// @author @jaredborders
contract Reentrancy {

    /// @notice enumerated stages of execution
    /// @dev each stage denotes a different level of protection
    enum Stage {
        UNSET,
        LEVEL1,
        LEVEL2
    }

    /// @notice current stage of execution
    Stage internal stage;

    /// @notice thrown when stage of execution is not expected
    /// @param actual current stage of execution
    /// @param expected expected stage of execution
    error ReentrancyDetected(Stage actual, Stage expected);

    /// @notice validate current stage of execution is as expected
    /// @param expected stage of execution
    modifier requireStage(Stage expected) {
        _requireStage(expected);
        _;
    }

    function _requireStage(Stage _expected) internal view {
        require(
            _expected == stage,
            ReentrancyDetected({actual: stage, expected: _expected})
        );
    }

}
