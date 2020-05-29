var lawman = {
    currentTab: -1,

    init: function() {
        
    },
    open: function() {
        $("#lawman").show();
    },
    close: function() {
        $("#lawman").hide();
    },

    // tabs
    openTab: function(tabId) {
        lawman.closeTab();

        this.currentTab = tabId;
        $("#lawman .tab" + tabId).show();
    },
    closeTab: function() {
        if (this.currentTab !== -1) {
            $("#lawman .tab" + this.currentTab).hide();
            this.currentTab = -1;
        }
    },

    // persons
    searchPersons: function(name) {

    },

    // arrests
    searchArrests: function(caseNumber, name) {

    },

    // warrants
    searchWarrants: function(caseNumber, name) {

    }
}