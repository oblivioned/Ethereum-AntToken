pragma solidity >=0.5.0 <0.6.0;

library LockDB {

  // 锁仓记录
  struct Record
  {
    // 锁定的总量
    uint256 totalAmount;

    // 已经提取的总量
    uint256 withdrawAmount;

    // 上一次提取的时间
    uint256 lastWithdrawTime;

    // 锁定天数
    uint16 lockDays;

    // 记录创建时间
    uint256 createTime;
  }

  struct Table
  {
    mapping (address => LockDB.Record[]) recordMapping;
  }

  function AddRecord(LockDB.Table storage dbtable, address _owner, LockDB.Record memory record)
  internal
  returns (bool success)
  {
    if ( !(record.totalAmount > 0 && record.withdrawAmount == 0 && record.lockDays > 0 && record.createTime > 0 ) )
    {
      return false;
    }

    LockDB.Record[] storage list = dbtable.recordMapping[_owner];

    list.push(record);

    return true;
  }

  function GetRecordList(LockDB.Table storage dbtable, address _owner)
  internal
  view
  returns (LockDB.Record[] memory list)
  {
    return dbtable.recordMapping[_owner];
  }

  function GetRecord(LockDB.Table storage dbtable, address _owner, uint index)
  internal
  view
  returns (LockDB.Record memory record)
  {
    return dbtable.recordMapping[_owner][index];
  }

  function RemoveRecord(LockDB.Table storage dbtable, address _owner, uint index)
  internal
  returns (bool success)
  {
    LockDB.Record[] storage list = dbtable.recordMapping[_owner];

    require(index > 0 && index < list.length);

    for (uint i = index; i < list.length - 1; i++)
    {
      list[i] = list[i + 1];
    }

    delete list[list.length - 1];
    list.length --;

    return true;
  }

  function GetTotalAmount(LockDB.Table storage dbtable, address _owner)
  internal
  view
  returns (uint256 posTotal)
  {
    LockDB.Record[] storage list = dbtable.recordMapping[_owner];

    uint256 ret = 0;

    for (uint i = 0; i < list.length; i++)
    {
      LockDB.Record storage record = list[i];

      ret += record.totalAmount;
    }

    return ret;
  }
}
