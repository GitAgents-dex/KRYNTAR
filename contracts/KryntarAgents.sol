// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
  KRYNTAR Agents — 1.111 pixel agent, gambar & trait disimpan 100% on-chain di BNB Chain.
  - Free mint: 2 per wallet, bayar freeFee 0.0004 BNB per agent
  - Paid mint: 2 per wallet, mintPrice 0.002 BNB per agent (1 = 0.002, 2 = 0.004)
  - Maks 4 per wallet (2 free + 2 paid). Harga bisa diubah owner
  - 10 kind dengan jumlah pasti (total 1.111), plus 2 rare tag ~1%: Pure Crystal & Resonance Eyes
  - Kind tiap agent memberi perk di game KRYNTAR Mining Rush

  Deploy: remix.ethereum.org -> compile 0.8.24, EVM paris, optimizer ON (200 runs)
          -> Injected Provider (MetaMask di BNB Smart Chain, chain id 56) -> Deploy
  Lalu tempel alamat kontrak ke CONTRACT_ADDRESS di index.html, panggil setMintOpen(true).
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract KryntarAgents is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1111;
    uint256 public constant MAX_PER_WALLET = 4;
    uint256 public constant FREE_PER_WALLET = 2;
    uint256 public constant PAID_PER_WALLET = 2;
    uint256 public constant KINDS = 10;

    uint256 public freeFee = 0.0004 ether;  // biaya free mint per agent (BNB)
    uint256 public mintPrice = 0.002 ether;  // paid mint per agent (BNB)
    bool public mintOpen;
    address public payee;

    mapping(address => uint256) public mintedBy;
    mapping(uint256 => uint256) private _dna; // bit 0-7 kind, bit 8 pureCrystal, bit 9 resonanceEyes
    uint16[10] public remaining = [200, 167, 144, 133, 111, 100, 89, 67, 56, 44];
    uint256 public remainingTotal = MAX_SUPPLY;

    bytes private constant PIXELS = hex"2e2e2e2e2e61612e2e2e2e2e2e2e2e2e6f61616f2e2e2e2e2e2e2e6f6f6f6f6f6f2e2e2e2e2e6f6262626262626f2e732e2e6f7676767676766f73732e2e6f7665767665766f2e732e2e6f6262626262626f2e732e2e2e6f6f6f6f6f6f2e2e732e2e6f6462626262646f2e732e2e6f6262616162626f2e2e2e2e6f6462626262646f2e2e2e2e2e6f6f2e2e6f6f2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e6f6f6f6f6f6f2e2e2e73736f6262626262626f2e2e73736f7676767676766f2e2e2e736f7665767665766f2e2e2e736f6262626262626f2e2e2e732e6f6f6f6f6f6f2e2e2e2e736f6462626262646f2e2e2e2e6f6262616162626f2e2e2e2e6f6462626262646f2e2e2e2e2e6f6f2e2e6f6f2e2e2e2e2e2e6464646464642e2e2e2e2e2e6464646464642e2e2e2e2e6f6f6f6f6f6f6f6f2e2e2e2e6f6262626262626f2e2e2e2e6f7676767676766f2e2e2e2e6f7665767665766f2e2e2e2e6f6262626262626f2e2e2e2e2e6f6f6f6f6f6f2e2e2e2e2e6f6462626262646f61612e2e6f6262616162626f61612e2e6f6462626262646f2e2e2e2e2e6f6f2e2e6f6f2e2e2e2e2e2e2e2e2e652e2e2e2e2e2e2e2e2e2e2e6f2e2e2e2e2e2e2e2e6f6f6f6f6f6f2e2e2e2e2e6f6262626262626f2e2e2e6f76767676767676766f2e2e6f76657676767665766f2e2e2e6f6262626262626f2e2e2e2e2e6f6f6f6f6f6f2e2e2e2e2e6f6462626262646f2e2e2e2e6f6262616162626f2e2e2e2e6f6462626262646f2e2e2e2e2e6f6f2e2e6f6f2e2e2e2e2e2e2e2e63632e2e2e2e2e2e2e2e2e637763632e2e2e2e2e2e2e6f6f6f6f6f6f2e2e2e2e2e6f6262626262626f2e2e2e2e6f7676767676766f2e2e2e2e6f7665767665766f2e2e2e2e6f6262626262626f2e2e2e2e2e6f6f6f6f6f6f2e2e2e2e2e6f6462636262646f2e2e2e2e6f6263636363626f2e2e2e2e6f6462636262646f2e2e2e2e2e6f6f2e2e6f6f2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e6f6f6f6f6f6f2e2e2e2e2e6f6262626262626f2e2e2e2e6f6262626262626f2e2e2e2e6f7676767676766f2e2e2e2e6f7665767665766f2e2e2e6f6f6262626262626f6f2e2e6f62646464646464626f2e2e6f62626261616262626f2e2e6f62626262626262626f2e2e6f64646464646464646f2e2e2e6f6f6f2e2e6f6f6f2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e6f6f6f6f6f6f2e2e2e2e2e6f6262626262626f2e2e2e2e6f7676767676766f2e2e2e2e6f7665767665766f73732e2e6f6262626262626f73612e2e2e6f6f6f6f6f6f7373732e2e6f6462626262646f732e2e2e6f6262616162626f2e2e2e2e6f6462626262646f2e2e2e2e2e6f6f2e2e6f6f2e2e2e2e2e2e2e646464642e2e2e2e2e2e2e6464646464642e2e2e2e2e646f6f6f6f6f6f642e2e2e2e6f6262626262626f2e2e2e2e6f7676767676766f2e2e2e2e6f7665767665766f2e2e2e2e6f6262626262626f2e2e2e632e6f6f6f6f6f6f2e2e2e6363636462626262646f2e2e6377636262616162626f2e2e2e632e6462626262646f2e2e2e2e2e6f6f2e2e6f6f2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e6f6f6f6f6f6f2e2e2e2e2e6f6262626262626f2e2e2e2e6f6262626262626f2e2e2e2e6f7676767676766f2e2e2e2e6f7665767665766f2e2e61616f6262626262626f2e2e6161616f6f6f6f6f6f2e2e2e61616f6462626262646f2e2e61616f6262616162626f2e2e2e616f6462626262646f2e2e2e2e2e6f6f2e2e6f6f2e2e2e2e2e61616161616161612e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e6f6f6f6f6f6f2e2e2e2e2e6f6262626262626f2e2e2e2e6f7676767676766f2e2e2e2e6f7676656576766f2e2e2e2e6f6262626262626f2e2e2e2e2e6f6f6f6f6f6f2e2e2e2e2e6f6462626262646f2e2e2e2e6f6262616162626f2e2e2e2e6f6462626262646f2e2e2e2e2e6f6f2e2e6f6f2e2e2e";
    string[10] private NAMES = ["Miner", "Smith", "Trader", "Scout", "Resonator", "Golem", "Driller", "Alchemist", "Sentinel", "Oracle"];
    string[10] private PERKS = [unicode"石头和铁矿得分 +20%", unicode"连击倍率提升速度 2 倍", unicode"金矿价值 2 倍", unicode"游戏时间 +8 秒", unicode"水晶出现频率 2 倍", unicode"生命 +1", unicode"矿石出现速度 +15%", unicode"第一次碰到岩浆不扣生命", unicode"前 2 次岩浆免疫", unicode"所有得分 +25%"];
    string[10] private TINT = ["#3d8bff", "#ff5c39", "#ffc23c", "#39ff88", "#8b6bff", "#a9b7ca", "#ff8a3d", "#3dd6c6", "#3d5aff", "#ff6bd6"];
    string[10] private SHADE = ["#2a5fb8", "#b83a20", "#c48a12", "#1fa85a", "#5a3fd1", "#6b7d95", "#c45a12", "#1f8f84", "#2236b8", "#b83a96"];

    error MintClosed(); error BadQuantity(); error OverLimit(); error SoldOut(); error Underpaid(); error PayFailed();

    event AgentMinted(address indexed to, uint256 indexed tokenId, uint256 kind, bool pureCrystal, bool resonanceEyes);

    constructor() ERC721("KRYNTAR Agents", "KAGENT") Ownable(msg.sender) { payee = msg.sender; }

    // ---------- reads ----------
    function totalMinted() external view returns (uint256) { return totalSupply(); }
    function freeLeft(address w) public view returns (uint256) { uint256 m = mintedBy[w]; return m >= FREE_PER_WALLET ? 0 : FREE_PER_WALLET - m; }
    function paidLeft(address w) public view returns (uint256) { uint256 m = mintedBy[w]; return m >= MAX_PER_WALLET ? 0 : (m <= FREE_PER_WALLET ? PAID_PER_WALLET : MAX_PER_WALLET - m); }
    function quote(address w, uint256 qty) public view returns (uint256 bnbWei, uint256 paid) {
        uint256 f = freeLeft(w); uint256 free = qty > f ? f : qty; paid = qty - free;
        bnbWei = free * freeFee + paid * mintPrice;
    }
    function agentOf(uint256 id) public view returns (uint256 kind, bool pureCrystal, bool resonanceEyes) {
        _requireOwned(id); uint256 d = _dna[id]; return (d & 0xff, (d >> 8) & 1 == 1, (d >> 9) & 1 == 1);
    }
    function kindInfo(uint256 k) external view returns (string memory name, string memory perk, uint256 left) {
        return (NAMES[k], PERKS[k], remaining[k]);
    }
    function tokensOf(address w) external view returns (uint256[] memory ids) {
        uint256 n = balanceOf(w); ids = new uint256[](n);
        for (uint256 i; i < n; i++) ids[i] = tokenOfOwnerByIndex(w, i);
    }

    // ---------- mint ----------
    function mint(uint256 qty) external payable {
        if (!mintOpen) revert MintClosed();
        if (qty == 0 || qty > MAX_PER_WALLET) revert BadQuantity();
        if (mintedBy[msg.sender] + qty > MAX_PER_WALLET) revert OverLimit();
        if (totalSupply() + qty > MAX_SUPPLY) revert SoldOut();
        (uint256 cost, ) = quote(msg.sender, qty);
        if (msg.value < cost) revert Underpaid();
        mintedBy[msg.sender] += qty;

        for (uint256 i; i < qty; i++) {
            uint256 id = totalSupply() + 1;
            uint256 r = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.prevrandao, msg.sender, id, block.timestamp)));
            uint256 pick = r % remainingTotal; uint256 k;
            for (; k < KINDS; k++) { if (pick < remaining[k]) break; pick -= remaining[k]; }
            remaining[k]--; remainingTotal--;
            bool pc = (r >> 128) % 100 == 0; bool re = (r >> 160) % 100 == 0;
            _dna[id] = k | (pc ? 1 << 8 : 0) | (re ? 1 << 9 : 0);
            _safeMint(msg.sender, id);
            emit AgentMinted(msg.sender, id, k, pc, re);
        }
        if (cost > 0) { (bool ok, ) = payable(payee).call{value: cost}(""); if (!ok) revert PayFailed(); }
        if (msg.value > cost) { (bool ok2, ) = payable(msg.sender).call{value: msg.value - cost}(""); if (!ok2) revert PayFailed(); }
    }

    // ---------- on-chain art ----------
    function _color(bytes1 c, uint256 k, bool pc, bool re) private view returns (string memory) {
        if (c == "o") return "#0a1220";
        if (c == "v") return "#16233a";
        if (c == "e") return re ? "#ff2d55" : "#3dfcff";
        if (c == "a") return pc ? "#c9b8ff" : "#ffc23c";
        if (c == "c") return "#8b6bff";
        if (c == "s") return "#a9b7ca";
        if (c == "w") return "#ffffff";
        if (c == "b") return pc ? "#8b6bff" : TINT[k];
        return pc ? "#5a3fd1" : SHADE[k]; // "d"
    }

    function svgOf(uint256 id) public view returns (string memory) {
        (uint256 k, bool pc, bool re) = agentOf(id);
        bytes memory out = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 12 12" shape-rendering="crispEdges"><rect width="12" height="12" fill="',
            pc ? "#241a4d" : "#1b2a44", '"/>');
        uint256 base = k * 144;
        for (uint256 j; j < 144; j++) {
            bytes1 c = PIXELS[base + j];
            if (c == ".") continue;
            out = abi.encodePacked(out, '<rect x="', (j % 12).toString(), '" y="', (j / 12).toString(),
                '" width="1" height="1" fill="', _color(c, k, pc, re), '"/>');
        }
        if (re) out = abi.encodePacked(out, '<rect x="9" y="5" width="3" height="0.4" fill="#ff2d55" opacity=".8"/>');
        return string(abi.encodePacked(out, "</svg>"));
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        (uint256 k, bool pc, bool re) = agentOf(id);
        string memory rare = pc && re ? "Pure Crystal + Resonance Eyes" : pc ? "Pure Crystal" : re ? "Resonance Eyes" : "None";
        bytes memory json = abi.encodePacked(
            '{"name":"KRYNTAR Agent #', id.toString(),
            '","description":"', unicode"KRYNTAR 像素代理，完全在 BNB Chain 链上绘制和存储。在 Mining Rush 游戏中的加成：", PERKS[k],
            '","image":"data:image/svg+xml;base64,', Base64.encode(bytes(svgOf(id))),
            '","attributes":[{"trait_type":"Kind","value":"', NAMES[k],
            '"},{"trait_type":"Rare","value":"', rare,
            '"},{"trait_type":"Perk","value":"', PERKS[k], '"}]}');
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    // ---------- owner ----------
    function setMintOpen(bool o) external onlyOwner { mintOpen = o; }
    function setMintPrice(uint256 p) external onlyOwner { mintPrice = p; }
    function setFreeFee(uint256 p) external onlyOwner { freeFee = p; }
    function setPayee(address p) external onlyOwner { payee = p; }
}
