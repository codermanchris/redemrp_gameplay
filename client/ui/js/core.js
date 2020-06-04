$(function() {
    currentMenu = null;

    // receive messages coming from game layer
    window.addEventListener('message', function(event) {
        var item = event.data;    
        if (item.target) {            
            var ui = null;
            if (item.target === 'core') {
                ui = core;
            } else {
                ui = core.getUI(item.target);
            }

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
            if (currentMenu !== null && currentMenu !== '' && currentMenu !== 'core') {
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
    progressBar: null,
    progressBarValue: 0.0,
    uis: [],
    init: function() {
        //
        console.log('redemrp_gameplay ui systems initialized.');        

        // jobs
        core.registerUI("bountyhunter", bountyHunter);
        core.registerUI("delivery", delivery);
        core.registerUI("doctor", doctor);
        core.registerUI("farmhand", farmhand);
        core.registerUI("fisher", fisher);
        core.registerUI("hunter", hunter);
        core.registerUI("lawman", lawman);
        core.registerUI("moonshiner", moonshiner);
        core.registerUI("posse", posse);
        core.registerUI("vehiclerental", vehicleRental);

        // test
        core.progressBar = new RadialProgress(document.getElementById("progressBar"),{indeterminate:true,colorFg:"#FFFFFF",thick:2.5,fixedTextSize:0.3});
        core.progressBar.setIndeterminate(false);
        core.progressBar.setValue(0.0);
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
    
    // progress bar stuffs
    initProgressBar: function(data) {
        core.progressTickRate = data.Rate;
        core.progressBarValue = 0.0;
        core.progressBar.setValue(0.0);
        core.startProgressBar();
    },
    startProgressBar: function() {
        $("#progressBar").show();

        setTimeout(function() {
            core.progressBarValue += core.progressTickRate;
            core.progressBar.setValue(core.progressBarValue);

            if (core.progressBarValue < 1.0) {
                core.startProgressBar();
            } else {
                // we have to do this to let the animation of the progress bar finish 
                setTimeout(core.hideProgressBar, 500);
            }
        }, 1000);
    },
    hideProgressBar: function() {
        $("#progressBar").hide();
    }
    //
};