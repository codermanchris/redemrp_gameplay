var pigeonCarrier = {
    init: function() {
        
    },
    open: function(data) {
        $("#pigeoncarrier").show();

        if (data.IsSender) {
            $("#newpigeonmessage").val("");
            $("#pigeoncarrier .sender").show();
            $("#pigeoncarrier .receiver").hide();
            $("#newpigeonmessage").focus();
        } else {
            $("#pigeoncarrier .sender").hide();
            $("#pigeoncarrier .receiver").show();
            $("#pigeonmessage").html(data.Message);
        }
    },
    close: function() {
        $("#pigeoncarrier").hide();
        core.sendPost("CloseMenu", null, function(data){});
    },
    send: function() {
        var message = $("#newpigeonmessage").val();
        core.sendPost("player:SendPigeon", { Message: message }, function(data) {});

        pigeonCarrier.close();
    }
}