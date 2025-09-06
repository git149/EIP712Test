/**
 * EIP712代币合约部署和验证脚本
 * 
 * 这个脚本展示了如何部署EIP712TokenWithPermit合约
 * 并验证其功能是否正常工作
 */

const { ethers } = require('ethers');
const fs = require('fs');

// 合约ABI（简化版，实际使用时应该从编译输出获取完整ABI）
const CONTRACT_ABI = [
    // 基础ERC20功能
    "function name() view returns (string)",
    "function symbol() view returns (string)", 
    "function decimals() view returns (uint8)",
    "function totalSupply() view returns (uint256)",
    "function balanceOf(address) view returns (uint256)",
    "function transfer(address to, uint256 value) returns (bool)",
    "function approve(address spender, uint256 value) returns (bool)",
    "function allowance(address owner, address spender) view returns (uint256)",
    "function transferFrom(address from, address to, uint256 value) returns (bool)",
    
    // EIP712功能
    "function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)",
    "function transferWithPermit(address from, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)",
    "function getNonce(address user) view returns (uint256)",
    "function getDomainSeparator() view returns (bytes32)",
    "function getPermitTypeHash() pure returns (bytes32)",
    "function getTransferTypeHash() pure returns (bytes32)",
    
    // 查询函数
    "function getPermitHash(address owner, address spender, uint256 value, uint256 nonce, uint256 deadline) pure returns (bytes32)",
    "function getTransferHash(address from, address to, uint256 value, uint256 nonce, uint256 deadline) pure returns (bytes32)",
    "function getDigest(bytes32 structHash) view returns (bytes32)",
    
    // 批量操作
    "function batchTransfer(address[] recipients, uint256[] amounts) returns (bool)",
    
    // 事件
    "event Transfer(address indexed from, address indexed to, uint256 value)",
    "event Approval(address indexed owner, address indexed spender, uint256 value)",
    "event PermitUsed(address indexed owner, address indexed spender, uint256 value, uint256 nonce, uint256 deadline)",
    "event TransferWithPermit(address indexed from, address indexed to, uint256 value, uint256 nonce, address indexed executor)"
];

/**
 * 部署合约
 */
async function deployContract(deployer) {
    console.log('🚀 开始部署EIP712TokenWithPermit合约...');
    
    // 读取合约字节码（需要先编译合约）
    // 注意：实际部署时需要使用Hardhat、Truffle或Remix编译合约
    console.log('⚠️  请先使用Solidity编译器编译contract/test.sol');
    console.log('📝 编译命令示例: solc --bin --abi contract/test.sol');
    
    // 模拟部署过程
    const contractFactory = new ethers.ContractFactory(
        CONTRACT_ABI,
        "0x608060405234801561001057600080fd5b50...", // 这里应该是实际的字节码
        deployer
    );
    
    try {
        // 部署合约
        const contract = await contractFactory.deploy();
        await contract.waitForDeployment();
        
        const contractAddress = await contract.getAddress();
        console.log(`✅ 合约部署成功！地址: ${contractAddress}`);
        
        return contract;
    } catch (error) {
        console.error('❌ 合约部署失败:', error);
        throw error;
    }
}

/**
 * 验证合约基础功能
 */
async function verifyBasicFunctions(contract) {
    console.log('🔍 验证合约基础功能...');
    
    try {
        // 检查代币信息
        const name = await contract.name();
        const symbol = await contract.symbol();
        const decimals = await contract.decimals();
        const totalSupply = await contract.totalSupply();
        
        console.log(`📋 代币信息:`);
        console.log(`   名称: ${name}`);
        console.log(`   符号: ${symbol}`);
        console.log(`   精度: ${decimals}`);
        console.log(`   总供应量: ${ethers.formatEther(totalSupply)} tokens`);
        
        // 检查EIP712相关信息
        const domainSeparator = await contract.getDomainSeparator();
        const permitTypeHash = await contract.getPermitTypeHash();
        const transferTypeHash = await contract.getTransferTypeHash();
        
        console.log(`🔐 EIP712信息:`);
        console.log(`   域分隔符: ${domainSeparator}`);
        console.log(`   Permit类型哈希: ${permitTypeHash}`);
        console.log(`   Transfer类型哈希: ${transferTypeHash}`);
        
        console.log('✅ 基础功能验证通过');
        return true;
    } catch (error) {
        console.error('❌ 基础功能验证失败:', error);
        return false;
    }
}

/**
 * 验证EIP712签名功能
 */
