/**
 * EIP712前端签名生成示例
 * 
 * 这个脚本展示了如何在前端（使用ethers.js或web3.js）生成EIP712签名
 * 然后调用合约的permit函数
 */

// 使用ethers.js v6的示例
const { ethers } = require('ethers');

/**
 * EIP712域定义
 */
const EIP712_DOMAIN = {
    name: 'EIP712 Test Token',
    version: '1',
    chainId: 11155111, // Sepolia测试网
    verifyingContract: '0x...' // 合约地址，需要替换为实际部署的地址
};

/**
 * Permit类型定义
 */
const PERMIT_TYPE = {
    Permit: [
        { name: 'owner', type: 'address' },
        { name: 'spender', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
    ]
};

/**
 * Transfer类型定义
 */
const TRANSFER_TYPE = {
    Transfer: [
        { name: 'from', type: 'address' },
        { name: 'to', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
    ]
};

/**
 * 生成Permit签名
 */
async function generatePermitSignature(signer, contractAddress, permitData) {
    // 更新域定义中的合约地址
    const domain = {
        ...EIP712_DOMAIN,
        verifyingContract: contractAddress
    };
    
    try {
        // 使用ethers.js生成签名
        const signature = await signer.signTypedData(domain, PERMIT_TYPE, permitData);
        
        // 分解签名
        const { v, r, s } = ethers.Signature.from(signature);
        
        return { v, r, s, signature };
    } catch (error) {
        console.error('签名生成失败:', error);
        throw error;
    }
}

/**
 * 生成Transfer签名
 */
async function generateTransferSignature(signer, contractAddress, transferData) {
    const domain = {
        ...EIP712_DOMAIN,
        verifyingContract: contractAddress
    };
    
    try {
        const signature = await signer.signTypedData(domain, TRANSFER_TYPE, transferData);
        const { v, r, s } = ethers.Signature.from(signature);
        
        return { v, r, s, signature };
    } catch (error) {
        console.error('转账签名生成失败:', error);
        throw error;
    }
}

/**
 * 完整的Permit工作流程示例
 */
async function permitWorkflowExample() {
    console.log('🚀 开始EIP712 Permit工作流程演示');
    
    // 1. 连接到区块链网络
    const provider = new ethers.JsonRpcProvider('https://sepolia.infura.io/v3/YOUR_PROJECT_ID');
    const wallet = new ethers.Wallet('YOUR_PRIVATE_KEY', provider);
    
    // 2. 连接到合约
    const contractAddress = '0x...'; // 替换为实际合约地址
    const contractABI = [
        // 这里需要添加合约的ABI
        'function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)',
        'function getNonce(address user) view returns (uint256)',
        'function allowance(address owner, address spender) view returns (uint256)'
    ];
    
    const contract = new ethers.Contract(contractAddress, contractABI, wallet);
    
    try {
        // 3. 准备permit参数
        const owner = wallet.address;
        const spender = '0x742d35Cc6634C0532925a3b8D0C9e3e0C8b0e5e1'; // 示例地址
        const value = ethers.parseEther('1000'); // 1000 tokens
        const deadline = Math.floor(Date.now() / 1000) + 3600; // 1小时后过期
        
        // 4. 获取当前nonce
        const nonce = await contract.getNonce(owner);
        console.log(`📝 当前nonce: ${nonce}`);
        
        // 5. 准备签名数据
        const permitData = {
            owner,
            spender,
            value: value.toString(),
            nonce: nonce.toString(),
            deadline
        };
        
        console.log('📋 Permit数据:', permitData);
        
        // 6. 生成签名
        console.log('✍️ 正在生成EIP712签名...');
        const { v, r, s } = await generatePermitSignature(wallet, contractAddress, permitData);
        
        console.log('✅ 签名生成成功:');
        console.log(`v: ${v}`);
        console.log(`r: ${r}`);
        console.log(`s: ${s}`);
        
        // 7. 调用permit函数
        console.log('📤 正在调用permit函数...');
        const tx = await contract.permit(owner, spender, value, deadline, v, r, s);
        
        console.log(`🔗 交易哈希: ${tx.hash}`);
        
        // 8. 等待交易确认
        const receipt = await tx.wait();
        console.log(`✅ 交易确认，区块号: ${receipt.blockNumber}`);
        
        // 9. 验证授权是否成功
        const allowanceAmount = await contract.allowance(owner, spender);
        console.log(`💰 授权金额: ${ethers.formatEther(allowanceAmount)} tokens`);
        
        console.log('🎉 Permit工作流程完成！');
        
    } catch (error) {
        console.error('❌ 工作流程执行失败:', error);
    }
}

/**
 * 批量签名示例
 */
async function batchSignatureExample() {
    console.log('🔄 批量签名示例');
    
    const provider = new ethers.JsonRpcProvider('https://sepolia.infura.io/v3/YOUR_PROJECT_ID');
    const wallet = new ethers.Wallet('YOUR_PRIVATE_KEY', provider);
    const contractAddress = '0x...';
    
    // 批量生成多个permit签名
    const permits = [
        {
            spender: '0x111...',
            value: ethers.parseEther('100'),
            deadline: Math.floor(Date.now() / 1000) + 3600
        },
        {
            spender: '0x222...',
            value: ethers.parseEther('200'),
            deadline: Math.floor(Date.now() / 1000) + 3600
        },
        {
            spender: '0x333...',
            value: ethers.parseEther('300'),
            deadline: Math.floor(Date.now() / 1000) + 3600
        }
    ];
    
    const signatures = [];
    
    for (let i = 0; i < permits.length; i++) {
        const permitData = {
            owner: wallet.address,
            spender: permits[i].spender,
            value: permits[i].value.toString(),
            nonce: i.toString(), // 简化示例，实际应该从合约获取
            deadline: permits[i].deadline
        };
        
        const signature = await generatePermitSignature(wallet, contractAddress, permitData);
        signatures.push(signature);
        
        console.log(`✅ 第${i + 1}个签名生成完成`);
    }
    
    console.log(`🎯 批量生成了${signatures.length}个签名`);
    return signatures;
}

/**
 * 验证签名的辅助函数
 */
function verifySignatureOffchain(domain, types, value, signature, expectedSigner) {
    try {
        const recoveredAddress = ethers.verifyTypedData(domain, types, value, signature);
        const isValid = recoveredAddress.toLowerCase() === expectedSigner.toLowerCase();
        
        console.log(`🔍 签名验证结果: ${isValid ? '✅ 有效' : '❌ 无效'}`);
        console.log(`预期签名者: ${expectedSigner}`);
        console.log(`恢复的地址: ${recoveredAddress}`);
        
        return isValid;
    } catch (error) {
        console.error('❌ 签名验证失败:', error);
        return false;
    }
}

/**
 * 使用示例
 */
async function main() {
    console.log('🎯 EIP712前端集成示例');
    console.log('================================');
    
    // 注意：在实际使用前，请确保：
    // 1. 替换YOUR_PROJECT_ID为实际的Infura项目ID
    // 2. 替换YOUR_PRIVATE_KEY为实际的私钥（注意安全！）
    // 3. 替换合约地址为实际部署的合约地址
    // 4. 添加完整的合约ABI
    
    console.log('⚠️  请在使用前配置实际的网络参数和合约地址');
    console.log('📚 这个示例展示了EIP712签名的完整流程');
    
    // 演示签名生成（不实际执行）
    const mockSigner = {
        address: '0x1234567890123456789012345678901234567890'
    };
    
    const mockPermitData = {
        owner: mockSigner.address,
        spender: '0x742d35Cc6634C0532925a3b8D0C9e3e0C8b0e5e1',
        value: '1000000000000000000000', // 1000 tokens
        nonce: '0',
        deadline: Math.floor(Date.now() / 1000) + 3600
    };
    
    console.log('📋 示例Permit数据:');
    console.log(JSON.stringify(mockPermitData, null, 2));
    
    console.log('🔧 EIP712域定义:');
    console.log(JSON.stringify(EIP712_DOMAIN, null, 2));
    
    console.log('📝 Permit类型定义:');
    console.log(JSON.stringify(PERMIT_TYPE, null, 2));
}

// 导出函数供其他模块使用
module.exports = {
    generatePermitSignature,
    generateTransferSignature,
    permitWorkflowExample,
    batchSignatureExample,
    verifySignatureOffchain,
    EIP712_DOMAIN,
    PERMIT_TYPE,
    TRANSFER_TYPE
};

// 如果直接运行此脚本
if (require.main === module) {
    main().catch(console.error);
}
