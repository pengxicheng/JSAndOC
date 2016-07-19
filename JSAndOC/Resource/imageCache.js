//一加载这个js就会调用下面自己写的onLoaded() 方法
window.onload = function() {
    onLoaded();
}

//使用WebViewJavascriptBridge的话，这一段是必须的
function connectWebViewJavascriptBridge(callback) {
    if (window.WebViewJavascriptBridge) {
        callback(WebViewJavascriptBridge)
    } else {
        document.addEventListener('WebViewJavascriptBridgeReady', function() {
                                  callback(WebViewJavascriptBridge)
                                  }, false)
    }
}

//上面已经说了，一插入js，这个方法就开始执行
function onLoaded() {
    connectWebViewJavascriptBridge(function(bridge) {
                                   //document.querySelectorAll：按文档顺序返回指定元素节点的子树中匹配选择器的元素集合，如果没有匹配返回空集合
                                   //下面这几句是提取所有img标签的esrc属性值（图片的URL），并存到imageUrlsArray这个数组中
                                   var allImage = document.querySelectorAll("img");
                                   allImage = Array.prototype.slice.call(allImage, 0);
                                   var imageUrlsArray = new Array();
                                   allImage.forEach(function(image) {
                                                    var esrc = image.getAttribute("esrc");
                                                    var newLength = imageUrlsArray.push(esrc);
                                                    });
                                   //将imageUrlsArray这个数组发送到OC的block
                                   bridge.send(imageUrlsArray);////四种关系图表之第1种
                                   
                                   bridge.init(function(message, responseCallback) {
                                               alert(message);
                                               if (responseCallback) {
                                               responseCallback("Message1已收到，送你个Message2")
                                               }
                                    })
                                   //这里先注册下，等待OC代码的_bridge调用([_bridge callHandler:....])
                                   bridge.registerHandler('imagesDownloadComplete', function(data, responseCallback) {
                                                          var allImage = document.querySelectorAll("img");
                                                          allImage = Array.prototype.slice.call(allImage, 0);
                                                          allImage.forEach(function(image) {
                                                                           if (image.getAttribute("esrc") == data[0] || image.getAttribute("esrc") == decodeURIComponent(data[0])) {
                                                                           image.src = data[1];
                                                                           }
                                                                           
                                                                           });
                                                          responseCallback("图片"+data[0]+"已加载")
                                                          })
                                   
                                   //使用WebViewJavascriptBridge的话，这一段是必须的，不然上面的imageUrlsArray传不过去
                                   bridge.send('Please respond to this', function responseCallback(responseData) {
                                               console.log("Javascript got its response", responseData)
                                               })
                                   });
    
}

//图片点击会触发
function onImageClick(picUrl){
    connectWebViewJavascriptBridge(function(bridge) {
                                   //作者用的是"p img[esrc]"，意思是获取p标签里的img的src值
                                   //我这里的图片是div，所以要改成"div img[esrc]"
                                   //var allImage = document.getElementsByTagName('img');//这样比较通用
                                   var allImage = document.querySelectorAll("div img[esrc]");
                                   allImage = Array.prototype.slice.call(allImage, 0);
                                   var urls = new Array();
                                   var index = -1;
                                   var x = 0;
                                   var y = 0;
                                   var width = 0;
                                   var height = 0;
                                   //获取点击图片在所有图片中的编号以及在图片相对于webView左上角的位置、宽高，并把这些信息返回给OC
                                   allImage.forEach(function(image) {
                                                    var imgUrl = image.getAttribute("esrc");
                                                    var newLength = urls.push(imgUrl);
                                                    if(imgUrl == picUrl || imgUrl == decodeURIComponent(picUrl)){
                                                    index = newLength-1;
                                                    x = image.getBoundingClientRect().left;
                                                    y = image.getBoundingClientRect().top;
                                                    x = x + document.documentElement.scrollLeft;
                                                    y = y + document.documentElement.scrollTop;
                                                    width = image.width;
                                                    height = image.height;
                                                    console.log("x:"+x +";y:" + y+";width:"+image.width +";height:"+image.height);
                                                    }
                                                    });
                                   
                                   console.log("检测到点击"+"x="+x+"y="+y+"width="+width+"height="+height);
                                   //四种关系图表之第2种
                                   bridge.callHandler('imageDidClicked', {'index':index,'x':x,'y':y,'width':width,'height':height}, function(response) {
                                                      console.log("JS已经发出imgurl和index，同时收到回调，说明OC已经收到数据");
                                                      });
                                   });
    
}







function imagesDownloadComplete(pOldUrl, pNewUrl) {
    alert('我也不知道为什么这个函数不执行T_T');
    var allImage = document.querySelectorAll("img");
    allImage = Array.prototype.slice.call(allImage, 0);
    allImage.forEach(function(image) {
                     if (image.getAttribute("esrc") == pOldUrl || image.getAttribute("esrc") == decodeURIComponent(pOldUrl)) {
                     image.src = pNewUrl;
                     }
                     });
    console.log('$$$$');
}

