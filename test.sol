//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title EIP712TokenWithPermit
 * @notice 基于EIP712标准的代币合约，支持permit功能
 * @dev 这是一个学习和测试用的简化版本，展示EIP712签名验证的核心实现
 *
 * EIP712核心概念：
 * 1. 域分隔符（Domain Separator）：确保签名只在特定合约和链上有效
 * 2. 类型哈希（Type Hash）：定义结构化数据的格式
 * 3. 结构化数据哈希：将用户数据按照EIP712标准进行哈希
 * 4. 签名验证：使用ecrecover恢复签名者地址
 * 5. Nonce机制：防止重放攻击
 */
contract EIP712TokenWithPermit {

    // ===== 基础代币功能 =====

    string public name = "EIP712 Test Token";
    string public symbol = "EIP712";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10**18; // 100万代币

    // 余额映射
    mapping(address => uint256) public balanceOf;

    // 授权映射：owner => spender => amount
    mapping(address => mapping(address => uint256)) public allowance;

    // ===== EIP712核心常量 =====

    // EIP712域分隔符类型哈希
    // 这个哈希定义了域分隔符的结构：name, version, chainId, verifyingContract
    bytes32 private constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    // Permit类型哈希
    // 定义permit函数的参数结构
    bytes32 private constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    // Transfer类型哈希（额外功能：支持代理转账）
    bytes32 private constant TRANSFER_TYPEHASH = keccak256(
        "Transfer(address from,address to,uint256 value,uint256 nonce,uint256 deadline)"
    );

    // ===== EIP712状态变量 =====

    // 域分隔符：在构造函数中计算，确保签名只在当前合约和链上有效
    bytes32 public DOMAIN_SEPARATOR;

    // 用户nonce映射：防止重放攻击
    // 每个用户的nonce在每次使用后递增
    mapping(address => uint256) public nonces;

    // ===== 事件定义 =====

    // 标准ERC20事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP712相关事件
    event PermitUsed(
        address indexed owner,
        address indexed spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    );

    event TransferWithPermit(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 nonce,
        address indexed executor
    );

    // ===== 构造函数 =====

    constructor() {
        // 给部署者分配所有代币
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);

        // 计算EIP712域分隔符
        // 这个分隔符确保签名只在当前合约和链上有效
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),           // 合约名称
                keccak256(bytes("1")),            // 版本号
                block.chainid,                    // 链ID
                address(this)                     // 合约地址
            )
        );
    }

    // ===== 基础ERC20功能 =====

    /**
     * @notice 转账功能
     * @param to 接收者地址
     * @param value 转账金额
     * @return bool 是否成功
     */
    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice 授权功能
     * @param spender 被授权者地址
     * @param value 授权金额
     * @return bool 是否成功
     */
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice 代理转账功能
     * @param from 发送者地址
     * @param to 接收者地址
     * @param value 转账金额
     * @return bool 是否成功
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    // ===== EIP712核心实现 =====

    /**
     * @notice EIP712 Permit函数 - 核心功能
     * @dev 允许用户通过签名授权代币转移，避免单独的approve交易
     *
     * 工作流程：
     * 1. 用户在链下生成EIP712签名
     * 2. 第三方调用此函数，提供签名参数
     * 3. 合约验证签名有效性
     * 4. 执行授权操作
     *
     * @param owner 代币拥有者（签名者）
     * @param spender 被授权者
     * @param value 授权金额
     * @param deadline 签名过期时间戳
     * @param v 签名参数v
     * @param r 签名参数r
     * @param s 签名参数s
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // 1. 验证签名未过期
        require(block.timestamp <= deadline, "EIP712: permit expired");

        // 2. 构造结构化数据哈希
        // 这是EIP712的核心：将参数按照预定义格式进行哈希
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,    // 类型哈希
                owner,              // 代币拥有者
                spender,            // 被授权者
                value,              // 授权金额
                nonces[owner],      // 当前nonce
                deadline            // 过期时间
            )
        );

        // 3. 验证EIP712签名
        require(
            _verifySignature(structHash, owner, v, r, s),
            "EIP712: invalid signature"
        );

        // 4. 增加nonce防止重放攻击
        nonces[owner]++;

        // 5. 执行授权
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);

        // 6. 发出permit使用事件
        emit PermitUsed(owner, spender, value, nonces[owner] - 1, deadline);
    }

    /**
     * @notice 通过EIP712签名进行代理转账
     * @dev 扩展功能：允许用户签名授权转账，第三方代为执行
     *
     * @param from 发送者（签名者）
     * @param to 接收者
     * @param value 转账金额
     * @param deadline 签名过期时间戳
     * @param v 签名参数v
     * @param r 签名参数r
     * @param s 签名参数s
     */
    function transferWithPermit(
        address from,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "EIP712: transfer permit expired");
        require(to != address(0), "Transfer to zero address");
        require(balanceOf[from] >= value, "Insufficient balance");

        // 构造转账许可的结构化数据哈希
        bytes32 structHash = keccak256(
            abi.encode(
                TRANSFER_TYPEHASH,
                from,
                to,
                value,
                nonces[from],
                deadline
            )
        );

        // 验证签名
        require(
            _verifySignature(structHash, from, v, r, s),
            "EIP712: invalid transfer signature"
        );

        // 增加nonce
        nonces[from]++;

        // 执行转账
        balanceOf[from] -= value;
        balanceOf[to] += value;

        emit Transfer(from, to, value);
        emit TransferWithPermit(from, to, value, nonces[from] - 1, msg.sender);
    }

    // ===== 内部辅助函数 =====

    /**
     * @notice 验证EIP712签名
     * @dev 这是EIP712签名验证的核心逻辑
     *
     * 验证步骤：
     * 1. 构造最终的消息哈希（digest）
     * 2. 使用ecrecover恢复签名者地址
     * 3. 验证恢复的地址是否与预期签名者匹配
     *
     * @param structHash 结构化数据哈希
     * @param signer 预期的签名者地址
     * @param v 签名参数v
     * @param r 签名参数r
     * @param s 签名参数s
     * @return bool 签名是否有效
     */
    function _verifySignature(
        bytes32 structHash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        // 构造EIP712消息哈希
        // 格式：keccak256("\x19\x01" + DOMAIN_SEPARATOR + structHash)
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",         // EIP712魔法值
                DOMAIN_SEPARATOR,   // 域分隔符
                structHash          // 结构化数据哈希
            )
        );

        // 使用ecrecover恢复签名者地址
        address recoveredSigner = ecrecover(digest, v, r, s);

        // 验证恢复的地址是否匹配且不为零地址
        return recoveredSigner == signer && recoveredSigner != address(0);
    }

    // ===== 查询函数 =====

    /**
     * @notice 获取用户当前nonce
     * @param user 用户地址
     * @return uint256 当前nonce值
     */
    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }

    /**
     * @notice 获取域分隔符
     * @return bytes32 域分隔符
     */
    function getDomainSeparator() external view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

    /**
     * @notice 获取Permit类型哈希
     * @return bytes32 Permit类型哈希
     */
    function getPermitTypeHash() external pure returns (bytes32) {
        return PERMIT_TYPEHASH;
    }

    /**
     * @notice 获取Transfer类型哈希
     * @return bytes32 Transfer类型哈希
     */
    function getTransferTypeHash() external pure returns (bytes32) {
        return TRANSFER_TYPEHASH;
    }

    /**
     * @notice 计算permit的结构化数据哈希（用于前端签名生成）
     * @param owner 代币拥有者
     * @param spender 被授权者
     * @param value 授权金额
     * @param nonce 当前nonce
     * @param deadline 过期时间
     * @return bytes32 结构化数据哈希
     */
    function getPermitHash(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) external pure returns (bytes32) {
        return keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );
    }

    /**
     * @notice 计算transfer的结构化数据哈希（用于前端签名生成）
     * @param from 发送者
     * @param to 接收者
     * @param value 转账金额
     * @param nonce 当前nonce
     * @param deadline 过期时间
     * @return bytes32 结构化数据哈希
     */
    function getTransferHash(
        address from,
        address to,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) external pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TRANSFER_TYPEHASH,
                from,
                to,
                value,
                nonce,
                deadline
            )
        );
    }

    /**
     * @notice 计算最终的EIP712消息哈希（用于前端签名生成）
     * @param structHash 结构化数据哈希
     * @return bytes32 最终消息哈希
     */
    function getDigest(bytes32 structHash) external view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                structHash
            )
        );
    }

    // ===== 批量操作功能 =====

    /**
     * @notice 批量转账功能
     * @param recipients 接收者地址数组
     * @param amounts 转账金额数组
     * @return bool 是否全部成功
     */
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external returns (bool) {
        require(recipients.length == amounts.length, "Array length mismatch");
        require(recipients.length > 0, "Empty arrays");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(balanceOf[msg.sender] >= totalAmount, "Insufficient balance");

        balanceOf[msg.sender] -= totalAmount;

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Transfer to zero address");
            balanceOf[recipients[i]] += amounts[i];
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }

        return true;
    }
}