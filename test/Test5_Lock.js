var PALToken = artifacts.require('./ERC20TokenImpl.sol')

contract('ERC20TokenImpl - Modules Lock', function (accounts) {

    var PALInstance;
    var BNZero = new web3.utils.BN("0");
    var oneDayTime = 86400
    var TestLockTime = parseInt((new Date()).getTime() / 1000 - 30 * oneDayTime);
    TestLockTime = parseInt(TestLockTime / oneDayTime) * oneDayTime

    it("Config Test Data", function() {

        return PALToken.deployed().then(function (instance) {
            PALInstance = instance;
            // 发送锁仓余额,1000-10日,测试使用的时间在30.5天前
            return PALInstance.TestAPI_SendLockBalanceByTime(accounts[0], "10000000000", "10", TestLockTime - 0.5 * oneDayTime )
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            //发送锁仓余额,2000-20日,测试使用的时间在30.5天前
            return PALInstance.TestAPI_SendLockBalanceByTime(accounts[0], "20000000000", "20", TestLockTime - 0.5 * oneDayTime)
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            //发送锁仓余额,3000-20日,测试使用的时间在14.5天前
            return PALInstance.TestAPI_SendLockBalanceByTime(accounts[0], "30000000000", "30", TestLockTime + 14.5 * oneDayTime)
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.GetLockRecords.call()
        })
        .then(function(response)
        {
            assert.equal( response.len.toString(), "3" );
            //设置开始释放的时间为30天前
            return PALInstance.API_SetUnlockAmountEnable(TestLockTime)
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
        })
    })

    it("Lock : GetLockRecords", function() {

        return PALToken.deployed().then(function (instance) {
            PALInstance = instance;
            //将Account_0的余额全部转出，保持余额为0
            return PALInstance.GetLockRecords.call()
        })
        .then(function(response) {

            assert.equal( response.len.toString(), "3" );

            for (var i = 0; i < 3; i++)
            {
                assert.equal( response.totalAmount[i].toString(), (10000000000 * (i + 1)).toString() )
                assert.equal( response.withdrawAmount[i].toString(), "0")
                assert.equal( response.lastWithdrawTime[i].toString(), "0")
                assert.equal( response.lockDays[i].toString(), (10 * (i + 1)).toString() )

                if ( i < 2 )
                {
                    assert.equal( response.profit[i].toString(), (10000000000 * (i + 1)).toString() )
                }
                else {
                    //第三笔测试数据应该只能获取到一半的收益
                    assert.equal( response.profit[i].toString(), (30000000000 / 2).toString() )
                }
            }
        })
    })

    it("Lock : WithDrawLockRecordProFit", function(){

        var beforWithDrawBalance;

        return PALToken.deployed().then(function (instance) {
            PALInstance = instance;

            return PALInstance.balanceOf(accounts[0])
        })
        .then(function(balance) {
            beforWithDrawBalance = balance;
            return PALInstance.WithDrawLockRecordProFit(0)
        })
        .then(function(tx){
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.balanceOf(accounts[0])
        })
        .then(function(balance) {
            assert.equal( beforWithDrawBalance.add( new web3.utils.BN("10000000000")).toString(), balance.toString())
            // 对于全部释放完成的，再次提取应该没有任何收益
            return PALInstance.WithDrawLockRecordProFit(0)
        })
        .then(function(tx){
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.balanceOf(accounts[0])
        })
        .then(function(balance) {
            assert.equal( beforWithDrawBalance.add( new web3.utils.BN("10000000000")).toString(), balance.toString())
        })
    })

    it("Lock : WithDrawLockRecordAllProfit", function(){
        var beforWithDrawBalance;

        return PALToken.deployed().then(function (instance) {
            PALInstance = instance;
            return PALInstance.balanceOf(accounts[0])
        })
        .then(function(balance) {
            beforWithDrawBalance = balance;
            return PALInstance.WithDrawLockRecordAllProfit()
        })
        .then(function(response) {
            return PALInstance.balanceOf(accounts[0])
        })
        .then(function(balance) {
            //由于上一个用例已经提取了10000000000，所以此处应该是35000000000的收益
            assert.equal( beforWithDrawBalance.add( new web3.utils.BN("35000000000")).toString(), balance.toString() )
            return PALInstance.WithDrawLockRecordAllProfit()
        })
        .then(function(response) {
            return PALInstance.balanceOf(accounts[0])
        })
        .then(function(balance) {
            assert.equal( beforWithDrawBalance.add( new web3.utils.BN("35000000000")).toString(), balance.toString() )
        })
    })


})
