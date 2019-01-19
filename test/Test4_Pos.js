var PALToken = artifacts.require('./ERC20TokenImpl.sol')

contract('ERC20TokenImpl - Modules Pos', function (accounts) {

    var SenderBalance;
    var PALInstance;

    var BNZero = new web3.utils.BN("0");

    it("Config Test Data", function() {

        return PALToken.deployed().then(function (instance) {
            PALInstance = instance;
            return PALInstance.GetCurrentPosSum.call()
        })
        .then(function(sum) {
            assert.equal( sum.toString(), BNZero.toString(), "Begin starting this test GetCurrentPosSum must be 0." )
            return PALInstance.GetPosRecords.call()
        })
        .then(function(response) {
            assert.equal(response.len , "0", "Begin starting this test GetPosRecords must be 0.")
            return PALInstance.balanceOf.call(accounts[0])
        })
        .then(function(balance){
            assert.equal(balance.toString() , "150000000000000000", "Begin starting this test balance must be 15E.")
            return PALInstance.DespoitToPos("100000000000")
        })
        .then(function() {
            return PALInstance.DespoitToPos("200000000000")
        })
        .then(function() {
            return PALInstance.DespoitToPos("300000000000")
        })
        .then(function() {
            return PALInstance.DespoitToPos("400000000000")
        })
        .then(function() {
            return PALInstance.DespoitToPos("500000000000")
        })
        .then(function() {
            return PALInstance.DespoitToPos("600000000000")
        })
        .then(function() {
            return PALInstance.DespoitToPos("700000000000")
        })
        .then(function() {
            return PALInstance.DespoitToPos("800000000000")
        })
        .then(function() {
            return PALInstance.DespoitToPos("900000000000")
        })
        .then(function() {
            return PALInstance.DespoitToPos("1000000000000")
        })
        .then(function() {
            return PALInstance.balanceOf.call(accounts[0])
        })
        .then( function(balance) {
            SenderBalance = balance;
            return PALInstance.GetCurrentPosSum.call()
        })
        .then( function(sum) {
            assert.equal( sum.toString(), "5500000000000", "PosPoll total sum error.");
        })
    })

    it("Pos : GetPosRecords", function() {

        return PALInstance.GetPosRecords.call()
        .then(function(response) {

            assert.equal(response.len, 10);
            assert.equal(response.amount.length, 10);
            assert.equal(response.depositTime.length, 10);
            assert.equal(response.lastWithDrawTime.length, 10);
            assert.equal(response.prefix.length, 10);

            return PALInstance.balanceOf.call(accounts[0])
        })
        .then(function(balance) {
            assert.equal( SenderBalance.toString(), balance.toString());
        })
    })

    it("Pos : RescissionPosAt,RescissionPosAll", function() {

        return PALInstance.RescissionPosAt(0)
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.RescissionPosAt(0)
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.RescissionPosAt(0)
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.RescissionPosAt(0)
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.RescissionPosAt(0)
        })
        .then(function(tx) {
            return PALInstance.GetPosRecords.call()
        })
        .then(function(response) {

            assert.equal(response.len, 5);
            assert.equal(response.amount.length, 5);
            assert.equal(response.depositTime.length, 5);
            assert.equal(response.lastWithDrawTime.length, 5);
            assert.equal(response.prefix.length, 5);

            return PALInstance.balanceOf.call(accounts[0])
        })
        .then( function(balance ) {
            var pay = new web3.utils.BN("1500000000000");
            assert.equal( (SenderBalance.add(pay)).toString(), balance.toString());
            return PALInstance.RescissionPosAt(4);
        })
        .then(function(tx){
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.GetPosRecords.call()
        })
        .then(function(response) {
            return PALInstance.GetCurrentPosSum.call()
        })
        .then( function(sum) {
            assert.equal( sum.toString(), "3000000000000");
            return PALInstance.RescissionPosAll();
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.GetPosRecords.call()
        })
        .then( function(response) {
            assert.equal(response.len, 0);
            return PALInstance.GetCurrentPosSum.call()
        })
        .then(function(sum){
            assert.equal( sum.toString(), BNZero.toString() )
        })
    })

    it("Pos : GetCurrentPosSum", function() {

        return PALToken.deployed().then(function (instance) {
            PALInstance = instance;
            return PALInstance.GetCurrentPosSum.call()
        })
        .then(function(sum) {
            assert.equal(sum.toString(), "0");
            return PALInstance.DespoitToPos("100000000000")
        })
        .then(function() {
            return PALInstance.DespoitToPos("200000000000")
        })
        .then(function() {
            return PALInstance.DespoitToPos("300000000000")
        })
        .then(function() {
            return PALInstance.GetCurrentPosSum.call()
        })
        .then(function( sum ) {
            assert.equal( sum.toString(), "600000000000" );
            return PALInstance.RescissionPosAt(2);
        })
        .then(function(tx){
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.GetCurrentPosSum.call()
        })
        .then(function( sum ) {
            assert.equal( sum.toString(), "300000000000" );
            return PALInstance.RescissionPosAll()
        })
        .then(function(tx){
            assert.equal(tx != undefined, true, "Transction Faild.");
        })
    });

    it( "Pos : ProfitTest Case 1 : Nomal test", function() {

        var testBeginBalance;
        var oneDayTime = 86400
        var testPosoutTime = parseInt((new Date()).getTime() / 1000 - 20 * oneDayTime);
        testPosoutTime = parseInt(testPosoutTime / oneDayTime) * oneDayTime

        var testPosrecordTime = testPosoutTime - oneDayTime * 1.5

        return PALToken.deployed().then(function (instance) {
            PALInstance = instance;
            return PALInstance.balanceOf(accounts[0])
        })
        .then(function(balance) {
            testBeginBalance = balance
            //投入Pos池,使用测试接口，时间为当前时间的21.5天前
            return PALInstance.TestAPI_DespoitToPosByTime(testBeginBalance.toString(), testPosrecordTime.toString())
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            //使用测试接口直接写入Posout数据写入时间为当前时间的前20天
            return PALInstance.TestAPI_CreatePosoutRecordAtTime(testPosoutTime.toString())
        })
        .then(function(tx) {
            //检测写入是否成功
            return PALInstance.GetPosoutLists.call()
        })
        .then(function(response) {

            // 扩大10 ** 16倍计算
            var d = new web3.utils.BN("10000000000000000")
            var everCointProfit = response.posouttotal[0].mul(d).div(testBeginBalance)
            everCointProfit = everCointProfit.div(d.div(new web3.utils.BN("100000000")))

            //检测写入数据是否正确
            assert.equal(response.len.toString(), "1")
            assert.equal(response.posouttotal[0].toString(), "90000000000000")
            assert.equal(response.profitByCoin[0].toString(), everCointProfit.toString() )
            assert.equal(response.posoutTime[0].toString(), testPosoutTime.toString())
            //检查收益
            return PALInstance.GetPosRecords.call()
        })
        .then(function(response) {
            assert.equal(response.len.toString(), "1")
            assert.equal(response.amount[0].toString(), testBeginBalance.toString())
            assert.equal(response.depositTime[0].toString(), testPosrecordTime.toString())
            assert.equal(response.lastWithDrawTime[0].toString(), "0")
            assert.equal(response.prefix[0].toString(), "90000000000000")
            //直写后4天的产出记录
            for ( var i = 1; i < 5; i++ )
            {
                PALInstance.TestAPI_CreatePosoutRecordAtTime( (testPosoutTime + i * oneDayTime ).toString())
                .then(function(x) {
                    assert.equal(x != undefined, true, "Transction Faild.");
                })
            }

            return PALInstance.GetPosRecords.call()
        })
        .then(function(response) {
            assert.equal(response.len.toString(), "1")
            assert.equal(response.amount[0].toString(), "150000000000000000")
            assert.equal(response.depositTime[0].toString(), testPosrecordTime.toString())
            assert.equal(response.lastWithDrawTime[0].toString(), "0")
            assert.equal(response.prefix[0].toString(), "450000000000000")

            // 提取收益
            return PALInstance.WithDrawPosProfit(0)
        })
        .then( function(response) {
            return PALInstance.balanceOf.call(accounts[0])
        })
        .then( function(balance) {
            assert.equal(balance.toString(), "450000000000000")
            //直写后5-10天的产出记录
            for ( var i = 5; i < 10; i++ )
            {
                PALInstance.TestAPI_CreatePosoutRecordAtTime( (testPosoutTime + i * oneDayTime ).toString())
                .then(function(x) {
                    assert.equal(x != undefined, true, "Transction Faild.");
                })
            }
            // 本利全提,解除所有Pos合约
            return PALInstance.RescissionPosAll()
        })
        .then(function() {
            return PALInstance.balanceOf.call(accounts[0])
        })
        .then(function(balance) {
            var amount = new web3.utils.BN("150000000000000000");
            var ever5DayProfit = new web3.utils.BN("450000000000000");
            var sum = amount.add(ever5DayProfit).add(ever5DayProfit);
            assert.equal(balance.toString(), sum.toString())
            return PALInstance.GetPosRecords.call()
        })
        .then(function(response){
            assert.equal(response.len.toString(), "0", "After RescissionPosAll still have data in POSDBTable.");
            return PALInstance.GetCurrentPosSum.call()
        })
        .then(function(posTotalSum){
            assert.equal( posTotalSum, "0", "After RescissionPosAll call GetCurrentPosSum must be 0.");
        })
    });

    it( "Pos : ProfitTest Case 2 : 0.3% revenue cap test", function() {

        var testBeginBalance;
        var oneDayTime = 86400
        var testPosoutTime = parseInt((new Date()).getTime() / 1000 - 9 * oneDayTime);
        testPosoutTime = parseInt(testPosoutTime / oneDayTime) * oneDayTime

        var testPosrecordTime = testPosoutTime - oneDayTime * 1.5

        return PALToken.deployed().then(function (instance) {
            PALInstance = instance;
            return PALInstance.balanceOf(accounts[0])
        })
        .then(function(balance) {
            testBeginBalance = balance
            //投入Pos池,使用测试接口，时间为当前时间的9.5天前
            return PALInstance.TestAPI_DespoitToPosByTime("100000000000", testPosrecordTime.toString())
        })
        .then(function(tx) {
            //写入一个8天前的产出记录
            return PALInstance.TestAPI_CreatePosoutRecordAtTime( (testPosoutTime + oneDayTime ).toString())
        })
        .then(function(x) {
            assert.equal(x != undefined, true, "Transction Faild.");
            return PALInstance.GetPosoutLists.call()
        })
        .then(function(response) {
            //检测写入数据是否正确,上一个测试用例已经在合约中写入了10个Posout记录
            assert.equal(response.len.toString(), "11")
            assert.equal(response.posouttotal[10].toString(), "90000000000000")
            assert.equal(response.profitByCoin[10].toString(), "90000000000")
            assert.equal(response.posoutTime[10].toString(), (testPosoutTime + oneDayTime).toString())
            //检查收益
            return PALInstance.GetPosRecords.call()
        })
        .then(function(response) {
            assert.equal(response.len.toString(), "1")
            assert.equal(response.amount[0].toString(), "100000000000")
            assert.equal(response.depositTime[0].toString(), testPosrecordTime.toString())
            assert.equal(response.lastWithDrawTime[0].toString(), "0")
            assert.equal(response.prefix[0].toString(), "300000000")

            //直写后9天的产出记录
            for ( var i = 1; i < 10; i++ )
            {
                PALInstance.TestAPI_CreatePosoutRecordAtTime( (testPosoutTime + i * oneDayTime ).toString())
                .then(function(x) {
                    assert.equal(x != undefined, true, "Transction Faild.");
                })
            }
            return PALInstance.GetPosRecords.call()
        })
        .then(function(response) {
            assert.equal(response.len.toString(), "1")
            assert.equal(response.amount[0].toString(), "100000000000")
            assert.equal(response.depositTime[0].toString(), testPosrecordTime.toString())
            assert.equal(response.lastWithDrawTime[0].toString(), "0")
            assert.equal(response.prefix[0].toString(), "3000000000")
            return PALInstance.RescissionPosAll()
        })
        .then(function(response) {
            return PALInstance.balanceOf(accounts[0])
        })
        .then(function(balance) {
            var amount = new web3.utils.BN("150000000000000000");
            var case1Profit = new web3.utils.BN("900000000000000");
            var case2Profit = new web3.utils.BN("3000000000");

            assert.equal(balance.toString(), amount.add(case1Profit).add(case2Profit))
        })
    })

    it( "Pos : ProfitTest Case 3 : Synthetic test", function() {
        // 900000 / 180000000 = 0.005(每Token收益)
        // Pos池达到 30000000个 时候，当前设定的900000日产出可全部产出
        // 用例说明 ：
        // Account_0 ：

        // Account_1 ：投入 179999900，一日后应有本息 1500000, 封顶数额 1003000，超过封顶数额得 1003000
        // Account_2 ：投入       100，一日后应有本息 100.3，

        var testBeginBalance = new web3.utils.BN("150900003000000000");

    })
})
