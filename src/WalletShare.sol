// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

contract WalletShare {
    uint256 public walletTotalShares = 100_000;
    mapping(address wallet => uint256 sharesAmount) public shares;
    address public immutable OWNER;
    address public immutable FOUNDATION;

    struct Percentage {
        uint256 percentageNumber;
        uint256 decimalPlaces;
    }

    error NotAuthorized();
    error IncorrectPercentage();

    modifier onlyOwner() {
        if (msg.sender != OWNER) revert NotAuthorized();
        _;
    }

    constructor(address _foundationWallet, address _owner) {
        OWNER = _owner;
        shares[_foundationWallet] = walletTotalShares;
        FOUNDATION = _foundationWallet;
    }

    /**
     * @notice Returns shares amount acc. to percentage
     * @param _totalShares    total shares
     * @param _percentage     Percentage struct for percentage share allocation of wallet
     */
    function getSharesAmount(
        uint256 _totalShares,
        Percentage memory _percentage
    )
        public
        pure
        returns (uint256 sharesToBeAllocated)
    {
        if (_percentage.percentageNumber / 10 ^ _percentage.decimalPlaces >= 100) revert IncorrectPercentage();
        sharesToBeAllocated = (_percentage.percentageNumber * _totalShares)
            / ((100 * (10 ^ _percentage.decimalPlaces)) - _percentage.percentageNumber);
    }

    /**
     * @notice Adds a new wallet to get allocation shares
     * @param _walletAddress    address of the wallet being added
     * @param _percentage     Percentage struct for percentage share allocation of wallet
     * Few examples for adding allocation for _percentage
     * 12% => { percentageNumber = 12, decimalPlaces = 0 }
     * 1.25% => { percentageNumber = 125, decimalPlaces = 2 }
     * 0.001% => { percentageNumber = 1, decimalPlaces = 3 }
     * 0.4578% => { percentageNumber = 4578, decimalPlaces = 4 }
     */
    function addWalletShare(address _walletAddress, Percentage memory _percentage) public onlyOwner {
        if (_percentage.percentageNumber / 10 ^ _percentage.decimalPlaces >= 100) revert IncorrectPercentage();
        uint256 sharesToBeAllocated = getSharesAmount(walletTotalShares, _percentage);
        walletTotalShares += sharesToBeAllocated;
        shares[_walletAddress] = sharesToBeAllocated;
    }

    /**
     * @notice  Method1: Remove the shares of the wallet from circulation
     * @param _walletAddress    wallet address that needs to be removed from allocation
     */
    function removeWalletShareM1(address _walletAddress) public onlyOwner {
        uint256 walletShares = shares[_walletAddress];
        walletTotalShares -= walletShares;
        shares[_walletAddress] = 0;
    }

    /**
     * @notice  Method2: Allocate wallet's shares to the foundation
     * @param _walletAddress    wallet address that needs to be removed from allocation
     */
    function removeWalletShareM2(address _walletAddress) public onlyOwner {
        uint256 walletShares = shares[_walletAddress];
        shares[FOUNDATION] += walletShares;
        shares[_walletAddress] = 0;
    }

    /**
     * @notice  Increases a wallet's allocation to new percentage
     * @param _walletAddress    wallet address whose allocation needs to be increased
     * @param _newPercentage     Percentage struct for new percentage share allocation of wallet
     */
    function increaseWalletShares(address _walletAddress, Percentage memory _newPercentage) public onlyOwner {
        if (_newPercentage.percentageNumber / 10 ^ _newPercentage.decimalPlaces >= 100) revert IncorrectPercentage();
        uint256 allocatedWalletShares = shares[_walletAddress];
        // totalSharesParam as total shares excluding allocated to the wallet
        uint256 newWalletShares = getSharesAmount(walletTotalShares - allocatedWalletShares, _newPercentage);

        // new percentage is lower than already allocated shares%
        if (newWalletShares < allocatedWalletShares) revert IncorrectPercentage();
        walletTotalShares = walletTotalShares + newWalletShares - allocatedWalletShares;
        shares[_walletAddress] = newWalletShares;
    }

    /**
     * @notice  Decreases a wallet's allocation to new percentage using Method 1
     * @param _walletAddress    wallet address whose allocation needs to be decreased
     * @param _newPercentage     Percentage struct for new percentage share allocation of wallet
     */
    function decreaseWalletSharesM1(address _walletAddress, Percentage memory _newPercentage) public onlyOwner {
        if (_newPercentage.percentageNumber / 10 ^ _newPercentage.decimalPlaces >= 100) revert IncorrectPercentage();

        removeWalletShareM1(_walletAddress);
        addWalletShare(_walletAddress, _newPercentage);
    }

    /**
     * @notice  Decreases a wallet's allocation to new percentage using Method 2
     * @param _walletAddress    wallet address whose allocation needs to be decreased
     * @param _newPercentage     Percentage struct for new percentage share allocation of wallet
     */
    function decreaseWalletSharesM2(address _walletAddress, Percentage memory _newPercentage) public onlyOwner {
        if (_newPercentage.percentageNumber / 10 ^ _newPercentage.decimalPlaces >= 100) revert IncorrectPercentage();

        removeWalletShareM2(_walletAddress);
        addWalletShare(_walletAddress, _newPercentage);
    }
}
