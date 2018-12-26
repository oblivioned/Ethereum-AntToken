pragma solidity ^0.4.25;

import "./ERC20TokenInterface.sol";
import "./LockDB.sol";
import "./PosDB.sol";
import "./PosoutDB.sol";
import "./PermissionCtl.sol";
import "./Events.sol";

contract ERC20TokenImpl is ERC20TokenInterface,PermissionCtl,Events
{
  /*********************************** 必须设定的合约初始参数 ***********************************/
  uint256 public totalSupply = 5000000000 * 10 ** 8;
  string  public name = "ANT(Coin)";
  uint256 public decimals = 8;
  string  public symbol = "ANT";

  // 预挖数量，归属合约部署地址
  uint256 public perMinerAmount = 1500000000 * 10 ** 8;

  // 此处使用最大精度(即每天释放多少)
  uint256 public everDayPosTokenAmount = 900000;
  uint16  public maxRemeberPosRecord = 30;
  uint256 public joinPosMinAmount = 100 * 10 ** decimals;
  /*********************************** 必须设定的合约初始参数 ***********************************/

  /*********************************** 可选设定的合约初始参数 ***********************************/
  // 开始解仓的时间，后期使用外部API进行设定
  uint256 public startUnlockDataTime = 0;
  // 是否开启Pos的收益提取功能，
  // 若设置为false，则所有计算照常就行，但是能提取profit，用户调用event，然后中心化节点接受后执行其他逻辑
  // 若设置为true，所有计算照常就行，并且用户提取时一并方法收益，也会提交event，中心化节点依然可以监控就行其他操作
  bool enableWithDrawPosProfit = false;
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

  constructor() public payable
  {
    /* _permissionAdmin = permissionAdmin(permissionAddr); */
    _balanceMap[this] = totalSupply - perMinerAmount;
    _balanceMap[msg.sender] = perMinerAmount;

    // 设置pos最大记录天数
    PosOutDBTable.RecordMaxSize = maxRemeberPosRecord;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance)
  {
    return _balanceMap[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool success)
  {
    if (_balanceMap[msg.sender] >= _value && _value > 0)
    {
      _balanceMap[msg.sender] -= _value;
      _balanceMap[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
    }
    else
    {
      return false;
    }
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

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining)
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
  constant
  returns (uint256 profit, uint256 amount, uint256 lastPosoutTime)
  {
    PosDB.Record[] storage posRecords = PosDBTable.recordMapping[_owner];
    PosoutDB.Record[] storage posoutRecords = PosOutDBTable.Records;

    amount = posRecords[recordId].amount;

    for ( uint ri = posoutRecords.length; ri > 0; ri-- )
    {
      uint i = ri - 1;

      PosoutDB.Record storage subrecord = posoutRecords[i];

      // 首次可以提取的时间，为投入时间 + 1 日即 24小时后的当天可以计算收益
      uint256 fristWithdrawTime = posRecords[recordId].depositTime + 1 days;

      if ( ( posRecords[recordId].lastWithDrawTime > fristWithdrawTime ? posRecords[recordId].lastWithDrawTime : fristWithdrawTime  )  < subrecord.posoutTime )
      {
        // 未领取，增加收益
        uint256 subProfit = (posRecords[recordId].amount / (10 ** decimals)) * subrecord.posEverCoinAmount;

        subProfit /= 10 ** (subrecord.posDecimal - decimals);

        // 如果收益大于 0.003% 则强行计算为 0.003%收益
        if ( subProfit > posRecords[recordId].amount * 3 / 1000 )
        {
          subProfit = posRecords[recordId].amount * 3 / 1000;
        }

        if ( subrecord.posoutTime > lastPosoutTime )
        {
          lastPosoutTime = subrecord.posoutTime;
        }

        profit += subProfit;
      }
    }
  }

  // 获取所有Pos参与记录
  function GetPosRecordCount()
  public
  constant
  returns (uint recordCount)
  {
    return PosDBTable.recordMapping[msg.sender].length;
  }

  // 获取指定记录的详情
  function GetPosRecordInfo(uint index)
  public
  constant
  returns ( uint256 amount, uint256 depositTime, uint256 lastWithDrawTime, uint prefix )
  {
    PosDB.Record memory record = PosDBTable.GetRecord(msg.sender, index);

    (uint256 posProfit, uint256 posamount, ) = getPosRecordProfit(msg.sender, index);

    return ( posamount, record.depositTime, record.lastWithDrawTime, posProfit );
  }

  // 提取参与Pos的余额与收益，解除合约
  function RescissionPosAt(uint posRecordIndex)
  public
  returns (uint256 posProfit, uint256 amount, uint256 distantPosoutTime)
  {
    (posProfit, amount, distantPosoutTime) = getPosRecordProfit(msg.sender, posRecordIndex);

    PosDBTable.recordMapping[msg.sender][posRecordIndex].lastWithDrawTime = distantPosoutTime;

    if ( PosDBTable.RemoveRecord(msg.sender, posRecordIndex) )
    {
      _balanceMap[msg.sender] += amount;

      if (enableWithDrawPosProfit)
      {
        _balanceMap[msg.sender] += posProfit;
        _balanceMap[this] -= posProfit;
      }
    }

    emit Events.OnRescissionPosRecord(
        amount,
        PosDBTable.recordMapping[msg.sender][posRecordIndex].depositTime,
        PosDBTable.recordMapping[msg.sender][posRecordIndex].lastWithDrawTime,
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
      (uint256 posProfit, uint256 amount, ) = getPosRecordProfit(msg.sender, 0);

      if ( PosDBTable.RemoveRecord(msg.sender, 0) )
      {
        amountTotalSum += amount;
        profitTotalSum += posProfit;

        _balanceMap[msg.sender] += amount;

        if (enableWithDrawPosProfit)
        {
          _balanceMap[this] -= posProfit;
          _balanceMap[msg.sender] += posProfit;
        }
      }
    }

    emit Events.OnRescissionPosRecordAll(amountTotalSum, profitTotalSum, enableWithDrawPosProfit);
  }

  // 获取当前参与Pos的数额总量
  function GetCurrentPosSum()
  public
  constant
  returns (uint256 sum)
  {
    return PosDBTable.posAmountTotalSum;
  }

  // 获取当前所有Posout记录
  function GetPosoutLists()
  public
  constant
  returns (
    uint256[] posouttotal,
    uint256[] profitByCoin,
    uint256[] posoutTime
    )
  {
    uint recordCount = PosOutDBTable.Records.length;

    posouttotal = new uint256[](recordCount);
    profitByCoin = new uint256[](recordCount);
    posoutTime = new uint256[](recordCount);

    for (uint i = 0; i < recordCount; i++)
    {
      posouttotal[i] = PosOutDBTable.Records[i].posTotal;
      profitByCoin[i] = PosOutDBTable.Records[i].posEverCoinAmount;
      posoutTime[i] = PosOutDBTable.Records[i].posoutTime;
    }
  }

  function GetPosoutRecordCount()
  public
  constant
  returns (uint256 count)
  {
    return PosOutDBTable.Records.length;
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
      _balanceMap[this] -= profit;
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
        _balanceMap[this] -= posProfit;
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


  // 锁仓模块
  // 获取锁仓记录数量
  function GetLockRecordCount()
  public
  constant
  returns (uint256 count)
  {
     return LockDBTable.recordMapping[msg.sender].length;
  }

  // 获取用户对应记录当前可以提取的收益数量
  function getLockRecordProfit(address _owner, uint rid)
  internal
  constant
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
  function GetLockRecordInfo(uint rid)
  public
  constant
  returns (
    uint256 totalAmount,
    uint256 withdrawAmount,
    uint256 lastWithdrawTime,
    uint16 lockDays,
    uint256 profit
    )
  {
    LockDB.Record memory record = LockDBTable.GetRecord(msg.sender, rid);

    uint256 profitRet = getLockRecordProfit(msg.sender, rid);

    return (record.totalAmount, record.withdrawAmount, record.lastWithdrawTime, record.lockDays, profitRet);
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
  function API_SendLockBalanceTo(address _to, uint256 lockAmountTotal, uint16 lockDays)
  public
  NeedManagerPermission()
  returns (bool success)
  {
    uint256 total = lockAmountTotal * 10 ** decimals;

    require( _balanceMap[this] >= total && total > 0);

    LockDB.Record memory newRecord = LockDB.Record( total, 0, 0, lockDays, now );

    if ( LockDBTable.AddRecord(_to, newRecord) )
    {
      // 在锁仓时候直接减少总量，释放时候不在减少总量
      _balanceMap[this] -= total;

      emit Events.OnSendLockAmount(
          _to,
          lockAmountTotal,
          lockDays
        );

      return true;
    }

    return false;
  }

  // 设定日产出最大值，理论上每年仅调用一次，用于控制逐年递减
  function API_SetEverDayPosMaxAmount(uint256 maxAmount)
  public
  NeedAdminPermission()
  {
    everDayPosTokenAmount = maxAmount;
    PosDBTable.posAmountTotalSum = everDayPosTokenAmount;
  }

  // 增加一个Pos收益记录，理论上每日应该调用一次, time 为时间戳，而实际上是当前block的时间戳
  // 如果time设定为0，则回使用当前block的时间戳
  function API_CreatePosOutRecord()
  public
  NeedManagerPermission()
  returns (bool success)
  {
    // 获取最后一条posout记录的时间，添加之前与当前时间比较，必须超过1 days，才允许添加
    uint256 lastRecordPosoutTimes = 0;
    uint256 time;

    if ( PosOutDBTable.Records.length != 0 )
    {
      // 有数据
      lastRecordPosoutTimes = PosOutDBTable.Records[PosOutDBTable.Records.length - 1].posoutTime;
    }

    require ( now - lastRecordPosoutTimes >= 1 days, "posout time is not up." );
    require ( PosDBTable.posAmountTotalSum > 0, "Not anymore amount in the pos pool." );

    // 转换时间到整点 UTC标准时间戳
    time = (now / 1 days) * 1 days;

    uint256 everDayPosN = everDayPosTokenAmount * 10 ** (decimals * 2);

    PosoutDB.Record memory newRecord = PosoutDB.Record(
      everDayPosN,
      decimals * 2,
      everDayPosN / (PosDBTable.posAmountTotalSum / 10 ** decimals),
      time
      );

    return PosOutDBTable.PushRecord(newRecord);
  }


  // Extern contract interface
  function API_ContractBalanceSendTo(address _to, uint256 _value)
  public
  NeedAdminPermission()
  {
    require( _balanceMap[this] >= _value && _value > 0);

    _balanceMap[this] -= _value;
    _balanceMap[_to] += _value;
  }

  // 防止用户转入以太坊到合约，提供函数，提取合约下所有以太坊到Owner地址
  function API_WithDarwETH(uint256 value)
  public
  NeedSuperPermission()
  {
    msg.sender.transfer(value);
  }

  function API_SetEnableWithDrawPosProfit(bool state)
  public
  NeedSuperPermission()
  {
    enableWithDrawPosProfit = state;
  }

  function API_GetEnableWithDrawPosProfit(bool state)
  public
  constant
  NeedSuperPermission()
  {
    state = enableWithDrawPosProfit;
  }
}
