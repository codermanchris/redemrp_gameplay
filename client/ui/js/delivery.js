var delivery = {
    init: function() {
        
    },
    open: function(data) {
        $("#delivery").show();
    },
    close: function() {
        $("#delivery").hide();
    },
    acceptOffer: function() {
        core.sendPost("delivery:Start", null, function(data){});
        core.sendPost("CloseMenu", null, function(data){});
        delivery.close();
    }
}