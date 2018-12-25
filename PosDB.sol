pragma solidity ^0.4.24;

library PosDB {

  // Pos记录
  struct Record {
    uint256 amount;
    uint256 depositTime;
    uint256 lastWithDrawTime;
  }

  struct Table
  {
    mapping (address => PosDB.Record[]) recordMapping;

    // 参与Pos的总数量
    uint256 posAmountTotalSum;
  }

  function AddRecord(PosDB.Table storage dbtable, address _owner, PosDB.Record memory record)
  internal
  returns (bool success)
  {
    if ( record.amount <= 0 || record.lastWithDrawTime > 0 )
    {
      return false;
    }

    PosDB.Record[] storage list = dbtable.recordMapping[_owner];

    list.push(record);

    dbtable.posAmountTotalSum += record.amount;

    return true;
  }

  function GetRecordList(PosDB.Table storage dbtable, address _owner)
  internal
  constant
  returns (PosDB.Record[] list)
  {
    return dbtable.recordMapping[_owner];
  }

  function GetRecord(PosDB.Table storage dbtable, address _owner, uint index)
  internal
  constant
  returns (PosDB.Record record)
  {
    return dbtable.recordMapping[_owner][index];
  }

  function RemoveRecord(PosDB.Table storage dbtable, address _owner, uint index)
  internal
  returns (bool success)
  {
    PosDB.Record[] storage list = dbtable.recordMapping[_owner];

    require(index >= 0 && index < list.length, "posdb record index error.");

    PosDB.Record storage record = list[index];

    for (uint i = index; i < list.length - 1; i++)
    {
      list[i] = list[i + 1];
    }

    delete list[list.length - 1];
    list.length --;

    dbtable.posAmountTotalSum -= record.amount;

    return true;
  }

  function GetTotalAmount(PosDB.Table storage dbtable, address _owner)
  internal
  constant
  returns (uint256 posTotal)
  {
    PosDB.Record[] storage list = dbtable.recordMapping[_owner];

    uint256 ret = 0;

    for (uint i = 0; i < list.length; i++)
    {
      PosDB.Record storage record = list[i];

      ret += record.amount;
    }

    return ret;
  }
}
