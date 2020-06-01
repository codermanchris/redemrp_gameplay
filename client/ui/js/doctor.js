var doctor = {
    init: function() {
        
    },
    open: function(data) {
        $("#doctor").show();
    },
    close: function() {
        $("#doctor").hide();
    },
    acceptOffer: function() {
        core.sendPost("doctor:Start", null, function(data){});
        core.sendPost("CloseMenu", null, function(data){});
        doctor.close();
    }
}