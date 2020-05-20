$(function() {
    currentMenu = null;

    // receive messages coming from game layer
    window.addEventListener('message', function(event) {
        var item = event.data;    
        if (item.target) {            
            var ui = core.getUI(item.target);
            if (ui !== undefined) {
                currentMenu = item.target;
                var method = ui[item.method];
                if (method !== undefined) {
                    method(item.data);
                }
            }
        }
    }, false);

    // detect escape and close menus if needed
    $(document).keyup(function(e) {
        if (e.keyCode === 27) {
            if (currentMenu !== null && currentMenu !== '') {
                var ui = core.getUI(currentMenu);
                if (ui !== undefined) {
                    var method = ui['close'];
                    if (method !== undefined) {
                        method();
                    }
                }
                currentMenu = null;
            }
            core.sendPost("CloseMenu", null, function(data){});
        }
    });

    // init core ui systems
    core.init();
});

var core = {
    uis: [],
    init: function() {
        console.log('redemrp_gameplay ui systems initialized.');        

        // jobs
        core.registerUI("bountyhunter", bountyHunter);
        core.registerUI("delivery", delivery);
        core.registerUI("doctor", doctor);
        core.registerUI("fisher", fisher);
        core.registerUI("hunter", hunter);
        core.registerUI("lawman", lawman);
        core.registerUI("moonshiner", moonshiner);
    },

	sendPost: function(url, parameters) {
		$.post("http://redemrp_gameplay/" + url, JSON.stringify(parameters), function(data) {
			 console.log(data);
		});
    },
    
    registerUI: function(name, ui) {
        core.uis[name] = ui;
        ui.init();
    },
    getUI: function(name) {
        return core.uis[name];
    },
};