var PALToken = artifacts.require('./ERC20TokenImpl.sol')

contract('ERC20TokenImpl - Modules TokenInfomation', function (accounts) {

    it("Info : PerMinerAmount", function(){
        return PALToken.deployed().then(function (instance) {
            return instance.perMinerAmount.call()
        })
        .then(function(number){
            assert.equal(number.toString(), "150000000000000000")
        })
    })

    it("Info : EverDayPosTokenAmount", function(){
        return PALToken.deployed().then(function (instance) {
            return instance.everDayPosTokenAmount.call()
        })
        .then(function(number){
            assert.equal(number.toString(), "900000")
        })
    })

    it("Info : MaxRemeberPosRecord", function(){
        return PALToken.deployed().then(function (instance) {
            return instance.maxRemeberPosRecord.call()
        })
        .then(function(number){
            assert.equal(number.toString(), "30")
        })
    })

    it("Info : JoinPosMinAmount", function(){
        return PALToken.deployed().then(function (instance) {
            return instance.joinPosMinAmount.call()
        })
        .then(function(number){
            assert.equal(number.toString(), "10000000000")
        })
    })

    it("Info : StartUnlockDataTime", function(){
        return PALToken.deployed().then(function (instance) {
            return instance.startUnlockDataTime.call()
        })
        .then(function(number){
            assert.equal(number.toString(), "0")
        })
    })

    it("Info : PosoutWriterReward", function(){
        return PALToken.deployed().then(function (instance) {
            return instance.posoutWriterReward.call()
        })
        .then(function(number){
            assert.equal(number.toString(), "0")
        })
    })
})
