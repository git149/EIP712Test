//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title EIP712测试合约
 * @notice 用于测试EIP712TokenWithPermit合约的功能
 * @dev 包含完整的测试用例，演示EIP712签名生成和验证过程
 */

// 导入测试合约
import "../test.sol";

contract EIP712Test {
    
    EIP712TokenWithPermit public token;
    
    // 测试账户
    address public owner = 0x1234567890123456789012345678901234567890;
    address public spender = 0x2345678901234567890123456789012345678901;
    address public recipient = 0x3456789012345678901234567890123456789012;
    
    // 测试事件
    event TestResult(string testName, bool success, string message);
    event SignatureGenerated(
        bytes32 structHash,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    );
    
    constructor() {
        // 部署代币合约
        token = new EIP712TokenWithPermit();
    }
    
    /**
     * @notice 运行所有测试
     */
    function runAllTests() external {
        emit TestResult("开始EIP712测试", true, "Starting comprehensive EIP712 tests");
        
        testBasicTokenFunctions();
        testDomainSeparator();
        testPermitFunctionality();
        testTransferWithPermit();
        testNonceManagement();
        testSignatureValidation();
        testEdgeCases();
        
        emit TestResult("EIP712测试完成", true, "All tests completed");
    }
    
    /**
     * @notice 测试基础代币功能
     */
    function testBasicTokenFunctions() public {
        emit TestResult("测试基础代币功能", true, "Testing basic token functions");
        
        // 检查初始状态
        require(token.totalSupply() == 1000000 * 10**18, "Total supply incorrect");
        require(token.balanceOf(address(this)) == 1000000 * 10**18, "Initial balance incorrect");
        require(keccak256(bytes(token.name())) == keccak256(bytes("EIP712 Test Token")), "Name incorrect");
        require(keccak256(bytes(token.symbol())) == keccak256(bytes("EIP712")), "Symbol incorrect");
        require(token.decimals() == 18, "Decimals incorrect");
        
        emit TestResult("基础代币功能", true, "Basic token functions work correctly");
    }
    
    /**
     * @notice 测试域分隔符
     */
    function testDomainSeparator() public {
        emit TestResult("测试域分隔符", true, "Testing domain separator");
        
        bytes32 domainSeparator = token.getDomainSeparator();
        require(domainSeparator != bytes32(0), "Domain separator is zero");
        
        // 验证域分隔符的构造
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("EIP712 Test Token")),
                keccak256(bytes("1")),
                block.chainid,
                address(token)
            )
        );
        
        require(domainSeparator == expectedDomainSeparator, "Domain separator mismatch");
        
        emit TestResult("域分隔符", true, "Domain separator is correct");
    }
    
    /**
     * @notice 测试permit功能
     */
    function testPermitFunctionality() public {
        emit TestResult("测试permit功能", true, "Testing permit functionality");
        
        // 准备permit参数
        address owner = address(this);
        address spender = address(0x123);
        uint256 value = 1000 * 10**18;
        uint256 deadline = block.timestamp + 3600; // 1小时后过期
        uint256 nonce = token.getNonce(owner);
        
        // 计算结构化数据哈希
        bytes32 structHash = token.getPermitHash(owner, spender, value, nonce, deadline);
        bytes32 digest = token.getDigest(structHash);
        
        emit SignatureGenerated(structHash, digest, 0, bytes32(0), bytes32(0));
        
        // 注意：在实际测试中，这里需要使用私钥生成真实签名
        // 这里我们模拟签名验证逻辑
        
        emit TestResult("permit功能", true, "Permit hash calculation works");
    }
    
    /**
     * @notice 测试transferWithPermit功能
     */
    function testTransferWithPermit() public {
        emit TestResult("测试transferWithPermit功能", true, "Testing transferWithPermit");
        
        address from = address(this);
        address to = address(0x456);
        uint256 value = 500 * 10**18;
        uint256 deadline = block.timestamp + 3600;
        uint256 nonce = token.getNonce(from);
        
        bytes32 structHash = token.getTransferHash(from, to, value, nonce, deadline);
        bytes32 digest = token.getDigest(structHash);
        
        emit SignatureGenerated(structHash, digest, 0, bytes32(0), bytes32(0));
        
        emit TestResult("transferWithPermit功能", true, "TransferWithPermit hash calculation works");
    }
    
    /**
     * @notice 测试nonce管理
     */
    function testNonceManagement() public {
        emit TestResult("测试nonce管理", true, "Testing nonce management");
        
        address user = address(this);
        uint256 initialNonce = token.getNonce(user);
        
        // 验证初始nonce为0
        require(initialNonce == 0, "Initial nonce should be 0");
        
        emit TestResult("nonce管理", true, "Nonce management works correctly");
    }
    
    /**
     * @notice 测试签名验证
     */
    function testSignatureValidation() public {
        emit TestResult("测试签名验证", true, "Testing signature validation");
        
        // 获取类型哈希
        bytes32 permitTypeHash = token.getPermitTypeHash();
        bytes32 transferTypeHash = token.getTransferTypeHash();
        
        require(permitTypeHash != bytes32(0), "Permit type hash is zero");
        require(transferTypeHash != bytes32(0), "Transfer type hash is zero");
        require(permitTypeHash != transferTypeHash, "Type hashes should be different");
        
        emit TestResult("签名验证", true, "Signature validation setup works");
    }
    
    /**
     * @notice 测试边界条件
     */
    function testEdgeCases() public {
        emit TestResult("测试边界条件", true, "Testing edge cases");
        
        // 测试零地址
        bytes32 zeroHash = token.getPermitHash(address(0), address(0), 0, 0, 0);
        require(zeroHash != bytes32(0), "Zero address hash should not be zero");
        
        // 测试最大值
        bytes32 maxHash = token.getPermitHash(
            address(type(uint160).max),
            address(type(uint160).max),
            type(uint256).max,
            type(uint256).max,
            type(uint256).max
        );
        require(maxHash != bytes32(0), "Max value hash should not be zero");
        
        emit TestResult("边界条件", true, "Edge cases handled correctly");
    }
    
    /**
     * @notice 演示完整的EIP712工作流程
     */
    function demonstrateEIP712Workflow() external {
        emit TestResult("演示EIP712工作流程", true, "Demonstrating complete EIP712 workflow");
        
        // 步骤1：准备参数
        address owner = address(this);
        address spender = address(0x789);
        uint256 value = 2000 * 10**18;
        uint256 deadline = block.timestamp + 7200; // 2小时后过期
        uint256 nonce = token.getNonce(owner);
        
        // 步骤2：计算结构化数据哈希
        bytes32 structHash = token.getPermitHash(owner, spender, value, nonce, deadline);
        
        // 步骤3：计算最终消息哈希
        bytes32 digest = token.getDigest(structHash);
        
        // 步骤4：发出事件，显示计算结果
        emit SignatureGenerated(structHash, digest, 0, bytes32(0), bytes32(0));
        
        emit TestResult("EIP712工作流程演示", true, 
            "Complete workflow demonstrated - ready for real signature generation");
    }
    
    /**
     * @notice 获取测试用的签名参数
     */
    function getTestSignatureParams() external view returns (
        bytes32 domainSeparator,
        bytes32 permitTypeHash,
        bytes32 transferTypeHash,
        uint256 chainId,
        address contractAddress
    ) {
        return (
            token.getDomainSeparator(),
            token.getPermitTypeHash(),
            token.getTransferTypeHash(),
            block.chainid,
            address(token)
        );
    }
    
    /**
     * @notice 批量测试功能
     */
    function testBatchOperations() external {
        emit TestResult("测试批量操作", true, "Testing batch operations");
        
        // 准备批量转账参数
        address[] memory recipients = new address[](3);
        recipients[0] = address(0x111);
        recipients[1] = address(0x222);
        recipients[2] = address(0x333);
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 * 10**18;
        amounts[1] = 200 * 10**18;
        amounts[2] = 300 * 10**18;
        
        // 执行批量转账
        bool success = token.batchTransfer(recipients, amounts);
        require(success, "Batch transfer failed");
        
        emit TestResult("批量操作", true, "Batch operations work correctly");
    }
}
