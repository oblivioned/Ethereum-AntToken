var PALToken = artifacts.require('./ERC20TokenImpl.sol')

contract('ERC20TokenImpl - Modules ERC20 Interface', function (accounts) {

    var Senderbalance;

    it("ERC20 : balanceOf", function(){
        return PALToken.deployed()
        .then(function (instance) {
            return instance.balanceOf.call(accounts[0])
        })
        .then(function(number){
            Senderbalance = number
            assert.equal(number.toString(), "150000000000000000")
        })
    })

    it("ERC20 : transfer", function() {

        var PALInstance;

        return PALToken.deployed()
        .then(function (instance) {
            PALInstance = instance
            return PALInstance.transfer(accounts[1], "50000000000000000")
        })
        .then(function(ret) {
            assert.equal( ret != undefined, true)
            return PALInstance.balanceOf.call(accounts[0])
        })
        .then(function(number) {
            assert.equal(number.toString(), "100000000000000000")
            return PALInstance.balanceOf.call(accounts[1])
        })
        .then(function(number) {
            assert.equal(number.toString(), "50000000000000000")
            return PALInstance.balanceOf.call( PALInstance.address )
        })
        .then( function(number) {
            assert.equal(number.toString(), "350000000000000000")
        })
    })

    it("ERC20 : approve, allowance, transferFrom", function() {

        var PALInstance;

        return PALToken.deployed()
        .then(function (instance) {
            PALInstance = instance
            return PALInstance.approve(accounts[1], "50000000000000000")
        })
        .then(function() {
            //设置赏金后，支出地址的余额应该不变
            return PALInstance.balanceOf.call(accounts[0])
        })
        .then(function(number) {
            assert.equal(number.toString(), "100000000000000000")
            return PALInstance.allowance.call(accounts[0], accounts[1])
        })
        .then(function(allowance) {
            assert.equal(allowance.toString(), "50000000000000000")
            return PALInstance.transferFrom( accounts[0], accounts[1], "25000000000000000", {
                from : accounts[1]
            })
        })
        .then(function(tx){
            //赏金被支出以后，owner应该扣除
            return PALInstance.balanceOf.call(accounts[0])
        })
        .then(function(number){
            assert.equal(number.toString(), "75000000000000000")
            return PALInstance.balanceOf.call(accounts[1])
        })
        .then(function(number){
            assert.equal(number.toString(), "75000000000000000")
            return PALInstance.allowance.call(accounts[0], accounts[1])
        })
        .then(function(number){
            assert.equal(number.toString(), "25000000000000000")
            return PALInstance.transfer(accounts[0], "75000000000000000", {
                from : accounts[1]
            })
        })
        .then(function(tx){
            return PALInstance.balanceOf.call(accounts[0])
        })
        .then(function(balance){
            assert.equal(balance.toString(), "150000000000000000")
        })
    })

})
