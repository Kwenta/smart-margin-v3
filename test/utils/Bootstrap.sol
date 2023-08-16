// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Test} from "lib/forge-std/src/Test.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {IERC20, SUSDHelper} from "test/utils/SUSDHelper.sol";
import {Constants} from "test/utils/Constants.sol";
import {Engine, OptimismGoerliParameters, Setup} from "script/Deploy.s.sol";

contract Bootstrap is Test, Constants, OptimismGoerliParameters {
    Engine engine;
    IPerpsMarketProxy perpsMarketProxy;
    IERC20 sUSD;
    SUSDHelper sUSDHelper;
    uint128 accountId;

    function initialize() public {
        perpsMarketProxy = IPerpsMarketProxy(OPTIMISM_GOERLI_PERPS_MARKET_PROXY);
        sUSD = IERC20(OPTIMISM_GOERLI_USD_PROXY);

        Setup setup = new Setup();
        engine = setup.deploySystem({
            perpsMarketProxy: OPTIMISM_GOERLI_PERPS_MARKET_PROXY,
            spotMarketProxy: OPTIMISM_GOERLI_SPOT_MARKET_PROXY,
            sUSDProxy: OPTIMISM_GOERLI_USD_PROXY
        });

        vm.startPrank(ACTOR);
        accountId = perpsMarketProxy.createAccount();
        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: "ADMIN",
            user: address(engine)
        });
        vm.stopPrank();

        sUSDHelper = new SUSDHelper();
        sUSDHelper.mint(ACTOR, AMOUNT);
    }
}
