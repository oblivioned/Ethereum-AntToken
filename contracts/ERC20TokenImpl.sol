pragma solidity >=0.5.0 <0.6.0;

import "./ERC20TokenInterface.sol";
import "./LockDB.sol";
import "./PosDB.sol";
import "./PosoutDB.sol";
import "./PermissionCtl.sol";
import "./Events.sol";

contract ERC20TokenImpl is ERC20TokenInterface,PermissionCtl,Events
{
  /*********************************** 必须设定的合约初始参数 ***********************************/
  uint256 public decimals;
  string  public name;
  string  public symbol;
  uint256 public totalSupply;

  // 此处使用最大精度(即每天释放多少)
  uint16  public maxRemeberPosRecord;
  uint256 public joinPosMinAmount;
  uint256 public posoutWriterReward;
  /*********************************** 必须设定的合约初始参数 ***********************************/

  /*********************************** 可选设定的合约初始参数 ***********************************/
  // 开始解仓的时间，后期使用外部API进行设定
  uint256 public startUnlockDataTime = 0;
  // 是否开启Pos的收益提取功能，
  // 若设置为false，则所有计算照常就行，但是能提取profit，用户调用event，然后中心化节点接受后执行其他逻辑
  // 若设置为true，所有计算照常就行，并且用户提取时一并方法收益，也会提交event，中心化节点依然可以监控就行其他操作
  bool enableWithDrawPosProfit = false;
  uint256 posMaxPorfitByThousandths = 3;
  /*********************************** 可选设定的合约初始参数 ***********************************/

  mapping (address => uint256) _balanceMap;
  mapping (address => mapping (address => uint256)) _allowance;

  // 主数据结构存储表
  using LockDB for LockDB.Table;
  LockDB.Table LockDBTable;

  using PosDB for PosDB.Table;
  PosDB.Table PosDBTable;

  using PosoutDB for PosoutDB.Table;
  PosoutDB.Table PosOutDBTable;

  //公管钱包合约地址
  address PWWAddress;

  constructor(
      address       TokenOrePool,
      uint8         TokenDecimals,
      string memory TokenName,
      string memory TokenSymbol,
      uint256       TokenTotalSupply,
      uint16        MaxRemeberPosRecord,
      uint256       JoinPosMinAmountLimit,
      uint256       PosOutWriterReward,
      uint256       StartUnlockDataTime,
      uint256       PosMaxPorfitByThousandths,
      bool          EnableWithDrawPosProfit
      )
      public
  {
    PWWAddress = TokenOrePool;
    _balanceMap[TokenOrePool] = TokenTotalSupply;
    totalSupply = TokenTotalSupply;
    decimals = TokenDecimals;
    name = TokenName;
    symbol = TokenSymbol;
    maxRemeberPosRecord = MaxRemeberPosRecord;
    PosOutDBTable.RecordMaxSize = MaxRemeberPosRecord;
    joinPosMinAmount = JoinPosMinAmountLimit;
    posoutWriterReward = PosOutWriterReward;
    startUnlockDataTime = StartUnlockDataTime;
    enableWithDrawPosProfit = EnableWithDrawPosProfit;
    posMaxPorfitByThousandths = PosMaxPorfitByThousandths;
  }

  function balanceOf(address _owner) public view returns (uint256 balance)
  {
    return _balanceMap[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool success)
  {
    require( _balanceMap[msg.sender] >= _value && _value > 0 );

    _balanceMap[msg.sender] -= _value;
    _balanceMap[_to] += _value;
    emit Transfer(msg.sender, _to, _value);

    if ( TryCreatePosOutRecord() && _balanceMap[address(this)] >= posoutWriterReward )
    {
        _balanceMap[msg.sender] += posoutWriterReward;
        _balanceMap[address(this)] -= posoutWriterReward;

        emit Transfer(address(this), msg.sender, posoutWriterReward);
    }

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
  {
    if (_balanceMap[_from] >= _value && _allowance[_from][msg.sender] >= _value && _value > 0)
    {
      _balanceMap[_from] -= _value;
      _balanceMap[_to] += _value;
      _allowance[_from][msg.sender] -= _value;
      emit Transfer(_from, _to, _value);
      return true;
    }
    else
    {
      return false;
    }
  }

  function approve(address _spender, uint256 _value) public returns (bool success)
  {
    _allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining)
  {
    return _allowance[_owner][_spender];
  }

  // 将可用余额参与POS
  function DespoitToPos(uint256 amount) public returns (bool success)
  {
    require( _balanceMap[msg.sender] >= amount && amount >= joinPosMinAmount );

    _balanceMap[msg.sender] -= amount;

    PosDB.Record memory newRecord = PosDB.Record(amount, now, 0);

    success = PosDBTable.AddRecord(msg.sender, newRecord);

    emit Events.OnCreatePosRecord(amount);
  }

  // 获取记录中的Pos收益
  function getPosRecordProfit(address _owner, uint recordId)
  internal
  view
  returns (uint256 profit, uint256 amount, uint256 lastPosoutTime)
  {
    PosDB.Record memory posRecord = PosDBTable.recordMapping[_owner][recordId];
    PosoutDB.Record[] memory posoutRecords = PosOutDBTable.Records;

    amount = posRecord.amount;

    for ( uint ri = posoutRecords.length; ri > 0; ri-- )
    {
      uint i = ri - 1;

      PosoutDB.Record memory subrecord = posoutRecords[i];

      // 首次可以提取的时间，为投入时间 + 1 日即 24小时后的当天可以计算收益
      uint256 fristWithdrawTime = posRecord.depositTime + 1 days;

      if ( ( posRecord.lastWithDrawTime > fristWithdrawTime ? posRecord.lastWithDrawTime : fristWithdrawTime  )  < subrecord.posoutTime )
      {
        // 未领取，增加收益
        uint256 subProfit = posRecord.amount * subrecord.thousandthRatio / 1000;

        if ( subrecord.posoutTime > lastPosoutTime )
        {
            lastPosoutTime = subrecord.posoutTime;
        }

        profit += subProfit;
      }
    }
  }

  function GetPosRecords()
  public
  view
  returns ( uint len, uint256[] memory amount, uint256[] memory depositTime, uint256[] memory lastWithDrawTime, uint256[] memory prefix )
  {
    len = PosDBTable.recordMapping[msg.sender].length;

    amount = new uint256[](len);
    depositTime = new uint256[](len);
    lastWithDrawTime = new uint256[](len);
    prefix = new uint256[](len);

    for ( uint i = 0; i < len; i++ )
    {
        PosDB.Record memory record = PosDBTable.GetRecord(msg.sender, i);

        (prefix[i], amount[i], ) = getPosRecordProfit(msg.sender, i);

        depositTime[i] = record.depositTime;
        lastWithDrawTime[i] = record.lastWithDrawTime;
    }
  }

  // 提取参与Pos的余额与收益，解除合约
  function RescissionPosAt(uint posRecordIndex)
  public
  returns (uint256 posProfit, uint256 amount, uint256 distantPosoutTime)
  {
    (posProfit, amount, distantPosoutTime) = getPosRecordProfit(msg.sender, posRecordIndex);

    // 拷贝一个内存实例，因为删除源数据
    PosDB.Record memory indexRecord = PosDBTable.recordMapping[msg.sender][posRecordIndex];

    if ( PosDBTable.RemoveRecord(msg.sender, posRecordIndex) )
    {
      _balanceMap[msg.sender] += amount;

      if (enableWithDrawPosProfit)
      {
        _balanceMap[msg.sender] += posProfit;
        _balanceMap[address(this)] -= posProfit;
      }
    }

    emit Events.OnRescissionPosRecord(
        amount,
        indexRecord.depositTime,
        indexRecord.lastWithDrawTime,
        posProfit,
        enableWithDrawPosProfit);
  }

  // 一次性提取所有Pos参与记录的本金和收益
  function RescissionPosAll()
  public
  returns (uint256 amountTotalSum, uint256 profitTotalSum)
  {
    uint recordCount = PosDBTable.recordMapping[msg.sender].length;

    for (uint i = 0; i < recordCount; i++)
    {
        (uint256 posProfit, uint256 amount, ) = getPosRecordProfit( msg.sender, 0 );

        if ( PosDBTable.RemoveRecord(msg.sender, 0) )
        {
            amountTotalSum += amount;
            profitTotalSum += posProfit;

            _balanceMap[msg.sender] += amount;

            if ( enableWithDrawPosProfit )
            {
                _balanceMap[address(this)] -= posProfit;
                _balanceMap[msg.sender] += posProfit;
            }
        }
    }

    emit Events.OnRescissionPosRecordAll(amountTotalSum, profitTotalSum, enableWithDrawPosProfit);
  }

  // 获取当前参与Pos的数额总量
  function GetCurrentPosSum()
  public
  view
  returns (uint256 sum)
  {
    return PosDBTable.posAmountTotalSum;
  }

  // 获取当前所有Posout记录
  function GetPosoutLists()
  public
  view
  returns (
    uint len,
    uint256[] memory posouttotal,
    uint256[] memory posoutTime,
    uint256[] memory thousandthRatio
    )
  {
    len = PosOutDBTable.Records.length;

    posouttotal = new uint256[](len);
    posoutTime = new uint256[](len);
    thousandthRatio = new uint256[](len);

    for (uint i = 0; i < len; i++)
    {
      posouttotal[i] = PosOutDBTable.Records[i].posTotal;
      posoutTime[i] = PosOutDBTable.Records[i].posoutTime;
      thousandthRatio[i] = PosOutDBTable.Records[i].thousandthRatio;
    }
  }

  // 提取指定Pos记录的收益
  function WithDrawPosProfit(uint posRecordIndex)
  public
  returns (uint256 profit, uint256 posAmount)
  {
    uint256 distantPosoutTime;

    (profit, posAmount, distantPosoutTime) = getPosRecordProfit(msg.sender, posRecordIndex);

    PosDBTable.recordMapping[msg.sender][posRecordIndex].lastWithDrawTime = distantPosoutTime;

    if (enableWithDrawPosProfit)
    {
      _balanceMap[address(this)] -= profit;
      _balanceMap[msg.sender] += profit;
    }

    emit Events.OnWithdrawPosRecordPofit(
        posAmount,
        PosDBTable.recordMapping[msg.sender][posRecordIndex].depositTime,
        distantPosoutTime,
        profit,
        enableWithDrawPosProfit
        );
  }

  // 提取所有Pos记录产生的收益
  function WithDrawPosAllProfit()
  public
  returns (uint256 profitSum, uint256 posAmountSum)
  {
    for (uint ri = 0; ri < PosDBTable.recordMapping[msg.sender].length; ri++)
    {
      (uint256 posProfit, uint256 amount, uint256 distantPosoutTime) = getPosRecordProfit(msg.sender, ri);

      PosDBTable.recordMapping[msg.sender][ri].lastWithDrawTime = distantPosoutTime;

      if (enableWithDrawPosProfit)
      {
        _balanceMap[address(this)] -= posProfit;
        _balanceMap[msg.sender] += posProfit;
      }

      profitSum += posProfit;
      posAmountSum += amount;

      emit Events.OnWithdrawPosRecordPofitAll(
          posAmountSum,
          profitSum,
          enableWithDrawPosProfit
          );
    }
  }

  // 获取用户对应记录当前可以提取的收益数量
  function getLockRecordProfit(address _owner, uint rid)
  internal
  view
  returns (uint256 profit)
  {
      LockDB.Record memory record = LockDBTable.GetRecord(_owner, rid);

      // 未开始释放，无任何收益，或有需要已经被暂停
      if ( startUnlockDataTime == 0 )
      {
        return 0;
      }
      else
      {
        // 自释放日起，到当前时间，总共释放经过的时间戳
        uint256 unlockTimes;

        if ( record.createTime > startUnlockDataTime )
        {
          //记录增加时间在释放开始时间之后，说明记录为ICO轮锁仓
          unlockTimes = now - record.createTime;
        }
        else
        {
          //记录创建时间位于释放时间开始之前，说明该记录为天使轮锁仓
          unlockTimes = now - startUnlockDataTime;
        }

        // 总共释放了多少天
        uint256 unlcokTotalDays = unlockTimes / 1 days;

        // 当前应该获得到总释放量
        uint256 unlockTotalAmount;

        if ( unlcokTotalDays >= record.lockDays )
        {
          // 不能直接使用 ”unlockTotalAmount = record.totalAmount“，某些数值会存在余数。
          unlockTotalAmount = record.lockDays * (record.totalAmount / record.lockDays);
        }
        else
        {
          unlockTotalAmount = unlcokTotalDays * (record.totalAmount / record.lockDays);
        }

        // 减去已经提取到量等于本次可以提取到量
        uint256 profitRet = unlockTotalAmount - record.withdrawAmount;

        // 如果已经是超过最大释放天数，并且锁定量和释放量中有部分余数，则在锁仓天数+1时，提取
        if ( unlcokTotalDays >= record.lockDays && record.totalAmount - (profitRet + record.withdrawAmount) > 0 )
        {
            return profitRet + (record.totalAmount - (profitRet + record.withdrawAmount));
        }

        return profitRet;
      }
  }

  // 获取单个数量的锁仓详情
  function GetLockRecords()
  public
  view
  returns (
    uint len,
    uint256[] memory totalAmount,
    uint256[] memory withdrawAmount,
    uint256[] memory lastWithdrawTime,
    uint16[] memory lockDays,
    uint256[] memory profit
    )
  {
    len = LockDBTable.recordMapping[msg.sender].length;

    totalAmount = new uint256[](len);
    withdrawAmount = new uint256[](len);
    lastWithdrawTime = new uint256[](len);
    lockDays = new uint16[](len);
    profit = new uint256[](len);

    for ( uint i = 0; i < len; i++ )
    {
        LockDB.Record memory record = LockDBTable.GetRecord(msg.sender, i);

        totalAmount[i] = record.totalAmount;
        withdrawAmount[i] = record.withdrawAmount;
        lastWithdrawTime[i] = record.lastWithdrawTime;
        lockDays[i] = record.lockDays;
        profit[i] = getLockRecordProfit(msg.sender, i);
    }
  }

  // 提取锁仓记录的释放量
  function WithDrawLockRecordProFit(uint rid)
  public
  returns (uint256 profit)
  {
    profit = getLockRecordProfit(msg.sender, rid);

    LockDB.Record storage lockRecord = LockDBTable.recordMapping[msg.sender][rid];

    if ( profit > 0 )
    {
      lockRecord.withdrawAmount += profit;
      lockRecord.lastWithdrawTime = now;

      _balanceMap[msg.sender] += profit;

      emit Events.OnWithdrawLockRecord(
            profit,
            lockRecord.totalAmount,
            lockRecord.withdrawAmount,
            lockRecord.lastWithdrawTime,
            lockRecord.lockDays,
            lockRecord.createTime
        );
    }

  }

  // 提取所有锁仓记录的释放量
  function WithDrawLockRecordAllProfit()
  public
  returns (uint256 profitTotal)
  {
    LockDB.Record[] storage list = LockDBTable.recordMapping[msg.sender];

    uint lockAmountTotalSum = 0;

    for (uint i = 0; i < list.length; i++)
    {
      uint256 profitRet = getLockRecordProfit(msg.sender, i);

      lockAmountTotalSum += list[i].totalAmount;

      if ( profitRet > 0 )
      {
        list[i].withdrawAmount += profitRet;
        list[i].lastWithdrawTime = now;

        _balanceMap[msg.sender] += profitRet;

        profitTotal += profitRet;
      }
    }

    if (profitTotal > 0)
    {
        emit Events.OnWithdrawLockRecordAll(
            lockAmountTotalSum,
            profitTotal
            );
    }
  }

  // 设置开始解仓时间
  function API_SetUnlockAmountEnable(uint256 startTime)
  public
  NeedAdminPermission()
  {
    startUnlockDataTime = startTime;
  }

  // 发放锁仓余额
  function API_SendLockBalanceTo( address _to, uint256 lockAmountTotal, uint16 lockDays )
  public
  NeedAdminPermission()
  returns (bool success)
  {
    require( _balanceMap[address(this)] >= lockAmountTotal && lockAmountTotal > 0 );

    LockDB.Record memory newRecord = LockDB.Record( lockAmountTotal, 0, 0, lockDays, now );

    if ( LockDBTable.AddRecord(_to, newRecord) )
    {
      //锁定资产的发送应该从预挖地址中进行提取，即使合约的拥有者和合约的超级权限地址中支出
      _balanceMap[address(this)] -= lockAmountTotal;

      emit Events.OnSendLockAmount(
          _to,
          lockAmountTotal,
          lockDays
        );

      return true;
    }

    return false;
  }

  function createPosOutRecord(uint256 time)
  internal
  returns (bool success)
  {
      if ( PosDBTable.posAmountTotalSum <= 0)
      {
          return false;
      }

      // 转换时间到整点 UTC标准时间戳
      time = (time / 1 days) * 1 days;

      PosoutDB.Record memory newRecord = PosoutDB.Record(
        PosDBTable.posAmountTotalSum,
        time,
        posMaxPorfitByThousandths
        );

      return PosOutDBTable.PushRecord(newRecord);
  }

  // 增加一个Pos收益记录，理论上每日应该调用一次, time 为时间戳，而实际上是当前block的时间戳
  // 如果time设定为0，则回使用当前block的时间戳
  function TryCreatePosOutRecord()
  internal
  returns (bool success)
  {
      // 获取最后一条posout记录的时间，添加之前与当前时间比较，必须超过1 days，才允许添加
      uint256 lastRecordPosoutTimes = 0;

      if ( PosOutDBTable.Records.length != 0 )
      {
        // 有数据
        lastRecordPosoutTimes = PosOutDBTable.Records[PosOutDBTable.Records.length - 1].posoutTime;
      }

      if ( now - lastRecordPosoutTimes <= 1 days || PosDBTable.posAmountTotalSum <= 0)
      {
          return false;
      }

      return createPosOutRecord(now);
  }

  // Extern contract interface
  /* function API_ContractBalanceSendTo(address _to, uint256 _value)
  public
  NeedAdminPermission()
  {
    require( _balanceMap[this] >= _value && _value > 0);

    _balanceMap[this] -= _value;
    _balanceMap[_to] += _value;
  } */

  /// @notice 设置成功写入Pos产出记录的用户的奖励
  /// @param reward ： 数量（最大精度）
  /// @return success ： 操作结果
  function API_SetPosoutWriteReward(uint256 reward)
  public
  NeedAdminPermission()
  returns (bool success)
  {
      posoutWriterReward = reward;
      return true;
  }

  function API_SetEnableWithDrawPosProfit(bool state)
  public
  NeedAdminPermission()
  {
    enableWithDrawPosProfit = state;
  }

  function API_GetEnableWithDrawPosProfit()
  public
  view
  NeedAdminPermission()
  returns (bool state)
  {
    state = enableWithDrawPosProfit;
  }

  function API_SetJoinPosMinLimit(uint256 min)
  public
  NeedAdminPermission()
  {
      joinPosMinAmount = min;
  }
  //////////////////////////////////////////////////////////////
  /// ⚠️⚠️⚠️⚠️ 以下合约函数仅在测试时出现，上链时应当注释所有 ⚠️⚠️⚠️⚠️ ///
  /////////////////////////////////////////////////////////////
  /// 去除间隔时间检测规则直接写入一个Posout记录，
  function TestAPI_CreatePosoutRecordAtTime(uint256 time)
  public
  NeedAdminPermission()
  returns (bool success)
  {
      return createPosOutRecord(time);
  }

  /// 去除时间间隔检测直接写入一个Pos记录
  function TestAPI_DespoitToPosByTime( uint256 amount, uint256 time, address owner )
  public
  NeedAdminPermission()
  returns (bool success)
  {
      _balanceMap[owner] -= amount;

      PosDB.Record memory newRecord = PosDB.Record(amount, time, 0);

      success = PosDBTable.AddRecord(owner, newRecord);
  }

  // 去除时间间隔检测直接写入锁仓余额
  function TestAPI_SendLockBalanceByTime( address _to, uint256 lockAmountTotal, uint16 lockDays, uint256 time )
  public
  NeedAdminPermission()
  returns (bool success)
  {
    require( _balanceMap[address(this)] >= lockAmountTotal && lockAmountTotal > 0 );

    LockDB.Record memory newRecord = LockDB.Record( lockAmountTotal, 0, 0, lockDays, time );

    if ( LockDBTable.AddRecord(_to, newRecord) )
    {
      //锁定资产的发送应该从预挖地址中进行提取，即使合约的拥有者和合约的超级权限地址中支出
      _balanceMap[address(this)] -= lockAmountTotal;

      emit Events.OnSendLockAmount(
          _to,
          lockAmountTotal,
          lockDays
        );

      return true;
    }

    return false;
  }
}
