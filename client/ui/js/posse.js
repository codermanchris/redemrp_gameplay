var posse = {
    init: function() {
        
    },
    open: function(data) {
        $("#posse").show();

        $("#possename").html(data.Posse.Name);
        $("#posse .members").html("");

        $.each(data.Members, function(key, value) {
            var html = "<div>" + value.firstname + " " + value.lastname + "</div>";
            $("#posse .members").append(html);
        });        
    },
    close: function() {
        $("#posse").hide();
    },

    showCreate: function() {
        $("#createposse").show();
    },
    closeCreate: function() {
        $("#createposse").hide();
        core.sendPost("LoseUIFocus", null, function(data){});
    },
    create: function() {
        var posseName = $("#newpossename").val();
        if (posseName.length == 0) {
            return;
        }

        core.sendPost("posse:Create", { posseName: posseName }, function(data){});
        $("#newpossename").attr("disabled", true);
    },
    onCreated: function(data) {
        
    }
}