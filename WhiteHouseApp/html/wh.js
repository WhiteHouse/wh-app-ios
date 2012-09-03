
var WhiteHouse = {
    transformFontSize: function(f) {
        var $target = $("div.content");
        var fontSize = parseInt($target.css("font-size"));
        var newFontSize = f(fontSize);
        $target.css("font-size", newFontSize);
    },
    textUp: function() {
        this.transformFontSize(function(x) {
            return x + 5;
        });
    },
    textDown: function() {
        this.transformFontSize(function(x) {
            if (0 < x - 5) {
                return x - 5;
            } else {
                return x;
            }
        });
    }
};


WhiteHouse.loadPage = function(pageInfo) {
    var container = $('#article');
    try {
        var t = _.template(document.getElementById("template").innerText);
        container.html(t(pageInfo));
    } catch (e) {
        alert("Error in template: " + e.name + "; " + e.message);
    }

    $.fn.fixLinks = function(attr) {
        return this.each(function() {
            var url = $(this).attr(attr);
            if (pageInfo.baseURL) {
                if (url && url.indexOf("/") == 0) {
                    $(this).attr(attr, pageInfo.baseURL + url);
                }
            }
        });
    };
    
    container.find("a").fixLinks("href");
    container.find("img").fixLinks("src");
    
    container.find("div[style]").each(function(idx, div) {
        div.removeAttribute("style");
    });
    
    // convert any YouTube <object> embed to an iframe
    container.find("object param[name=movie]").each(function(idx, movie) {
        var videoUrl = $(movie).attr('value');
        if (videoUrl.match(/youtube/)) {
            var videoId = videoUrl.match(/\/v\/(.*)?\?/)[1];
            var src = "http://www.youtube.com/embed/" + videoId;
            var video = $("<iframe>").addClass("youtube-player").attr("type", "text/html").attr("src", src).attr("width", "100%").attr("height", "auto").attr("frameborder", "0");
            $(movie).parent().replaceWith(video);
        }
    });

    var fixIframeWidth = function(el) {
        var oldWidth = $(el).width();
        $(el).attr("width", "100%").attr("height", oldWidth / 1.6);
    };

    container.find("iframe").each(function(idx, iframe) {
        fixIframeWidth(iframe);
        var src = $(iframe).attr("src");
        $(iframe).attr("src", src + "?showinfo=0;controls=0");
    });

    $(window).on("resize", function(e) {
        $("iframe").each(function(idx, iframe) {
            fixIframeWidth(iframe);
        });
    });
}

// Local Variables:
// indent-tabs-mode: nil
// End:
