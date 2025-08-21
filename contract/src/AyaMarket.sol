// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
contract AyaMarket is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // === ENUMS === //
    enum Category {
        GRAINS_PACKAGED,
        CRAFTS_ART,
        FASHION,
        HOME_DECOR
    }

    // === STRUCTS === //
    struct Product {
        uint256 id;
        address seller;
        string name;
        Category category;
        uint256 price;
        bool isAvailable;
        string details; // IPFS hash or metadata URI
    }

    struct Order {
        uint256 productId;
        address buyer;
        uint256 amountPaid;
        bool isConfirmed;
        uint256 timestamp;
        bool isReleased;
    }

    // === STATE VARIABLES === //
    mapping(uint256 => Product) public products;
    mapping(uint256 => Order) public orders;
    mapping(address => uint256[]) public sellerProducts;
    mapping(address => uint256) public reputationPoints;

    uint256 public productCounter;
    uint256 public orderCounter;

    uint256 public deliveryTimeout = 3 days;
    IERC20 public stablecoin;
    address public owner;

    // === EVENTS === //
    event ProductListed(uint256 indexed productId, Category indexed category, address indexed seller);
    event OrderPlaced(uint256 indexed orderId, address indexed buyer, uint256 productId);
    event OrderConfirmed(uint256 indexed orderId, address indexed seller);
    event FundsReleased(uint256 indexed orderId, address indexed seller);
    event ReputationUpdated(address indexed user, uint256 newPoints);
    event TimeoutUpdated(uint256 newTimeout);

    // === MODIFIERS === //
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // === CONSTRUCTOR === //
    constructor(address _stablecoin) {
        stablecoin = IERC20(_stablecoin);
        owner = msg.sender;
    }

    // === MAIN FUNCTIONS === //

    function listProduct(
        string memory _name,
        Category _category,
        uint256 _price,
        string memory _details
    ) external {
        require(_price > 0, "Invalid price");

        productCounter++;
        products[productCounter] = Product({
            id: productCounter,
            seller: msg.sender,
            name: _name,
            category: _category,
            price: _price,
            isAvailable: true,
            details: _details
        });

        sellerProducts[msg.sender].push(productCounter);
        emit ProductListed(productCounter, _category, msg.sender);
    }

    function placeOrder(uint256 _productId) external nonReentrant {
        Product storage product = products[_productId];
        require(product.isAvailable, "Unavailable");
        require(stablecoin.allowance(msg.sender, address(this)) >= product.price, "Insufficient allowance");

        stablecoin.safeTransferFrom(msg.sender, address(this), product.price);
        product.isAvailable = false;

        orderCounter++;
        orders[orderCounter] = Order({
            productId: _productId,
            buyer: msg.sender,
            amountPaid: product.price,
            isConfirmed: false,
            timestamp: block.timestamp,
            isReleased: false
        });

        emit OrderPlaced(orderCounter, msg.sender, _productId);
    }

    function confirmDelivery(uint256 _orderId) external nonReentrant {
        Order storage order = orders[_orderId];
        Product memory product = products[order.productId];

        require(msg.sender == order.buyer, "Only buyer");
        require(!order.isConfirmed, "Already confirmed");
        require(!order.isReleased, "Already released");

        order.isConfirmed = true;
        order.isReleased = true;

        stablecoin.safeTransfer(product.seller, order.amountPaid);

        _updateReputation(product.seller, 20);
        _updateReputation(order.buyer, 10);

        emit OrderConfirmed(_orderId, product.seller);
        emit FundsReleased(_orderId, product.seller);
    }

    function releaseAfterTimeout(uint256 _orderId) external nonReentrant {
        Order storage order = orders[_orderId];
        Product memory product = products[order.productId];

        require(!order.isReleased, "Already released");
        require(block.timestamp >= order.timestamp + deliveryTimeout, "Timeout not reached");

        order.isReleased = true;
        stablecoin.safeTransfer(product.seller, order.amountPaid);

        _updateReputation(product.seller, 10); // Less than confirmed delivery
        emit FundsReleased(_orderId, product.seller);
    }

    // === REPUTATION === //

    function _updateReputation(address _user, uint256 _points) internal {
        reputationPoints[_user] += _points;
        emit ReputationUpdated(_user, reputationPoints[_user]);
    }

    // === ADMIN === //

    function updateDeliveryTimeout(uint256 _seconds) external onlyOwner {
        deliveryTimeout = _seconds;
        emit TimeoutUpdated(_seconds);
    }

    // === VIEW FUNCTIONS === //

    function getProductsByCategory(Category _category) external view returns (Product[] memory) {
        uint256 count;
        for (uint256 i = 1; i <= productCounter; i++) {
            if (products[i].category == _category) count++;
        }

        Product[] memory result = new Product[](count);
        uint256 index;

        for (uint256 i = 1; i <= productCounter; i++) {
            if (products[i].category == _category) {
                result[index] = products[i];
                index++;
            }
        }

        return result;
    }

    function getSellerProducts(address _seller) external view returns (Product[] memory) {
        uint256[] memory ids = sellerProducts[_seller];
        Product[] memory result = new Product[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = products[ids[i]];
        }

        return result;
    }
}