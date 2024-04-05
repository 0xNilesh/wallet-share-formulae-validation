// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

contract WalletShare {
    uint256 public walletTotalShares = 100;
    mapping (address wallet => uint256 sharesAmount) public shares;
    address public immutable OWNER;
    address public immutable FOUNDATION;

    error NotAuthorized();
    error IncorrectPercentage();

    modifier onlyOwner () {
        if (msg.sender != OWNER) revert NotAuthorized();
        _;
    }

    constructor (address _presetWallet, address _foundationWallet, address _owner) {
        OWNER = _owner;
        shares[_presetWallet] = walletTotalShares;
        FOUNDATION = _foundationWallet;
    }

    function getSharesAmount (uint256 _totalShares, uint256 _percentage)
    public pure returns (uint256 sharesToBeAllocated) {
        if (_percentage >= 100) revert IncorrectPercentage();
        sharesToBeAllocated = (_percentage * _totalShares) / (100 - _percentage);
    }

    function addWalletShare (address _walletAddress, uint256 _percentage) public onlyOwner {
        if (_percentage >= 100) revert IncorrectPercentage();
        uint256 sharesToBeAllocated = getSharesAmount(walletTotalShares, _percentage);
        walletTotalShares += sharesToBeAllocated;
        shares[_walletAddress] = sharesToBeAllocated;
    }

    // Method1: Remove the shares of the wallet from circulation
    function removeWalletShareM1 (address _walletAddress) public onlyOwner {
        uint256 walletShares = shares[_walletAddress];
        walletTotalShares -= walletShares;
        shares[_walletAddress] = 0;
    }

    // Method2: Allocate wallet's shares to the foundation
    function removeWalletShareM2 (address _walletAddress) public onlyOwner {
        uint256 walletShares = shares[_walletAddress];
        shares[FOUNDATION] += walletShares;
        shares[_walletAddress] = 0;
    }

    function updateWalletSharesM1 (address _walletAddress, uint256 _newPercentage) public onlyOwner {
        if (_newPercentage >= 100) revert IncorrectPercentage();
        uint256 allocatedWalletShares = shares[_walletAddress];
        // totalSharesParam as total shares excluding allocated to the wallet
        uint256 newWalletShares = getSharesAmount(walletTotalShares - allocatedWalletShares, _newPercentage);
        walletTotalShares = walletTotalShares + newWalletShares - allocatedWalletShares;
        shares[_walletAddress] = newWalletShares;
    }

    function updateWalletSharesM2 (address _walletAddress, uint256 _newPercentage) public onlyOwner {
        if (_newPercentage >= 100) revert IncorrectPercentage();
        uint256 allocatedWalletShares = shares[_walletAddress];
        // totalSharesParam as total shares excluding allocated to the wallet
        uint256 newWalletShares = getSharesAmount(walletTotalShares - allocatedWalletShares, _newPercentage);
        walletTotalShares = walletTotalShares + newWalletShares - allocatedWalletShares;
        shares[_walletAddress] = newWalletShares;

        if (newWalletShares < allocatedWalletShares) {
            // Decreased percentage allocation of wallet and sent to foundation
            shares[FOUNDATION] += allocatedWalletShares - newWalletShares;
        }
    }
}
