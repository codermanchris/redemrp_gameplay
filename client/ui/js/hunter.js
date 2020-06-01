var hunter = {
    init: function() {
        
    },
    open: function(data) {
        $("#hunter").show();
    },
    close: function() {
        $("#hunter").hide();
    },
    acceptOffer: function() {
        core.sendPost("hunter:Start", null, function(data){});
        core.sendPost("CloseMenu", null, function(data){});
        hunter.close();
    }
}