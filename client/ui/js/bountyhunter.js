var bountyHunter = {
    postTemplate: "<div id='bounty_{{ID}}' class='posting' onclick='bountyHunter.selectBounty({{ID}});'>\
                    <img src='images/face.jpg' /><br />\
                    <span style='font-size: 1.0em; color: red;'>${{BOUNTY}}.00</span><br />\
                    {{NAME}}<br />\
                    {{CHARGE}}</div>",

    init: function() {
        
    },
    open: function(data) {
        $("#bountyhunter").show();
    },
    close: function() {
        $("#bountyhunter").hide();
    },
    setBoard: function(bounties) {
        $("#bountyhunter").html("");
        $.each(bounties, function(key, value) {
            var html = bountyHunter.postTemplate
                .replace(/{{ID}}/g, value.Id)
                .replace("{{BOUNTY}}", value.Crime.Reward)
                .replace("{{CHARGE}}", value.Crime.Name)
                .replace("{{NAME}}", value.FirstName + " " + value.LastName);
            $("#bountyhunter").append(html);
        });
    },
    selectBounty: function(bountyId) {
        dialogs.yesNo.show('Select Bounty', 'Are you sure you want to select this bounty?', function(value) {
            if (value) {
                core.sendPost("SelectBounty", { bountyId: bountyId }, function(data){});
            }
        });
    }
}