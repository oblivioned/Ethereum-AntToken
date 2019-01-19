pragma solidity >=0.5.0 <0.6.0;

library PosoutDB {

    // Pos结果
    struct Record {

      // 当次POS产出最大数量
      uint256 posTotal;

      // 数值精度
      uint256 posDecimal;

      // 每个Token获得对应的收益
      uint256 posEverCoinAmount;

      // 产出时间
      uint256  posoutTime;

    }

    struct Table
    {
      PosoutDB.Record[] Records;

      // 记录最大值
      uint16 RecordMaxSize;
    }

    function GetRecordMaxSize(PosoutDB.Table storage dbtable)
    internal
    view
    returns (uint16 size)
    {
      return dbtable.RecordMaxSize;
    }

    function PushRecord(PosoutDB.Table storage dbtable, PosoutDB.Record memory record)
    internal
    returns (bool success)
    {
      if ( dbtable.Records.length >= dbtable.RecordMaxSize )
      {
        for (uint i = 0; i < dbtable.Records.length - 1; i++)
        {
          dbtable.Records[i] = dbtable.Records[i + 1];
        }

        delete dbtable.Records[dbtable.Records.length - 1];
        dbtable.Records.length --;
      }

      dbtable.Records.push(record);

      return true;
    }
}
