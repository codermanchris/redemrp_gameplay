var vehicleRental = {
    init: function() {

    },
    open: function(data) {
        $("#vehiclerental").show();
    },
    close: function() {
        $("#vehiclerental").hide();
    },
    rentVehicle: function(vehicleId) {
        core.sendPost("vehiclerental:Select", { vehicleId: vehicleId }, function(data){});     
    }
}