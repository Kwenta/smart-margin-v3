// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

/// @title Contract for defining constants used in testing
/// @author JaredBorders (jaredborders@pm.me)
contract Constants {
    uint256 public constant BASE_BLOCK_NUMBER = 8_225_680;

    address internal constant OWNER = address(0x01);

    bytes32 internal constant TRACKING_CODE = "KWENTA";

    address internal constant REFERRER = address(0xEFEFE);

    int128 internal constant SIZE_DELTA = 1 ether / 100;

    int128 internal constant INVALID_SIZE_DELTA = type(int128).max;

    uint256 internal constant ACCEPTABLE_PRICE_LONG = type(uint256).max;

    uint256 internal constant ACCEPTABLE_PRICE_SHORT = 0;

    uint256 internal constant INVALID_ACCEPTABLE_PRICE_LONG = 0;

    uint128 internal constant SETTLEMENT_STRATEGY_ID = 0;

    uint128 internal constant INVALID_SETTLEMENT_STRATEGY_ID = type(uint128).max;

    bytes32 internal constant ADMIN_PERMISSION = "ADMIN";

    bytes32 internal constant PERPS_COMMIT_ASYNC_ORDER_PERMISSION =
        "PERPS_COMMIT_ASYNC_ORDER";

    address internal constant MOCK_MARGIN_ENGINE = address(0xE1);

    address internal constant ACTOR = address(0xa1);

    address internal constant BAD_ACTOR = address(0xa2);

    address internal constant NEW_ACTOR = address(0xa3);

    address internal constant DELEGATE_1 = address(0xd1);

    address internal constant DELEGATE_2 = address(0xd2);

    address internal constant DELEGATE_3 = address(0xd3);

    uint128 internal constant SUSD_SPOT_MARKET_ID = 0;

    uint128 internal constant SETH_SPOT_MARKET_ID = 2; // ?

    uint128 internal constant INVALID_PERPS_MARKET_ID = type(uint128).max;

    uint128 constant SETH_PERPS_MARKET_ID = 200;

    uint256 internal constant AMOUNT = 10_000 ether;

    uint256 internal constant SMALLER_AMOUNT = 100 ether;

    uint256 internal constant SMALLEST_AMOUNT = 100 wei;

    address internal constant MARKET_CONFIGURATION_MODULE = address(0xC0FE);

    uint256 internal constant ZERO_CO_FEE = 0;

    uint256 internal constant CO_FEE = 620_198 wei;

    bytes internal constant ETH_USD_PYTH_PRICE_FEED =
        "0x504e41550100000003b801000000030d014cf37f351d5b43adb7351848ed692a8aa595a7ca44bc6977d27d9c8b4e9dc6716580ee634bbfdc61c906713bddaed63641fa9a6c1598ddf8453822127ef8a9ab00023fa28f0103423f2f1fe8f3d26c1aa6029c950eb1ded22f460d43eab688f0d264659a6f3990976c6a6784b6945b325f7fc1d45abfa6118391cbf2fbdae7e9274c01049408e26c7573bbc42adf2543bd4f5c7ea1d846db60173116612bf0b7486666622c192cf4b7a863776e877c1ec91d0d508a79bb81055b8644fbd10b9a04689e1e0006efa307bfaca10475207d16a305155acf925237408288081ea548fff9543dae790352d63b4be29c17376b90cef8618790740c172e376ae064cbf5a3520d401aac0008692d6a9d6039785ec518f5375b19ef51ac3c2d4f74a3ff16bf1f76a19321b7266d3eaaf972606374ee20594993bf06394ab723c6f12ea6b1b59101d02a52bbfb010934479367502501fee4a8ad5863a8f54c07c608c931e1958833f08f85f7f471493da4580b98c07835f8b4fc3c6391802ef8c84b4d632b7cda929bfb1855724487010b1ee991dd8ac66a2b6b221217327e3c666245956c2cef21267f5ce8d9db7c5d29624d6a535887ff171d73afed829ab0c6a6622046de6dcfd6837d2961a6ca0439010cc2ba52b14836d141ee7de88489b00183435bb19bf8c106e68b0e2448ce9a92e8690ca33a1492a962d56d5a9ef9fe90946c82e41258f3120c6f71666427a99b6a000d7211764e4f3f8f6edec81fbba2767653a549896bc5c47c8398e7943aaf67852e78fa87ddf395b53f28905ab66d49d08df22b7ca763c782a2e4fc9b66bbf72ab1010e592eef1342511e436928be6dfd91149dab11dcdecccd11974d6ebb0ba74809f35f1fb59b2849408faf32484ab4a498bdb862a9dd94706db517c51073ed460462010f0a8512f4ae5413352265e030ce34cd53e8fff9f155e5856236d18e649d96077c09ac1e279ab2d247723a7174b99c5d08d62f394a341942380b3d91a45007a7b70110579b8868c788ad313d8430b44a1b0d9655b3b9307ad42c46a08c17143bce290f036b1f346bfa12c17659c4628464ed86df90d685f9edd3ecde325f6321c4ad3700123af80cab17e62a9b08384bc5540d6d2ce362adeae73b31d86f2f658ab930f93e465a642ba8550f8d22443fd6e8de8948097ffb5e545742b13786598144d1c4ef016597089e00000000001ae101faedac5851e32b9b23b5f9411a8c2bac4aae3ed4dd7b811dd1a72ea4aa710000000002112cc301415557560000000000071862a900002710b97795026449a7f99a7ead515864f7897ad63e1301005500ff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace000000353015c600000000000df28e80fffffff8000000006597089e000000006597089e000000350f3617f0000000000c8beef50afd052ff1a1f0fd3638fc34ad246bc2b004ec0e671eae59d632a9b688005fe35b25815fcc84944d0fa9d7ddaaddb54309a0d9842dd7df109a41faedb54ce501f1323f2d0b4695817ef1cc64242f8ead4031b22b49f16d2f6be31126c6c8bbd83bd6507c3c434fbf4139ce67979c9d928d68af01ab8dd14405ca36d1950d01975c6009fb9ca781f033dd02cabc26fbe8aef48a71fc45256d00c92418ce994a5982401bfee1b1da2e78b6aa353c29a13991ac579604f2ec2c8547a8f5394ec1d891aa5dafa5141b0d6b";
}
