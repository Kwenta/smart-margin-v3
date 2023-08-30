// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Reduced Interface of the ERC721 standard as defined in the EIP
/// @author OpenZeppelin
interface IERC721 {
    /// @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
    /// are aware of the ERC721 protocol to prevent tokens from being forever locked.
    /// @param from The address of the current owner of the token
    /// @param to The address of the recipient
    /// @param tokenId The token ID to transfer
    ///
    /// Requirements:
    /// - `from` cannot be the zero address.
    /// - `to` cannot be the zero address.
    /// - `tokenId` token must exist and be owned by `from`.
    /// - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
    /// - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
    /// Emits a {Transfer} event.
    function safeTransferFrom(address from, address to, uint256 tokenId)
        external;
}
