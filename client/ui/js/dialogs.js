var dialogs = {
    init: function() {
        dialogs.message.init();
        dialogs.yesNo.init();
    },

    // message dialog
    message: {
        $dialog: null,

        init: function() {
            this.$dialog = $("#messageDialog");
        },
        show: function(message) {
            this.$dialog.html(message);
            this.$dialog.show();
        },
        close: function() {
            this.$dialog.hide();
        }
    },

    // yes/no dialog
    yesNo: {
        $dialog: null,
        $message: null,
        $title: null,
        callback: null,

        init: function() {
            this.$dialog = $("#yesNoDialog");
            this.$title = $("#yesNoDialog .title");
            this.$message = $("#yesNoDialog .message");
        },
        show: function(title, message, cb) {
            this.callback = cb;

            $("#yesNoDialog .title").html(title);
            $("#yesNoDialog .message").html(message);            
            $("#yesNoDialog").show();
        },
        close: function() {
            $("#yesNoDialog .message").html("");
            $("#yesNoDialog .title").html("");
            $("#yesNoDialog").hide();

            this.callback = null;
        },
        yes: function() {
            this.callback(true);
            this.close();
        },
        no: function() {
            this.callback(false);
            this.close();
        }
    },

    quantity: {
        $dialog: null,
        $title: null,
        $message: null,
        callback: null,

        init: function() {
            this.$dialog = $("#quantityDialog");
            this.$title = $("#quantityDialog .title");
            this.$message = $("#quantityDialog .message");
        },
        show: function(title, message, cb) {
            this.callback = cb;

            this.$title.html(title);
            this.$message.html(message);            
        },
        close: function() {
            this.$title.html("");
            this.$message.html("");             
            this.$dialog.hide();
            this.callback = null;
        },
        accept: function() {
            var amount = $("#quantityAmount").val();
            if (!parseInt(amount)) {
                amount = 0;
            }
            this.callback(true, amount);
        },
        cancel: function() {
            this.callback(false, 0);
        }
    }
}