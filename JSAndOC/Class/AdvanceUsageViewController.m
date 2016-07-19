//
//  AdvanceUsageViewController.m
//  JSAndOC
//
//  Created by Damon Li on 15/11/26.
//  Copyright © 2015年 Panway. All rights reserved.
//

#import "AdvanceUsageViewController.h"
#import "WebViewJavascriptBridge.h"
#import "UIImageView+WebCache.h"
#import "HZPhotoBrowser.h"


@interface AdvanceUsageViewController ()<UIWebViewDelegate,HZPhotoBrowserDelegate>
{
    NSMutableArray *_allImagesOfThisArticle;
    NSArray *_imageURLs;
}
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property WebViewJavascriptBridge* bridge;

@end

@implementation AdvanceUsageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"article1" ofType:@"html"];
    //原网页html代码
    NSString *_content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    //--1--首先，我们要做的第一步是替换获取的HTML文本中默认的src，避免webView自动加载图片
    _content = [_content stringByReplacingOccurrencesOfString:@"src" withString:@"esrc"];
    //正则替换,给每个图片添加一个onImageClick点击方法
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<img[^>]+esrc=\")(\\S+)\"" options:0 error:nil];
    //终于得到我想要的html了!!!
    _content = [regex stringByReplacingMatchesInString:_content options:0 range:NSMakeRange(0, _content.length) withTemplate:@"<img esrc=\"$2\" onClick=\"javascript:onImageClick('$2')\""];
    [self.webView loadHTMLString:_content baseURL:nil];
    
    //插入js
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"imageCache" ofType:@"js"];
    NSString *jsString = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    
    //初始化一个WebViewJavascript桥梁，方便imageCache.js把数据传过来
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"###来自imageCache.js的图片URL数组: %@", data);
        //利用SDWebImageManager下载图片到本地
        [self downloadAllImagesInNative:data];
        _imageURLs = data;
        responseCallback(@"###Right back atcha");
    }];
    
    //这里注册一下，imageCache.js里的`bridge.callHandler('imageDidClicked', {'index':index,'x':x,'y':y,'width':width,'height':height}, function(response)`就会传数据过来
    [_bridge registerHandler:@"imageDidClicked" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSInteger index = [[data objectForKey:@"index"] integerValue];
        
        CGFloat originX = [[data objectForKey:@"x"] floatValue];
        CGFloat originY = [[data objectForKey:@"y"] floatValue];
        CGFloat width   = [[data objectForKey:@"width"] floatValue];
        CGFloat height  = [[data objectForKey:@"height"] floatValue];
        
        //启动图片浏览器
        HZPhotoBrowser *browserVc = [[HZPhotoBrowser alloc] init];
        // browserVc.sourceImagesContainerView = cell.webView; // 原图的父控件
        browserVc.imageCount = _allImagesOfThisArticle.count; // 图片总数
        browserVc.currentImageIndex = index;
        browserVc.delegate = self;
        browserVc.imageFrameinWebView = CGRectMake(originX, originY+64, width, height);
        [browserVc show];
        
        NSLog(@"OC已经收到JS的imageDidClicked了: %@", data);
        responseCallback(@"OC已经收到JS的imageDidClicked了");
    }];
    
    //四种关系图表之第3种（测试）
//    [_bridge send:@"###Message1：我将会被发送到imageCache.js里bridge.init()的回调里"];
    
    //四种关系图表之第3种（测试）
//    [_bridge send:@"###Message1：我将会被发送到imageCache.js里bridge.init()的回调里，imageCache.js还会给我回调,不信你可能下面的Log" responseCallback:^(id responseData) {
//        NSLog(@"###%@", responseData);
//    }];
}

#pragma mark -- 下载全部图片
-(void)downloadAllImagesInNative:(NSArray *)imageUrls{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    //初始化一个数组用于存image
    _allImagesOfThisArticle = [NSMutableArray arrayWithCapacity:imageUrls.count];
    for (NSUInteger i = 0; i < imageUrls.count; i++) {
        NSString *_url = imageUrls[i];
        [manager downloadImageWithURL:[NSURL URLWithString:_url] options:SDWebImageHighPriority progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            
            if (image) {
                [_allImagesOfThisArticle addObject:image];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *imgB64 = [UIImageJPEGRepresentation(image, 1.0) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                    //把图片在磁盘中的地址传回给JS
                    NSString *key = [manager cacheKeyForURL:imageURL];
                    
                    NSString *source = [NSString stringWithFormat:@"data:image/png;base64,%@", imgB64];
                    //四种关系图表之第4种
                    [_bridge callHandler:@"imagesDownloadComplete" data:@[key,source] responseCallback:^(id responseData) {
                        NSLog(@"js把img标签的esrc属性替换后-->%@<",responseData);
                    }];
                    
                });
                
            }
            
        }];
        
    }
    
}

#pragma mark - HZPhotoBrowser的代理方法
//这里没有占位小图，所以就让大图代替
- (UIImage *)photoBrowser:(HZPhotoBrowser *)browser placeholderImageForIndex:(NSInteger)index {
    return _allImagesOfThisArticle[index];
}

- (NSURL *)photoBrowser:(HZPhotoBrowser *)browser highQualityImageURLForIndex:(NSInteger)index {
    return [NSURL URLWithString:_imageURLs[index]];
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
