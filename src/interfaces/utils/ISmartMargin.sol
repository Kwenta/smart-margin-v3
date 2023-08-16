// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IAuth} from "src/interfaces/modules/IAuth.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {IStats} from "src/interfaces/modules/IStats.sol";

/// @title Kwenta Smart Margin v3: Smart Margin Interface
/// @notice This interface is used to interact with the Smart Margin system
/// @dev The entry point (i.e. contract) for interacting with the
/// Smart Margin system via this interface is **Engine.sol**
/// @author JaredBorders (jaredborders@pm.me)
interface ISmartMargin is IAuth, IEngine, IStats {}
