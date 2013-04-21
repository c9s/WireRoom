// Paste into firebug.

// time
timebot_interval = setInterval(function() {
    var oldnick = $("#nickname").text();
    $("#nickname").text("不整點報時");
    $("#message_body").val("-----------" + new Date() + "-----------");
    $("#message_form").submit();
    $("#nickname").text(oldnick);
}, Math.random() * 1000000 + 60000);

// moretext
moretext_interval = setInterval(function() {
    $.getJSON(
        "http://more.handlino.com/sentences.json?callback=?",
        function(d) {
            var oldnick = $("#nickname").text();
            $("#nickname").text("Moretext");
            $("#message_body").val(d.sentences[0]);
            $("#message_form").submit();
            $("#nickname").text(oldnick);
        }
    )
}, 300000);

