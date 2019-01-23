var PALToken = artifacts.require('./ERC20TokenImpl.sol')

var FX2CachePage = /** @class */ (function (pageIdentifier) {

    var _identifier;
    var _cachemap = {}

    function TimeStamp() {

        return (new Date()).valueOf();
    }

    function SetCache( name, value ) {

        _cachemap[name] = value;
    }

    function GetCache( name ) {

        return _cachemap[name];
    }
})


var FX2CacheManager = /** @class */ (function () {

    var _pageManager = {}

    function CreateCachePage(identifier) {

        return new FX2CachePage(identifier);
    }

    function AddCachePage(page) {
        _pageManager[page._identifier] = page;
    }

    function GetCachePage(identifier)
    {
        return _pageManager[identifier];
    }

}

contract('ERC20TokenImpl - Modules TokenInfomation', function (accounts) {

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
