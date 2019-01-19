var PALToken = artifacts.require('./ERC20TokenImpl.sol')

contract('ERC20TokenImpl - Modules SettingAPI', function (accounts) {

    var AirDropAddress
    var AirDropAddressBalance

    it("SettingAPI : API_SetUnlockAmountEnable", function(){

        var nowTimestamp = (new Date()).getTime();

        var PALInstance
        return PALToken.deployed().then(function (instance) {
            PALInstance = instance
            return PALInstance.API_SetUnlockAmountEnable(nowTimestamp)
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.startUnlockDataTime.call()
        })
        .then(function(time) {
            assert.equal(time.toString(), nowTimestamp.toString())
        })
    })

    it("SettingAPI : API_SendLockBalanceTo", function(){

        var PALInstance

        return PALToken.deployed().then(function (instance) {
            PALInstance = instance
            return PALInstance.airdropAddress.call()
        })
        .then(function(addr) {
            AirDropAddress = addr;
            return PALInstance.balanceOf.call( accounts[0] )
        })
        .then(function(number) {
            AirDropAddressBalance = number * 0.5
            return PALInstance.transfer( AirDropAddress, (number * 0.5).toString() )
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.API_SendLockBalanceTo(accounts[0], "100000000000", 10)
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.balanceOf.call(AirDropAddress)
        })
        .then(function(number) {
            assert.equal( (AirDropAddressBalance - 100000000000).toString(), number.toString() )
        })
    })

    it("SettingAPI : API_SetEverDayPosMaxAmount", function(){

        var PALInstance

        return PALToken.deployed().then(function (instance) {
            PALInstance = instance
            return PALInstance.API_SetEverDayPosMaxAmount("88888888888888")
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.everDayPosTokenAmount.call()
        })
        .then(function(ret) {
            assert.equal( ret.toString(), "88888888888888" )
        })
    })

    it("SettingAPI : API_SetPosoutWriteReward", function(){

        var PALInstance

        return PALToken.deployed().then(function (instance) {
            PALInstance = instance
            return PALInstance.API_SetPosoutWriteReward("20000000000")
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.posoutWriterReward.call()
        })
        .then(function(ret) {
            assert.equal( ret.toString(), "20000000000" )
        })
    })

    it("SettingAPI : API_SetEnableWithDrawPosProfit, API_GetEnableWithDrawPosProfit", function(){

        var PALInstance

        return PALToken.deployed().then(function (instance) {
            PALInstance = instance
            return PALInstance.API_SetEnableWithDrawPosProfit(true)
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.API_GetEnableWithDrawPosProfit.call()
        })
        .then(function(ret) {
            assert.equal( ret, true )
            return PALInstance.API_SetEnableWithDrawPosProfit(true)
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.API_GetEnableWithDrawPosProfit.call()
        })
        .then(function(ret) {
            assert.equal( false, false )
        })
    })

})
