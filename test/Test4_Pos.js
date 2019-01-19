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
        .then(function(sum){
            assert.equal( sum.toString(), BNZero.toString() )
            return PALInstance.DespoitToPos("100000000000")
        })
        .then(function(){
            return PALInstance.DespoitToPos("200000000000").then(function(){})
        })
        .then(function(){
            return PALInstance.DespoitToPos("300000000000").then(function(){})
        })
        .then(function(){
            return PALInstance.DespoitToPos("400000000000").then(function(){})
        })
        .then(function(){
            return PALInstance.DespoitToPos("500000000000").then(function(){})
        })
        .then(function(){
            return PALInstance.DespoitToPos("600000000000").then(function(){})
        })
        .then(function(){
            return PALInstance.DespoitToPos("700000000000").then(function(){})
        })
        .then(function(){
            return PALInstance.DespoitToPos("800000000000").then(function(){})
        })
        .then(function(){
            return PALInstance.DespoitToPos("900000000000").then(function(){})
        })
        .then(function(){
            return PALInstance.DespoitToPos("1000000000000").then(function(){})
        })
        .then(function() {
            return PALInstance.balanceOf.call(accounts[0])
        })
        .then( function(balance) {
            SenderBalance = balance;
            return PALInstance.GetCurrentPosSum.call()
        })
        .then( function(sum) {
            assert.equal( sum.toString(), "5500000000000");
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
        })
    });
})
