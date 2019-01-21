var PALToken = artifacts.require('./ERC20TokenImpl.sol')

contract('ERC20TokenImpl - Modules SettingAPI', function (accounts) {

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

    it("SettingAPI : API_SendLockBalanceTo ( Jump )", function(){

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
            return PALInstance.API_SetEverDayPosMaxAmount("900000")
        })
        .then(function(tx){
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.everDayPosTokenAmount.call()
        })
        .then(function(ret) {
            assert.equal( ret.toString(), "900000" )
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
            return PALInstance.API_SetPosoutWriteReward("0")
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
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
            return PALInstance.API_SetEnableWithDrawPosProfit(false)
        })
        .then(function(tx) {
            assert.equal(tx != undefined, true, "Transction Faild.");
            return PALInstance.API_SetEnableWithDrawPosProfit(true)
        })
    })

})
