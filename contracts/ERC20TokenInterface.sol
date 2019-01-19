pragma solidity >=0.5.0 <0.6.0;

contract ERC20TokenInterface
{
    /// @notice 预挖数量
    uint256 public perMinerAmount;
    /// @notice 日Pos最大值
    uint256 public everDayPosTokenAmount;
    /// @notice 最大记录Pos产出记录的数量
    uint16  public maxRemeberPosRecord;
    /// @notice 签约参与Pos的最小值
    uint256 public joinPosMinAmount;
    /// @notice （可选）开始解仓的时间，后期使用外部API进行设定
    uint256 public startUnlockDataTime;
    /// @notice 空投支出地址
    address public airdropAddress;
    /// @notice 成功写入Posout记录的转账人的奖励
    uint256 public posoutWriterReward;

    /// @notice 签约参与Pos挖矿
    /// @param amount ：参与数量
    /// @return success ： 参与是否成功
    function DespoitToPos(uint256 amount) public returns (bool success);

    /// @notice 获取所有已经完成签约的Pos挖矿的详细信息
    /// @return len ： 数据长度
    /// @return amount ： 数量
    /// @return depositTime ： 参与时间（block时间）
    /// @return lastWithDrawTime ： 最近一次提取的时间
    /// @return prefix ： 记录对应未领取的收益数量
    function GetPosRecords() public view returns ( uint len, uint256[] memory amount, uint256[] memory depositTime, uint256[] memory lastWithDrawTime, uint256[] memory prefix );

    /// @notice 提取参与Pos的余额与收益，解除合约
    /// @param posRecordIndex ： 记录检索号
    /// @return posProfit ： 收益数量
    /// @return amount ： 参与的数量
    /// @return distantPosoutTime ： 设置到最后一次Posout的时间戳
    function RescissionPosAt(uint posRecordIndex) public returns (uint256 posProfit, uint256 amount, uint256 distantPosoutTime);

    /// @notice 一次性提取所有Pos参与记录的本金和收益
    /// @return amountTotalSum ： 参与数量总和
    /// @return profitTotalSum ： 收益总数
    function RescissionPosAll() public returns (uint256 amountTotalSum, uint256 profitTotalSum);

    /// @notice 获取Pos池总数
    /// @return sum ：数量
    function GetCurrentPosSum() public view returns (uint256 sum);

    /// @notice 获取当前所有Posout记录
    /// @return len ： 数据长度
    /// @return posouttotal ： 对应的pos唱出最大值
    /// @return profitByCoin ： 每个最小精度一个代币获得收益
    /// @return posoutTime ： 产出时间
    function GetPosoutLists() public view returns ( uint len, uint256[] memory posouttotal, uint256[] memory profitByCoin, uint256[] memory posoutTime);

    /// @notice 提取指定Pos记录的收益
    /// @return profit ： 收益数量
    /// @return posAmount ： 参与Pos的数量
    function WithDrawPosProfit(uint posRecordIndex) public returns (uint256 profit, uint256 posAmount);

    /// @notice 提取所有Pos记录产生的收益
    /// @return profitSum ： 收益总和
    /// @return posAmountSum ： 投入的总和
    function WithDrawPosAllProfit() public returns (uint256 profitSum, uint256 posAmountSum);

    /// @notice 获取用户的所有锁仓记录
    /// @return len ： 数据长度
    /// @return totalAmount ：记录的锁定总数
    /// @return withdrawAmount ： 已经提取的总数
    /// @return lastWithdrawTime ： 最近一次提取的时间
    /// @return lockDays ： 锁定的时间
    /// @return profit ： 当前本条记录可以领取的收益
    function GetLockRecords() public view returns ( uint len, uint256[] memory totalAmount, uint256[] memory withdrawAmount, uint256[] memory lastWithdrawTime, uint16[] memory lockDays, uint256[] memory profit);

    /// @notice 提取锁仓记录的释放量
    /// @return profit ： 收益
    function WithDrawLockRecordProFit(uint rid) public returns (uint256 profit);

    /// @notice 提取所有锁仓记录的释放量
    /// @return profitTotal ： 收益总数
    function WithDrawLockRecordAllProfit() public returns (uint256 profitTotal);

    uint256 public totalSupply;
    string  public name;     //名称，例如"My test token"
    uint8   public decimals;  //返回token使用的小数点后几位。比如如果设置为3，就是支持0.001表示.
    string  public symbol;   //token简称,like MTT

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
