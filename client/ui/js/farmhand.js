var farmhand = {
    init: function() {
        
    },
    open: function(data) {
        $("#farmhand").show();
    },
    close: function() {
        $("#farmhand").hide();
    },
    acceptOffer: function() {
        core.sendPost("farmhand:Start", null, function(data){});
        core.sendPost("CloseMenu", null, function(data){});
        farmhand.close();
    }
}