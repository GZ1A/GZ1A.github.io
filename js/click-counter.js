function setCookie(cname, cvalue, exdays, path = "", domain = "") {
  var d = new Date();
  d.setTime(d.getTime() + (exdays * 24 * 60 * 60 * 1000));
  var expires = "expires=" + d.toGMTString();
  var path = "path=" + path;
  var domain = "domain=" + domain;
  document.cookie = cname + "=" + cvalue + "; " + expires + "; " + domain + "; " + path;
}

function getCookie(cname) {
  var name = cname + "=";
  var ca = document.cookie.split(';');
  for (var i = 0; i < ca.length; i++) {
    var c = ca[i].trim();
    if (c.indexOf(name) == 0) return c.substring(name.length, c.length);
  }
  return "";
}

// init
let domain = "disorder.ink";
let cookie_count = getCookie('click_count');
var _click_count = cookie_count == undefined ? 0 : cookie_count;
console.log("_click_count = " + _click_count);

// click event
$("body").bind("click", function (e) { //直接给body一个事件好了.
  var $i = $("<t>").text("+" + (++_click_count) + "s"); //添加到页面的元素
  var x = e.pageX,
    y = e.pageY; //鼠标点击的位置
  $i.css({
    "z-index": 99999,
    "top": y - 15,
    "left": x,
    "position": "absolute",
    "color": "0,0,0",
    "opacity": 0.8
  });
  $("body").append($i);
  $i.animate({
      "top": y + 120,
      "opacity": 0
    },
    1000,
    function () {
      $i.remove();
    }
  );
  e.stopPropagation();
  setCookie('click_count', _click_count, 36500, '/');
  // setCookie('click_count', _click_count, 36500, '/', domain);
});
