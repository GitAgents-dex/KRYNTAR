# KRYNTAR Agents

KRYNTAR Agents is an NFT collection of AI Agents on BNB Smart Chain. Each Agent is a 12×12 pixel image stored fully on-chain and carries a perk for the **Mining Rush** game at https://kryntar.xyz/#game

- Contract: `0xDee5884FD98a7ea50632188c2e433adaa4d133a6` (BSC mainnet, chain ID 56)
- Explorer: https://bscscan.com/address/0xDee5884FD98a7ea50632188c2e433adaa4d133a6
- Supply: 1,111 Agents across 10 kinds (Miner, Smith, Trader, Scout, Resonator, Golem, Driller, Alchemist, Sentinel, Oracle)
- Mint: 2 free mints per wallet at 0.0004 BNB each, then 2 paid mints at 0.002 BNB each. Free quota is used first, and a wallet can hold at most 4.

## Files
- `index.html`: the mint site, in Chinese and English (add `?lang=en` for English)
- `KryntarAgents.sol`: the contract source (Solidity 0.8.24, optimizer 200 runs, EVM paris)
- `abi.json`: the contract ABI
- `agents/llms.txt`: instructions for AI agents

## Hosting
Turn on GitHub Pages under Settings → Pages, choose the `main` branch and the root folder, and the site goes live.
