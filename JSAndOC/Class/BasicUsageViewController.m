//
//  BasicUsageViewController.m
//  JSAndOC
//
//  Created by Damon Li on 15/11/26.
//  Copyright © 2015年 Panway. All rights reserved.
//

#import "BasicUsageViewController.h"

@interface BasicUsageViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *testLabel;

@end

@implementation BasicUsageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString* path = [[NSBundle mainBundle] pathForResource:@"web1" ofType:@"html"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"js"];
    NSString *jsString = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
}


#pragma mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // 获取HTML页面title元素，赋值给self.title
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"开始加载请求");
    //当点击按钮时，navigationType = UIWebViewNavigationTypeOther
    NSString *requestString = request.URL.absoluteString;
    NSArray *components = [requestString componentsSeparatedByString:@":"];
    if ([components[0] isEqualToString:@"changelabeltext"] && components.count > 1) {
        //这种通过URL传参数的方式貌似不是太好，因为参数如果含中文还得URL解码，eg:
        self.testLabel.text = [components[1] stringByRemovingPercentEncoding];
        return NO;
    }
    //也可以这样判断
    else if([request.URL.scheme isEqualToString:@"yourprotocol"]) {
        NSLog(@"%@",[components[2] stringByRemovingPercentEncoding]);
        return NO;
    }
    return YES;
}


- (IBAction)insertJavaScript1:(UIButton *)sender {
    //方法1：预加载的test.js内部已经写了addNewNodeTest()方法，这里只需注入"addNewNodeTest()"字符串即可
    [self.webView stringByEvaluatingJavaScriptFromString:@"addNewNodeTest()"];
}

- (IBAction)insertJavaScript2:(UIButton *)sender {
    //方法2：把test.js内部的addNewNodeTest()方法复制过来，去掉行与行之间的空格，字符串的双引号前要加转义符"\",或者把双引号变成单引号，例如：
    NSString *addNewNode = @"var para = document.createElement(\"p\");var node=document.createTextNode('这是新段落。');para.appendChild(node);var element=document.getElementById('addNewNodeTest');element.appendChild(para);";
    [self.webView stringByEvaluatingJavaScriptFromString:addNewNode];
}

- (IBAction)insertJavaScript3:(UIButton *)sender {
    //方法3：把test.js内部的addNewNodeTest()方法复制过来，并在每一行首尾加上双引号（跟方法2差不多）
    NSString *addNewNode =
    @"var para = document.createElement('p');"
    "var node = document.createTextNode('这是新段落。');"
    "para.appendChild(node);"
    "var element = document.getElementById('addNewNodeTest');"
    "element.appendChild(para);";
    [self.webView stringByEvaluatingJavaScriptFromString:addNewNode];
}




- (IBAction)submitForm:(id)sender {
    NSLog(@"提交表单:执行了打开百度首页、输入“潘多拉”、搜索操作");
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];
    //因为网页加载完(finishLoad)才能提交表单，这里延迟2秒假设加载完
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.webView stringByEvaluatingJavaScriptFromString:@"var script = document.createElement('script');"
         "script.type = 'text/javascript';"
         "script.text = \"function myFunction() { "
         "var field = document.getElementsByName('word')[0];"
         "field.value='潘多拉';"
         "document.forms[0].submit();"
         "}\";"
         "document.getElementsByTagName('head')[0].appendChild(script);"];
        
        [self.webView stringByEvaluatingJavaScriptFromString:@"myFunction();"];
        
    });
    
}

- (IBAction)resizeImages:(UIButton *)sender {
    [self.webView stringByEvaluatingJavaScriptFromString:
     @"var script = document.createElement('script');"
     "script.type = 'text/javascript';"
     "script.text = \"function ResizeImages() { "
     "var myimg,oldwidth;"
     "var maxwidth=380;" //缩放系数
     "for(i=0;i <document.images.length;i++){"
     "myimg = document.images[i];"
     "if(myimg.width > maxwidth){"
     "oldwidth = myimg.width;"
     "myimg.width = maxwidth;"
     "myimg.height = myimg.height * (maxwidth/oldwidth);"
     "}"
     "}"
     "}\";"
     "document.getElementsByTagName('head')[0].appendChild(script);"];
    [self.webView stringByEvaluatingJavaScriptFromString:@"ResizeImages();"];
}

- (IBAction)changeLabelText:(UIButton *)sender {
    
}





- (IBAction)showJSAlert:(UIButton *)sender {
    [self.webView stringByEvaluatingJavaScriptFromString:@"showAlert();"];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
