# MulticallablePayable

  
The MulticallablePayable [contract](https://github.com/Kwenta/smart-margin-v3/blob/cacb85bd4c913a85c6bc978b1e8cde2585cee19a/src/utils/MulticallablePayable.sol#L7) is Kwenta's Multicall implementation that enables a single call to call multiple methods on itself.  It is slightly different from Synthetix [TrustedMulticallForwarder](https://github.com/Synthetixio/synthetix-v3/blob/0591c4cb5d36b6720dbc5b867e87f5274aaa518d/auxiliary/TrustedMulticallForwarder/src/TrustedMulticallForwarder.sol#L8), and this document aims to focus on the key differences between them, as well as presenting alternative options.

## Kwenta MulticallablePayable contract
```
function multicall(bytes[] calldata data)
        public
        payable
        returns (bytes[] memory)
```

`multicall` applies `DELEGATECALL` with the current contract to each calldata in `data`, and store the `abi.encode` formatted results of each `DELEGATECALL` into `results`. If any of the `DELEGATECALL`s reverts, the entire context is reverted,
and the error is bubbled up.

This function is *payable* in order to support multicalls including [EIP7412.fulfillOracleQuery()](https://github.com/Kwenta/smart-margin-v3/blob/cacb85bd4c913a85c6bc978b1e8cde2585cee19a/src/utils/EIP7412.sol). 
Inside a delegatecall, `msg.sender` and `msg.value` are persisted (see: https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong), and although `EIP7412.fulfillOracleQuery()` is payable and uses `msg.value`, double spending is not possible in the SMV3 Engine context as it's the only function that makes use of `msg.value`.

## Synthetix TrustedMulticallForwarder

A TrustedMulticallForwarder is required because sometimes it is necessary to send multiple commands at the same time from an Externally Owned Account, but EOAs dont support calling more than one function in a transaction.The TrustedMulticallForwarder aggregates results from multiple function calls.
It can be used for Synthetix v3 Account Creation/Permission Granting, or for any adress to send multiple orders at the same time. All transactions should be prepared as a multicall and sent to the `TrustedMulticallForwarder` contracts using `aggregate3Value`.

Unlike Kwenta's `MulticallablePayable`, Synthetix `TrustedMulticallForwarder` includes [ERC-2771](https://eips.ethereum.org/EIPS/eip-2771) trusted forwarder functionality. 

Considering we have account abstraction used by our front-end, there is no real point for Kwenta to have ERC-2771 implemented, as meta-transactions can be executed directly by any account without the necessity for trusted relayers or forwarders.

Although we could use Synthetix `TrustedMulticallForwarder`, our own implementation of `MulticallablePayable` is more suited to account abstraction used by frontend and 1ct as we don't need ERC-2771.

## Alternatives

It's important to note that `MulticallablePayable` is adapted from Solady/Solmate Multicallable implementation and that Synthetix `TrustedMulticallForwarder` is derived from [Multicall3](https://github.com/mds1/multicall).

Solady's multicall implementation is the same that `MulticallablePayable`, with the exception that the multicall function is deliberately made non-payable to guard against double spending (see above why we had to make it payable).

Other alternatives of Multicall exists, for instance OpenZeppelin's has a Multicall but it does not directly support value transfers, which does not align with our requirements.

Overall, each solution has its tradeoffs, such as simplicity, features, integration with existing libraries, gas efficiency, and suitability for specific use cases, but Kwenta `MulticallablePayable` implementation seems to be the most suited implementation for our needs, that is reliable as it's derived from well-established projects (Solady/Solmate have lots of forks around the ecosystem), on top of being gas efficient.
Moreover, having our own implementation means it's easier to adapt to new configurations/needs.