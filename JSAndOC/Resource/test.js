//添加子节点
function addNewNodeTest () {
    
    var para = document.createElement("p");
    var node = document.createTextNode("这是新段落。");
    para.appendChild(node);
    var element = document.getElementById("addNewNodeTest");
    element.appendChild(para);
    console.log("添加子节点成功");
}

//改变UILabel的文本
function changeUILabelText() {
    //"changelabeltext"是你自己定的一个协议。
    //注url不要含大写字母，就算是大写字母，在`webView:shouldStartLoadWithRequest:navigationType:`代理方法里也会被替换成小写字母
    var url = "changelabeltext:" + "我是改变后的文字";
    //给document.location重新赋值就相当于webView加载一个新的URL，所以又会调用`webView:shouldStartLoadWithRequest:navigationType:`方法，然后就可以在这个代理方法里截获这个重定向请求
    document.location = url;
}

//也可以自己封装个传参数的方法
function sendCommand(cmd,param){
    var url = "yourprotocol:" + cmd + ":" + param;
    document.location = url;
}
//打印测试
function logText(){
    sendCommand("log","Hi,I'm In logText Function");
}
