// https://blog.csdn.net/shua67/article/details/81535883
function clearCookie() {
  var keys = document.cookie.match(/[^ =;]+(?=\=)/g);
  if (keys) {
    for (var i = keys.length; i--;) {
      document.cookie = keys[i] + '=0;path=/;expires=' + new Date(0).toUTCString(); //清除当前域名下的,例如：m.kevis.com
      document.cookie = keys[i] + '=0;path=/;domain=' + document.domain + ';expires=' + new Date(0).toUTCString(); //清除当前域名下的，例如 .m.kevis.com
      document.cookie = keys[i] + '=0;path=/;domain=kevis.com;expires=' + new Date(0).toUTCString(); //清除一级域名下的或指定的，例如 .kevis.com
    }
  }
  $("#divcookie").html(document.cookie);
  alert('已清除 cookies');
}
