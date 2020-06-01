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
    searchPersons: function() {
        var firstName = $("#lawman .persons .search .search-firstname").val();
        var lastName = $("#lawman .persons .search .search-lastname").val();

        core.sendPost("SearchPersons", { FirstName: firstName, LastName: lastName });
    },
    onSearchPersons: function(persons) {
        lawman.cachedPersons = persons;
        
        $("#lawman .persons .selected").hide();
        var $results = $("#lawman .persons .search-results");
        $results.show();        
        $results.html("");

        $.each(persons, function(key, value) {
            var html = "<div class='person-search-result' onclick='lawman.selectPerson({{ID}});'>{{NAME}}</div>"
                        .replace('{{ID}}', value.id)
                        .replace('{{NAME}}', value.firstname + " " + value.lastname);

            $results.append(html);
        });
    },
    selectPerson: function(playerId) {
        var person = lawman.cachedPersons.find(p => p.id === playerId);
        if (person === undefined || person === null) {
            return;
        }

        $("#lawman .persons .search-results").hide();
        $("#lawman .persons .selected").show();

        $("#lawman .persons .selected .name").html(person.firstname + " " + person.lastname);
    },

    // arrests
    searchArrests: function(caseNumber, firstName, lastName) {
        var caseNumber = $("#lawman .arrests .search .search-case").val();
        var firstName = $("#lawman .arrests .search .search-firstname").val();
        var lastName = $("#lawman .arrests .search .search-lastname").val();
        
        core.sendPost("SearchArrests", { CaseNumber: caseNumber, FirstName: firstName, LastName: lastName });
    },
    onSearchArrests: function(data) {

    },
    selectArrest: function(data) {

    },

    // warrants
    searchWarrants: function(caseNumber, firstName, lastName) {
        var caseNumber = $("#lawman .warrants .search .search-case").val();
        var firstName = $("#lawman .warrants .search .search-firstname").val();
        var lastName = $("#lawman .warrants .search .search-lastname").val();
        core.sendPost("SearchWarrants", { CaseNumber: caseNumber, FirstName: firstName, LastName: lastName });
    },
    onSearchWarrants: function(data) {

    },
    selectWarrant: function(data) {

    },
}