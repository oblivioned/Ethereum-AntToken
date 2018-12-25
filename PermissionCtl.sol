pragma solidity ^0.4.25;

contract PermissionCtl {

  struct Table
  {
    address superOwner;
    address[] admins;
    address[] managers;
  }

  Table DBTable;

  function GetAllPermissionAddress()
  public
  constant
  NeedAdminPermission
  returns (address superAdmin, address[] admins, address[] managers)
  {
    return (DBTable.superOwner, DBTable.admins, DBTable.managers);
  }

  constructor() public
  {
    DBTable.superOwner = msg.sender;
    DBTable.admins.push(msg.sender);
    DBTable.managers.push(msg.sender);
  }

  modifier NeedSuperPermission()
  {
    require(msg.sender == DBTable.superOwner);
    _;
    return;
  }

  modifier NeedAdminPermission()
  {
    if (msg.sender == DBTable.superOwner)
    {
      _;
      return;
    }

    bool exist = false;

    for (uint i = 0; i < DBTable.admins.length; i++ )
    {
      if (DBTable.admins[i] == msg.sender)
      {
        exist = true;
        break;
      }
    }

    require(exist);
    _;
    return;
  }

  modifier NeedManagerPermission()
  {
    if (msg.sender == DBTable.superOwner)
    {
      _;
      return;
    }

    bool exist = false;

    for (uint i = 0; i < DBTable.managers.length; i++ )
    {
      if (DBTable.managers[i] == msg.sender)
      {
        exist = true;

        break;
      }
    }

    // 如果存在管理员地址，则直接通过验证，否则继续查找是否属于更高权限的账号
    if (exist)
    {
      _;
      return;
    }

    for (uint j = 0; j < DBTable.admins.length; j++ )
    {
      if (DBTable.admins[j] == msg.sender)
      {
        exist = true;
        break;
      }
    }

    require(exist);
    _;
    return;
  }

  function GetSuperOwner()
  public
  constant
  returns (address superOwnerAddress)
  {
    return DBTable.superOwner;
  }

  function AddManager(address manager)
  public
  NeedSuperPermission
  returns (bool success)
  {
    for (uint i = 0; i < DBTable.managers.length; i++ )
    {
      if (DBTable.managers[i] == manager)
      {
        return false;
      }
    }

    DBTable.managers.push(manager);
  }

  function AddAdmin(address admin)
  public
  NeedSuperPermission
  returns (bool success)
  {
    for (uint i = 0; i < DBTable.admins.length; i++ )
    {
      if (DBTable.admins[i] == admin)
      {
        return false;
      }
    }

    DBTable.admins.push(admin);
  }

  function RemoveManager(address manager)
  public
  NeedSuperPermission
  returns (bool success)
  {
    for (uint i = 0; i < DBTable.managers.length; i++ )
    {
      if (DBTable.managers[i] == manager)
      {
        for (uint j = i; j < DBTable.managers.length - 1; j++)
        {
          DBTable.managers[j] = DBTable.managers[j + 1];
        }

        delete DBTable.managers[DBTable.managers.length - 1];
        DBTable.managers.length --;

        return true;
      }
    }

    return false;
  }

  function RemoveAdmin(address admin)
  public
  NeedSuperPermission
  returns (bool success)
  {
    for (uint i = 0; i < DBTable.admins.length; i++ )
    {
      if (DBTable.admins[i] == admin)
      {
        for (uint j = i; j < DBTable.admins.length - 1; j++)
        {
          DBTable.admins[j] = DBTable.admins[j + 1];
        }

        delete DBTable.admins[DBTable.admins.length - 1];
        DBTable.admins.length --;

        return true;
      }
    }

    return false;
  }
}
