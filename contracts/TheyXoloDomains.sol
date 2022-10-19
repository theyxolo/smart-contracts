// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title TheyXoloDomains
/// @author cesargdm.eth

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

interface IEnsPublicResolver {
  function setAddr(bytes32 node, address addr) external;
}

interface IEnsRegistry {
  function setSubnodeRecord(
    bytes32 node,
    bytes32 label,
    address owner,
    address resolver,
    uint64 ttl
  ) external;

  function recordExists(bytes32 node) external view returns (bool);
}

contract TheyXoloDomains is Pausable {
  event GotNameHash(bytes32 namehash);

  uint64 defaultTtl = 43200;

  address ensPublicResolverAddr;
  IEnsPublicResolver ensPublicResolver;
  IEnsRegistry ensRegistry;

  constructor(address _ensRegistryAddr, address _ensPublicResolverAddr) {
    // 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e
    ensRegistry = IEnsRegistry(_ensRegistryAddr);

    // Mainnet:
    // Goerli: 0x4B1488B7a6B320d2D721406204aBc3eeAa9AD329
    ensPublicResolver = IEnsPublicResolver(_ensPublicResolverAddr);
    ensPublicResolverAddr = _ensPublicResolverAddr;
  }

  function getNamehash(bytes32 _label) public pure returns (bytes32 namehash) {
    namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;

    namehash = keccak256(
      abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
    );
    namehash = keccak256(
      abi.encodePacked(namehash, keccak256(abi.encodePacked('theyxolo')))
    );
    namehash = keccak256(
      // Label is already a keccak256 hash
      abi.encodePacked(namehash, _label)
    );
  }

  function setUser(bytes32 _parentNode, bytes32 _labelHash)
    external
    whenNotPaused
  {
    // Calculate node from label
    bytes32 usernameNode = getNamehash(_labelHash);

    // Check subodmain does not exist already
    require(
      !ensRegistry.recordExists(usernameNode),
      'TheyXoloDomains: Username already exists'
    );

    ensRegistry.setSubnodeRecord(
      _parentNode,
      _labelHash,
      msg.sender,
      ensPublicResolverAddr,
      defaultTtl
    );
  }
}