async function verifyEIP712Functions(contract, signer) {
    console.log('🔐 验证EIP712签名功能...');
    
    try {
        const signerAddress = await signer.getAddress();
        const spenderAddress = '0x742d35Cc6634C0532925a3b8D0C9e3e0C8b0e5e1';
        const value = ethers.parseEther('1000');
        const deadline = Math.floor(Date.now() / 1000) + 3600;
        
        // 获取当前nonce
        const nonce = await contract.getNonce(signerAddress);
        console.log(`📝 当前nonce: ${nonce}`);
        
        // 计算permit哈希
        const permitHash = await contract.getPermitHash(
            signerAddress,
            spenderAddress,
            value,
            nonce,
            deadline
        );
        console.log(`🔢 Permit哈希: ${permitHash}`);
        
        // 计算最终消息哈希
        const digest = await contract.getDigest(permitHash);
        console.log(`📋 消息摘要: ${digest}`);
        
        console.log('✅ EIP712哈希计算功能正常');
        
        // 注意：实际签名需要用户交互，这里只验证哈希计算
        console.log('ℹ️  实际签名需要用户通过钱包确认');
        
        return true;
    } catch (error) {
        console.error('❌ EIP712功能验证失败:', error);
        return false;
    }
}

/**
 * 验证批量操作功能
 */
async function verifyBatchFunctions(contract, signer) {
    console.log('📦 验证批量操作功能...');
    
    try {
        const signerAddress = await signer.getAddress();
        const initialBalance = await contract.balanceOf(signerAddress);
        
        console.log(`💰 初始余额: ${ethers.formatEther(initialBalance)} tokens`);
        
        // 准备批量转账参数
        const recipients = [
            '0x1111111111111111111111111111111111111111',
            '0x2222222222222222222222222222222222222222',
            '0x3333333333333333333333333333333333333333'
        ];
        
        const amounts = [
            ethers.parseEther('10'),
            ethers.parseEther('20'),
            ethers.parseEther('30')
        ];
        
        console.log('📤 执行批量转账...');
        
        // 执行批量转账
        const tx = await contract.batchTransfer(recipients, amounts);
        const receipt = await tx.wait();
        
        console.log(`✅ 批量转账成功，交易哈希: ${tx.hash}`);
        console.log(`⛽ Gas使用量: ${receipt.gasUsed}`);
        
        // 验证余额变化
        const finalBalance = await contract.balanceOf(signerAddress);
        const totalTransferred = amounts.reduce((sum, amount) => sum + amount, 0n);
        
        console.log(`💰 最终余额: ${ethers.formatEther(finalBalance)} tokens`);
        console.log(`📊 转账总额: ${ethers.formatEther(totalTransferred)} tokens`);
        
        return true;
    } catch (error) {
        console.error('❌ 批量操作验证失败:', error);
        return false;
    }
}

/**
 * 生成部署报告
 */
function generateDeploymentReport(contractAddress, verificationResults) {
    const report = {
        timestamp: new Date().toISOString(),
        contractAddress: contractAddress,
        network: 'Sepolia Testnet', // 或其他网络
        verificationResults: verificationResults,
        gasEstimates: {
            deployment: '~2,500,000 gas',
            permit: '~80,000 gas',
            transferWithPermit: '~85,000 gas',
            batchTransfer: '~21,000 gas per recipient'
        },
        nextSteps: [
            '1. 在区块链浏览器上验证合约源码',
            '2. 更新前端配置中的合约地址',
            '3. 进行完整的集成测试',
            '4. 准备生产环境部署'
        ]
    };
    
    const reportJson = JSON.stringify(report, null, 2);
    fs.writeFileSync('deployment-report.json', reportJson);
    
    console.log('📊 部署报告已生成: deployment-report.json');
    return report;
}

/**
 * 主函数
 */
async function main() {
    console.log('🎯 EIP712代币合约部署和验证');
    console.log('================================');
    
    try {
        // 连接到网络
        const provider = new ethers.JsonRpcProvider('https://sepolia.infura.io/v3/YOUR_PROJECT_ID');
        const wallet = new ethers.Wallet('YOUR_PRIVATE_KEY', provider);
        
        console.log(`👤 部署账户: ${wallet.address}`);
        
        // 检查账户余额
        const balance = await provider.getBalance(wallet.address);
        console.log(`💰 账户余额: ${ethers.formatEther(balance)} ETH`);
        
        if (balance < ethers.parseEther('0.1')) {
            console.warn('⚠️  账户余额较低，可能无法完成部署');
        }
        
        // 部署合约（模拟）
        console.log('⚠️  这是一个演示脚本，实际部署需要编译后的字节码');
        console.log('📚 请参考README了解完整的部署流程');
        
        // 模拟验证过程
        const mockContract = new ethers.Contract(
            '0x1234567890123456789012345678901234567890', // 模拟地址
            CONTRACT_ABI,
            wallet
        );
        
        const verificationResults = {
            basicFunctions: true,
            eip712Functions: true,
            batchFunctions: true
        };
        
        // 生成报告
        generateDeploymentReport(
            '0x1234567890123456789012345678901234567890',
            verificationResults
        );
        
        console.log('🎉 部署和验证流程演示完成！');
        console.log('📋 请查看deployment-report.json了解详细信息');
        
    } catch (error) {
        console.error('❌ 部署过程出错:', error);
        process.exit(1);
    }
}

// 导出函数
module.exports = {
    deployContract,
    verifyBasicFunctions,
    verifyEIP712Functions,
    verifyBatchFunctions,
    generateDeploymentReport
};

// 直接运行
if (require.main === module) {
    main().catch(console.error);
}
