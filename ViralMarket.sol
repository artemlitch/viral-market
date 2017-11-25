contract ViralMarket {
    struct SearchTermCoin {
        uint256 totalCoinsMinted;
        bool dead;
    }
    
    address internal admin;
    uint256 constant UNIT_COIN = 1e18;
    uint256 constant DEAD_COIN_PRICE = 1e6 wei;
    uint256 constant FIRST_COIN_PRICE = 0.00001 ether;
    uint256 constant PRICE_HALF_LIFE = 1000 * UNIT_COIN;
    
    mapping(bytes32 => SearchTermCoin) searchTermToSupply;     
    mapping(address => mapping (bytes32 => uint256)) balances;
    
    function ViralMarket() {
        admin = msg.sender;    
    }
    
    function calculateCurrentCoinPrice(uint256 currentSupply) internal pure returns (uint256 currentPrice) {
        uint256 numberOfPriceDoublings = currentSupply / PRICE_HALF_LIFE;
        currentPrice = FIRST_COIN_PRICE << numberOfPriceDoublings;
    }
    
    function getCurrentExchangeRate(bytes32 searchTerm) public view returns (uint256 currentPrice) {
        SearchTermCoin storage searchTermCoin = searchTermToSupply[searchTerm];
        return calculateCurrentCoinPrice(searchTermCoin.totalCoinsMinted);
    }
    
    function isSearchTermDead(bytes32 searchTerm) public view returns (bool isDead) {
        SearchTermCoin storage searchTermCoin = searchTermToSupply[searchTerm];
        return searchTermCoin.dead;    
    }
    
    function setSearchTermDead(bytes32 searchTerm) public {
        if (msg.sender == admin) {
            SearchTermCoin storage searchTermCoin = searchTermToSupply[searchTerm];           
            searchTermCoin.dead = true;
        }
    }
    
    function mintCoin(bytes32 searchTerm) public payable {
        uint256 ethToConvert = msg.value;
        uint256 coinsMinted = 0;
        SearchTermCoin storage searchTermCoin = searchTermToSupply[searchTerm];
        if (searchTermCoin.dead) {
            coinsMinted = ethToConvert * UNIT_COIN / DEAD_COIN_PRICE;
        } else {
            uint256 coinSupply = searchTermCoin.totalCoinsMinted;
            while (ethToConvert != 0) {
                uint256 currentPrice = calculateCurrentCoinPrice(coinSupply);
                uint256 coinsLeftInBracket = PRICE_HALF_LIFE - (coinSupply % PRICE_HALF_LIFE);
                uint256 coinsBuyable = ethToConvert / currentPrice;
                uint256 coinsBought;
                if (coinsBuyable <= coinsLeftInBracket) {
                    coinsBought = coinsBuyable;
                } else {
                    coinsBought = coinsLeftInBracket;
                }
                coinsMinted += coinsBought;
                ethToConvert -= coinsBuyable * currentPrice;
            }
        }
        searchTermCoin.totalCoinsMinted += coinsMinted;
        balances[msg.sender][searchTerm] += coinsMinted;
    }
    
    function transfer(address recipient, bytes32 searchTerm, uint256 amount) public returns (bool) {
        if (balances[msg.sender][searchTerm] < amount ||
            balances[recipient][searchTerm] + amount < balances[recipient][searchTerm] ||
            balances[msg.sender][searchTerm] + amount < balances[msg.sender][searchTerm]) {
            return false;
        }
        balances[msg.sender][searchTerm] -= amount;
        balances[recipient][searchTerm] += amount;
        return true;
    }
    
}
