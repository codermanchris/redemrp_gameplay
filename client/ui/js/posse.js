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

    // handle create posse
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
        
    },

    // handle posse invite
    openInvite: function(data) {
        $("#posseinvitename").html(data.PosseName);
        $("#posseinvitedby").html(data.InvitedBy);
        $("#posseinvite").show();
    },
    closeInvite: function() {
        $("#posseinvitename").html('');
        $("#posseinvitedby").html('');
        $("#posseinvite").hide();
        core.sendPost("LoseUIFocus", null, function(data){});
    },
    acceptInvite: function() {
        core.sendPost("posse:AcceptInvite", null, function(data){});
        $("#posseinvite").hide();
        core.sendPost("LoseUIFocus", null, function(data){});        
    }
}