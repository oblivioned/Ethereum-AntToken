pragma solidity >=0.5.0 <0.6.0;

contract PermissionCtl {

  address owner;
  address[] admins;

  function GetAdminList()
  public
  constant
  NeedAdminPermission
  returns ( address[] addresses )
  {
    return admins;
  }

  constructor() public
  {
    owner = msg.sender;
  }

  modifier NeedAdminPermission()
  {
    if (msg.sender == owner)
    {
      _;
      return;
    }

    bool exist = false;

    for (uint i = 0; i < admins.length; i++ )
    {
      if (admins[i] == msg.sender)
      {
        exist = true;
        break;
      }
    }

    require(exist);
    _;
  }

  modifier NeedSuperPermission()
  {
    require( msg.sender == owner );
    _;
  }

  function AddAdmin(address admin)
  public
  NeedSuperPermission
  returns (bool success)
  {
    for (uint i = 0; i < admins.length; i++ )
    {
      if (admins[i] == admin)
      {
        return false;
      }
    }

    admins.push(admin);
  }

  function RemoveAdmin(address admin)
  public
  NeedSuperPermission
  returns (bool success)
  {
    for (uint i = 0; i < admins.length; i++ )
    {
      if (admins[i] == admin)
      {
        for (uint j = i; j < admins.length - 1; j++)
        {
          admins[j] = admins[j + 1];
        }

        delete admins[admins.length - 1];
        admins.length --;

        return true;
      }
    }

    return false;
  }
}
