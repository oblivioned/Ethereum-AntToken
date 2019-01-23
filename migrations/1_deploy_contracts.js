const ERC20TokenImpl = artifacts.require("ERC20TokenImpl");

// 持币地址，可以是一个地址，也可以是一个合约地址
var TokenOrePool = ""

// 代币的精度
var TokenDecimals = "8"

// 代币名称
var TokenName = "ANT(Coin)"

// 代币符号
var TokenSymbol = "ANT"

// 代币总量（最大精度）
var TokenTotalSupply = "500000000000000000"

// 初始最大记录Pos产出记录的数量
var MaxRemeberPosRecord = "30"

// 参与Pos的最小额度（最大精度）
var JoinPosMinAmountLimit = "10000000000"

// 成功计算Posout记录的用户的奖励（最大精度）
var PosOutWriterReward = "0"

// 锁仓开始释放的时间（时间戳11位，与ETH的时间戳格式相同）
var StartUnlockDataTime = "0"

// 默认是否开启真实释放Pos获得的代币收益
var EnableWithDrawPosProfit = true

// 设置Pos封顶收益率的千分比，比如设置3则是 0.3%， 30则是3%以此类推
var PosMaxPorfitByThousandths = 3

module.exports = function(deployer)
{
  return web3.eth.getAccounts()
  .then(function(accounts) {

      var defaultAccount;

      if (TokenOrePool.length > 0)
      {
          defaultAccount = TokenOrePool;
      }
      else {
          defaultAccount = accounts[0];
      }

      return deployer.deploy( ERC20TokenImpl,
          defaultAccount,
          TokenDecimals,
          TokenName,
          TokenSymbol,
          TokenTotalSupply,
          MaxRemeberPosRecord,
          JoinPosMinAmountLimit,
          PosOutWriterReward,
          StartUnlockDataTime,
          PosMaxPorfitByThousandths,
          EnableWithDrawPosProfit
      );
  })
  .then(function(instnace) {
      return instnace.AddAdmin("0xccd937d168f47c058ba9e68cab61c37b52d76dcf");
  })
  .then(function(tx){
      console.log("   > SetAdmin Success");
  })
};
