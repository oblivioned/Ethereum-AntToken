pragma solidity >=0.4.0 <0.6.0;

import "remix_tests.sol"; // this import is automatically injected by Remix.

import "../ERC20TokenImpl.sol";

contract TestPos {

  ERC20TokenImpl instant;

  function beforeAll() public
  {
    instant = new ERC20TokenImpl();

    Assert.equal( instant.balanceOf(this), 1500000000 * 10 ** 8, "预挖数量有误" );
  }

  function TestWithdrawPosProfix_1() public
  {
    (uint256 amount, , , uint prefix) = instant.GetPosRecordInfo(0);

    // 提取单条记录的收益
    instant.WithDrawPosProfit(0);

    Assert.equal( instant.balanceOf(this), prefix, "提取Pos后余额数量不正确" );

    (,,,uint256 prefix2) = instant.GetPosRecordInfo(0);

    Assert.equal(prefix2, 0, "提取Pos收益后，记录的收益有误");

    // 尝试再次提取
    instant.WithDrawPosProfit(0);
    Assert.equal( instant.balanceOf(this), prefix, "第二次提取Pos后余额数量不正确" );

    // 提取本金

  }

  function TestDespoitToPos_0() public returns (bool pass)
  {
    // 记录测试前的余额
    uint256 originBalance = instant.balanceOf(this);

    // 1.将所有余额参与Pos
    instant.DespoitToPos(instant.balanceOf(this));

    // 2.参与以后剩余的余额应该为0
    Assert.equal( uint256(instant.balanceOf(this)), uint256(0), "参与Pos后，用户可用余额与参与Pos的数量不匹配");

    // 3.对应获得一条参与记录
    Assert.equal( instant.GetPosRecordCount(), uint256(1), "参与Pos后，记录未能生成" );

    // 4.创建一条Pos收益记录，在10天前
    instant.API_AddPosOutRecord(now - 10 days);

    // 5.检查Pos产出是否正常
    (uint256 amount, , , uint prefix) = instant.GetPosRecordInfo(0);
    Assert.equal( amount, originBalance, "记录的参与数量，与实际数量不符合。" );
    Assert.ok( prefix <= originBalance * 3 / 1000, "单日Pos收益计算错误。");

    // 9.增加额外的9次记录，凑齐3新增次pos收益记录
    instant.API_AddPosOutRecord(now - 9 days);
    instant.API_AddPosOutRecord(now - 8 days);

    // 检查Pos收益
    (amount,,,prefix) = instant.GetPosRecordInfo(0);
    Assert.ok( prefix <= (originBalance * 3 / 1000) * 3, "单日Pos收益计算错误。");

    return true;
  }
}
