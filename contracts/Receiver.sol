// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Receiver {
    bytes32 public constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(address from,uint256 nonce,address relayer,bytes functionSignature)"
            )
        );

    struct MetaTransactionData {
        address from;
        uint256 nonce;
        address relayer;
        bytes functionSignature;
    }

    struct Transfer {
        address tokenAddress;
        address recipient;
        uint256 amount;
    }

    mapping(address => uint256) public nonces;

    event TransferFailed(
        uint256 indexed index,
        address recipient,
        uint256 amount
    );

    event TransferSuccess(
        uint256 indexed index,
        address recipient,
        uint256 amount
    );

    function executeBatchedERC20Transfers(
        MetaTransactionData calldata metaTx,
        Transfer[] calldata transfers,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(metaTx.from != address(0), "Invalid sender address");
        require(
            metaTx.from == msg.sender || metaTx.relayer == msg.sender,
            "Invalid relayer address"
        );
        require(nonces[metaTx.from] == metaTx.nonce, "Invalid nonce");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                hashMetaTransaction(metaTx)
            )
        );
        address signer = ecrecover(digest, v, r, s);
        require(signer == metaTx.from, "Invalid signature");

        for (uint256 i = 0; i < transfers.length; i++) {
            // Call the transferFrom function of the ERC20 token contract
            // bool success = IERC20(transfers[i].tokenAddress).transferFrom(
            //     metaTx.from,
            //     transfers[i].recipient,
            //     transfers[i].amount
            // );

            (bool success, ) = transfers[i].tokenAddress.delegatecall(
                abi.encodeWithSignature(
                    "transferFrom(address, address, uint256)",
                    msg.sender,
                    transfers[i].recipient,
                    transfers[i].amount
                )
            );
            if (!success) {
                // Emit an event to indicate that the transfer failed for this user transaction
                emit TransferFailed(
                    i,
                    transfers[i].recipient,
                    transfers[i].amount
                );
            } else {
                emit TransferSuccess(
                    i,
                    transfers[i].recipient,
                    transfers[i].amount
                );
            }
        }

        // Increment the nonce for the sender
        nonces[metaTx.from]++;
    }

    function getDomainSeparator() public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("BatchedERC20Transfer")),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );
    }

    function hashMetaTransaction(
        MetaTransactionData calldata metaTx
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.from,
                    nonces[metaTx.from],
                    metaTx.relayer,
                    keccak256(metaTx.functionSignature)
                )
            );
    }
}
