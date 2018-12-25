pragma solidity ^0.4.24;

contract Events {

    /*********************************************/
    /************** Pos相关事件 *******************/
    /*********************************************/
    /* 当用户投入可用余额进入Pos池中 */
    event OnCreatePosRecord
    (
      address owner,
      uint256 posAmount
    );

    /* 提取Pos池中投入的记录，提取并且删除记录，返回本金时发起 */
    event OnRescissionPosRecord
    (
      address owner,
      // 记录对应的数额
      uint256 posAmount,
      // 记录创建的时间
      uint256 recordCreateTime,
      // 记录最后领取收益的时间
      uint256 lastWithDrawTime,
      // 提取时候残留一并读取的收益
      uint256 posProfit
    );

    /* 提取所有pos记录，提取并且删除记录，返回本金时发起 */
    event OnRescissionPosRecordAll
    (
      address owner,
      uint256 amountSum,
      uint256 profitSum
    );

    /* 当用户提取Pos记录带来当收益 */
    event OnWithdrawPosRecordPofit
    (
      address owner,
      // pos记录对应的数额
      uint256 amount,
      // pos记录对应的创建时间
      uint256 depositTime,
      // pos记录最后一次提取的时间
      uint256 lastWithDrawTime,
      // 提取的收益数
      uint256 profit
    );

    /* 一次提取所有pos记录的收益 */
    event OnWithdrawPosRecordPofitAll
    (
      address owner,
      uint256 amountSum,
      uint256 profitSum
    );
    /*********************************************/
    /************** Pos相关事件 *******************/
    /*********************************************/


    /*********************************************/
    /************** Lock 相关事件 *****************/
    /*********************************************/

    /* 锁定余额发送时，一般来说只有最高权限的用户可以调用 */
    event OnSendLockAmount(
      // 发送代币的管理员地址
      address sender,
      // 锁仓余额目标地址
      address to,
      // 数量
      uint256 amount,
      // 锁定天数
      uint256 lockDays
    );

    /* 用户领取锁仓记录 */
    event OnWithdrawLockRecord(
      address owner,
      // 当次领取的数值
      uint256 profit,
      // 记录中锁定的总量
      uint256 totalAmount,
      // 记录中已提取的总量
      uint256 withdrawAmount,
      // 记录中上一次提取的时间
      uint256 lastWithdrawTime,
      // 记录中锁定天数
      uint16 lockDays,
      // 记录创建时间
      uint256 createTime
    );

    /* 用户领取所有锁仓记录 */
    event OnWithdrawLockRecordAll(
      address owner,
      // 记录中锁定的总量
      uint256 totalAmountSum,
      // 当次领取的数值
      uint256 profitSum
    );
    /*********************************************/
    /************** Lock 相关事件 *****************/
    /*********************************************/


  }
