pragma solidity >=0.5.0 <0.6.0;

import "../PermissionCtl.sol";

interface ERC20TransferInterface {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

library VoterTransferLibrary
{
    enum QueueType
    {
        WaitingReviewQueue,
        PassedQueue,
        RejectQueue,
        WaitingExecQueue
    }
    
    struct Request
    {
        // 提币发起人
        address     proposal;
        // 发起时间
        uint256     createTime;
        // 发送的目标地址
        address     targetAddress;
        // 发送的数量
        uint256     amount;
        // 备注信息
        string      desc;
        // 本提案的Hash值
        bytes32     hashCode;
        // 同意的地址
        address[]   passedAddresses;
        // 拒绝的地址
        address[]   rejectAddresses;
        // 投票结果时间
        uint256     votedRequestTime;
        // 执行时间
        uint256     execTime;
    }

    struct StoragePool
    {
        // 等待投票，暂未通过的变更申请
        Request[] waitingRequests;
        // 已经通过的申请
        Request[] passRequests;
        // 被驳回的申请
        Request[] rejectRequests;
        // 已经执行的投票
        Request[] execRequests;
        // 所有具有投票权的用户地址
        address[] voterAddresses;
        // 总共发起了投票的次数，用于控制Hash值
        uint160   voteTotalCount;
    }

    function GetVoteCaseList( StoragePool storage _self, QueueType _qtype ) 
    internal 
    view
    returns (Request[] memory list) {
        
        if (_qtype == QueueType.WaitingReviewQueue)
        {
            return _self.waitingRequests;
        }
        else if (_qtype == QueueType.PassedQueue)
        {
            return _self.passRequests;
        }
        else if (_qtype == QueueType.RejectQueue)
        {
            return _self.rejectRequests;
        }
        else if (_qtype == QueueType.WaitingExecQueue)
        {
            return _self.execRequests;
        }
        
        require(false, "not found vote queue by key");
    }

    function AddVoter( StoragePool storage _self, address newVoter ) internal returns (bool success) {

        for ( uint i = 0; i < _self.voterAddresses.length; i++ )
        {
            if (_self.voterAddresses[i] == newVoter )
            {
                return false;
            }
        }

        _self.voterAddresses.push(newVoter);
    }
    
    function RemoveVoter( StoragePool storage _self, address newVoter ) internal returns (bool success){
        
        for ( uint i = 0; i < _self.voterAddresses.length; i++ )
        {
            if (_self.voterAddresses[i] == newVoter )
            {
                for (uint di = 0; di < _self.voterAddresses.length - 1; di ++)
                {
                    _self.voterAddresses[i] = _self.voterAddresses[i + 1];
                }
                
                delete _self.voterAddresses[ _self.voterAddresses.length - 1 ];
                _self.voterAddresses.length--;
                return true;
            }
        }
        
        return false;
    }

    function AddressIsIn( address addr, address[] memory array ) internal pure returns (bool exist) {

        for (uint i = 0; i < array.length; i++)
        {
            if (array[i] == addr)
            {
                return true;
            }
        }

        return false;
    }
    
    function AfterExecVoteCase( StoragePool storage _self, bytes32 _voteHash ) internal returns (bool success)
    {
        for (uint i = 0; i < _self.passRequests.length; i++ )
        {
            if ( _self.passRequests[i].hashCode == _voteHash )
            {
                //添加到成功的投票列表
                _self.passRequests[i].execTime = now;
                
                _self.execRequests.push( _self.passRequests[i] );

                //删除源
                for (uint di = i; di < _self.passRequests.length - 1; di++)
                {
                    _self.passRequests[di] = _self.passRequests[di + 1];
                }

                delete _self.passRequests[_self.passRequests.length - 1];
                _self.passRequests.length --;
                return true;
            }
        }
        
        return false;
    }

    /// @notice 投票已经足够构成通过的结果，将投票移入已经通过的列表等待执行
    function PassVoteCase( StoragePool storage _self, bytes32 _voteHash ) private returns (bool succses)
    {
        for (uint i = 0; i < _self.waitingRequests.length; i++ )
        {
            if ( _self.waitingRequests[i].hashCode == _voteHash )
            {
                //添加到成功的投票列表
                _self.waitingRequests[i].votedRequestTime = now;
                _self.rejectRequests.push( _self.waitingRequests[i] );

                //删除源
                for (uint di = i; di < _self.waitingRequests.length - 1; di++)
                {
                    _self.waitingRequests[di] = _self.waitingRequests[di + 1];
                }

                delete _self.waitingRequests[_self.waitingRequests.length - 1];
                _self.waitingRequests.length --;
                return true;
            }
        }

        return false;
    }

    function RejectVoteCase( StoragePool storage _self, bytes32 _voteHash ) private returns (bool succses)
    {
        for (uint i = 0; i < _self.waitingRequests.length; i++ )
        {
            if ( _self.waitingRequests[i].hashCode == _voteHash )
            {
                //添加到成功的驳回的列表
                _self.waitingRequests[i].votedRequestTime = now;
                _self.passRequests.push( _self.waitingRequests[i] );

                //删除源
                for (uint di = i; di < _self.waitingRequests.length - 1; di++)
                {
                    _self.waitingRequests[di] = _self.waitingRequests[di + 1];
                }

                delete _self.waitingRequests[_self.waitingRequests.length - 1];
                _self.waitingRequests.length --;
                return true;
            }
        }
    }

    /// @notice 为指定的申请就行投票
    function VoteingRequest( StoragePool storage _self, bytes32 _voteHash, string memory _msg ) internal returns (bool success, bool isPass, bool isReject)
    {
        for (uint i = 0; i < _self.waitingRequests.length; i++ )
        {
            if ( _self.waitingRequests[i].hashCode == _voteHash )
            {
                //不能重复投票
                require( !AddressIsIn(msg.sender, _self.waitingRequests[i].passedAddresses) && !AddressIsIn(msg.sender, _self.waitingRequests[i].rejectAddresses) );

                if ( keccak256(bytes(_msg)) == keccak256("Pass") )
                {
                    _self.waitingRequests[i].passedAddresses.push(msg.sender);

                    if ( _self.waitingRequests[i].passedAddresses.length > _self.voterAddresses.length / 2 )
                    {
                        require( PassVoteCase(_self, _voteHash) );
                        return (true, true, false);
                    }
                    else
                    {
                        return (true, false, false);
                    }
                }
                else if ( keccak256(bytes(_msg)) == keccak256("Reject") )
                {
                    _self.waitingRequests[i].rejectAddresses.push(msg.sender);

                    if ( _self.waitingRequests[i].rejectAddresses.length > _self.voterAddresses.length / 2 )
                    {
                        require( RejectVoteCase(_self, _voteHash) );
                        return (true, false, true);
                    }
                    else
                    {
                        return (true, false, true);
                    }
                }
            }
        }

        require(false, "cant't found vote request.");
    }

    function CreateTransferVoteCase( StoragePool storage _self, address _to, uint256 _amount, string memory _desc ) internal returns (bool success){

        //计算投票的Hash值
        uint160 fromAddress = uint160(msg.sender);
        uint160 toAddresss = uint160(_to);
        uint160 hashBaseData = fromAddress + toAddresss + _self.voteTotalCount + 1;
        bytes32 voteHash = keccak256( new bytes(hashBaseData) );

        Request memory newVoteRequest = Request( msg.sender, now, _to, _amount, _desc, voteHash, new address[](0), new address[](0), 0, 0 );
        _self.waitingRequests.push(newVoteRequest);
        _self.voteTotalCount ++;

        return true;
    }
}

contract PublicManagerWallet is PermissionCtl
{
    ERC20TransferInterface  tokenInstanceAddress;

    using VoterTransferLibrary for VoterTransferLibrary.StoragePool;
    VoterTransferLibrary.StoragePool Voters;

    function SetTokenInstanceAddress( address instance ) 
    public
    NeedSuperPermission
    {
        tokenInstanceAddress = ERC20TransferInterface(instance);
    }

    constructor() public
    {

    }

    function ApplyTransafer( address _to, uint256 _amount, string memory _desc ) 
    public 
    NeedAdminPermission()
    returns (bool success)
    {
        return Voters.CreateTransferVoteCase( _to, _amount, _desc );
    }

    function PassVoteCase( bytes32 _caseHash ) 
    public 
    NeedAdminPermission()
    returns ( bool success )
    {
        (success,,) = Voters.VoteingRequest( _caseHash, "Pass" );
    }

    function RejectVoteCase( bytes32 _caseHash ) 
    public 
    NeedAdminPermission()
    returns ( bool success )
    {
        (success,,) = Voters.VoteingRequest( _caseHash, "Reject" );
    }

    function ExecPassVoteCase( bytes32 _caseHash ) 
    public 
    NeedAdminPermission()
    returns ( bool success )
    {
        for ( uint i = 0; i < Voters.passRequests.length; i++ )
        {
            VoterTransferLibrary.Request memory passVoteCase = Voters.passRequests[i];
            
            require( tokenInstanceAddress.transfer( passVoteCase.targetAddress, passVoteCase.amount ) );
        }
        
        return Voters.AfterExecVoteCase(_caseHash);
    }

    function AddAdmin(address admin)
    public
    NeedSuperPermission
    returns (bool success)
    {
        require( Voters.AddVoter(admin) );
        
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
        require( Voters.RemoveVoter(admin) );
        
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
    
    function GetVoteQueueCount( VoterTransferLibrary.QueueType _qtype ) 
    public 
    view
    NeedAdminPermission()
    returns( uint count )
    {
        VoterTransferLibrary.Request[] memory list = Voters.GetVoteCaseList(_qtype);
        
        return list.length;
    }
    
    function GetVoteRequestDetail( VoterTransferLibrary.QueueType _qtype, uint256 index )
    public
    view
    NeedAdminPermission()
    returns(
        address         proposal,
        uint256         createTime,
        address         targetAddress,
        uint256         amount,
        string memory   desc,
        bytes32         hashCode,
        uint256         votedRequestTime,
        uint256         execTime
        )
    {
        VoterTransferLibrary.Request memory voteCase = Voters.GetVoteCaseList(_qtype)[index];
        
        return ( 
            voteCase.proposal,
            voteCase.createTime,
            voteCase.targetAddress,
            voteCase.amount,
            voteCase.desc,
            voteCase.hashCode,
            voteCase.votedRequestTime,
            voteCase.execTime
        );
    }

}
