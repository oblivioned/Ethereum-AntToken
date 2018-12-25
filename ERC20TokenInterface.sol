  pragma solidity ^0.4.25;

contract ERC20TokenInterface
{
    uint256 public totalSupply;
    string  public name;     //名称，例如"My test token"
    uint8   public decimals;  //返回token使用的小数点后几位。比如如果设置为3，就是支持0.001表示.
    string  public symbol;   //token简称,like MTT

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
