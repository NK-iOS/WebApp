//
//  NKWEBViewController.m
//  Amusement
//
//  Created by 聂宽 on 2018/7/11.
//  Copyright © 2018年 聂宽. All rights reserved.
//

#import "NKWEBViewController.h"
#import <WebKit/WebKit.h>
#import "SVProgressHUD.h"
#import "Reachability.h"
#import <CommonCrypto/CommonDigest.h>

@interface NKWEBViewController ()<UIWebViewDelegate>

@property (nonatomic) Reachability *hostReaty;//域名检查
@property (nonatomic) Reachability *internetReach;//网络检查

@property (assign, nonatomic) BOOL isFinish;//是否加载完成
@property (assign, nonatomic) BOOL isLandscape;//是否横屏

@property (weak, nonatomic) IBOutlet UIWebView *webView;//主体网页
@property (retain, nonatomic) IBOutlet UIView *noNetView;//无网络提示 视图

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heeetMarggg;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *artHeiab;
@property (weak, nonatomic) IBOutlet UIView *tombotView;

@end

@implementation NKWEBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    
    if (@available(iOS 11.0, *)) {
        
        if (statusBarFrame.size.height > 20) {
            self.heeetMarggg.constant = 44;
            self.artHeiab.constant = 89;
        }
        //        _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlehubytAction:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.webURL]]];
    [self.view addSubview:self.webView];
    self.webView.scalesPageToFit = YES;
    
    self.noNetView.hidden = YES;
    [self.view addSubview:self.noNetView];
    
    [self listenCurrentNetWorkingStatus]; //监听网络是否可用
}

/**清除缓存和cookie*/
- (void)cleanCacheAndCookie{
    //清除cookies
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies]){
        [storage deleteCookie:cookie];
    }
    //清除UIWebView的缓存
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURLCache * cache = [NSURLCache sharedURLCache];
    [cache removeAllCachedResponses];
    [cache setDiskCapacity:0];
    [cache setMemoryCapacity:0];

    if ([[[UIDevice currentDevice]systemVersion]intValue ] >8) {

        NSArray * types =@[WKWebsiteDataTypeMemoryCache,WKWebsiteDataTypeDiskCache]; // 9.0之后才有的
        NSSet *websiteDataTypes = [NSSet setWithArray:types];
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{

        }];

    }else{

        NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES) objectAtIndex:0];
        NSString *cookiesFolderPath = [libraryPath stringByAppendingString:@"/Cookies"];

        NSLog(@"%@", cookiesFolderPath);
        NSError *errors;
        [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&errors];
    }
}

//更新 UI 布局
-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
}



#pragma mark - ------ 网页代理方法 ------

//是否允许加载网页
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    return YES;
}

// 网页开始加载时调用
- (void)webViewDidStartLoad:(UIWebView *)webView{
    //    self.activityIndicatorView.hidden = NO;
    [SVProgressHUD showWithStatus:@"正在加载"];
    self.isFinish = NO;
    
    //是否 跳转到 别的 应用
    [self openOtherAppWithUIWebView:webView];
}

//只管 固定的几个 跳转
-(void)openSomeTheAppWithUIWebView:(UIWebView *)webView{
    
    
    if ([webView.request.URL.absoluteString hasPrefix:@"https://itunes.apple.com"]//Appstore
        ||[webView.request.URL.absoluteString hasPrefix:@"itms-services://"]//iOS 网页安装协议
        ||[webView.request.URL.absoluteString hasPrefix:@"weixin://"]//微信跳转
        ||[webView.request.URL.absoluteString hasPrefix:@"mqq://"])//QQ跳转
    {
        [[UIApplication sharedApplication] openURL:webView.request.URL];
    }
}


//是否 跳转到 别的 应用
-(void)openOtherAppWithUIWebView:(UIWebView *)webView{
    if ([webView.request.URL.absoluteString hasPrefix:@"https://itunes.apple.com"]//Appstore
        ||[webView.request.URL.absoluteString hasPrefix:@"itms-services://"])//iOS 网页安装协议
    {
        [[UIApplication sharedApplication] openURL:webView.request.URL];
    }else{
        //如果不是 http 链接，判断 是否 可以进行 白名单跳转
        if (![webView.request.URL.absoluteString hasPrefix:@"http"]) {
            //获取 添加的 白名单
            NSArray *whitelist = [[[NSBundle mainBundle] infoDictionary] objectForKey : @"LSApplicationQueriesSchemes"];
            //遍历 查询 白名单
            for (NSString * whiteName in whitelist) {
                //白名单 跳转 规则
                NSString *rulesString = [NSString stringWithFormat:@"%@://",whiteName];
                //判断 链接前缀 是否在 白名单 范围内
                if ([webView.request.URL.absoluteString hasPrefix:rulesString]){
                    [[UIApplication sharedApplication] openURL:webView.request.URL];
                }
            }
        }
    }
}

// 网页加载完成之后调用
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    //    self.activityIndicatorView.hidden = YES;
    //    self.noNetView.hidden = YES;
    
    [SVProgressHUD dismiss];
    self.isFinish = YES;
    
    //    NSString *meta = [NSString stringWithFormat:@"document.getElementsByName(\"viewport\")[0].content = \"width=%f, initial-scale=1.0, minimum-scale=1.0, maximum-scale=3.0, user-scalable=no\"", webView.frame.size.width];
    //    [webView stringByEvaluatingJavaScriptFromString:meta];
}

// 网页加载失败时调用
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    if (!self.noNetView.hidden) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:@"加载失败..."];
    }
}

#pragma mark - ------ 底部 导航栏 ------

//底部 导航栏 按钮 点击事件
- (IBAction)goingBT:(UIButton *)sender {
    if (sender.tag ==200) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.webURL]]];
    }else if (sender.tag ==201) {
        if ([self.webView canGoBack]) {[self.webView goBack]; }
    }else if (sender.tag ==202) {
        if ([self.webView canGoForward]) {[self.webView goForward];}
    }else if (sender.tag ==203) {
        [self.webView reload];
    }else if (sender.tag ==204) {
        NSLog(@"清除缓存，退出程序");
        [self cleanCacheAndCookie];
        exit(0);
    }
}


#pragma mark - ------ 网络监听 ------

//无网络 重试 按钮 点击事件
- (IBAction)againBTAction:(UIButton *)sender {
    //    self.activityIndicatorView.hidden = NO;
    [SVProgressHUD showWithStatus:@"正在加载"];
    self.noNetView.hidden = YES;
    self.isFinish = NO;
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.webURL]]];
    //    [self performSelector:@selector(checkNetwork) withObject:nil afterDelay:3];
    [self checkCurrentNetwork];
}

//检查网络
-(void)checkCurrentNetwork{
    self.hostReaty = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    [self.hostReaty startNotifier];
    [self updateInterfaceCurrentWithReachability:self.hostReaty];
}


//监听 网络状态
-(void)listenCurrentNetWorkingStatus{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netWorkChanged:) name:kReachabilityChangedNotification object:nil];
    // 设置网络检测的站点
    NSString *remoteHostName = @"www.apple.com";
    
    self.hostReaty = [Reachability reachabilityWithHostName:remoteHostName];
    [self.hostReaty startNotifier];
    [self updateInterfaceCurrentWithReachability:self.hostReaty];
    
    self.internetReach = [Reachability reachabilityForInternetConnection];
    [self.internetReach startNotifier];
    [self updateInterfaceCurrentWithReachability:self.internetReach];
}

//网络状态 通知事件
- (void) netWorkChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    [self updateInterfaceCurrentWithReachability:curReach];
}

//当前网络类型
- (void)updateInterfaceCurrentWithReachability:(Reachability *)reachability
{
    
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    switch (netStatus) {
        case 0://无网络
            //网页加载完成，突然断网，不显示 无网络提醒视图
            if (!self.isFinish) {
                self.noNetView.hidden = NO;
                [SVProgressHUD dismiss];
            }
            break;
            
        case 1://WIFI
            NSLog(@"ReachableViaWiFi----WIFI");
            break;
            
        case 2://蜂窝网络
            NSLog(@"ReachableViaWWAN----蜂窝网络");
            break;
            
        default:
            break;
    }
    
}

#pragma mark - ------ 横竖屏相关 ------

//支持旋转
-(BOOL)shouldAutorotate{
    return YES;
}

//支持的方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

//监听屏幕 横竖屏
- (void)handlehubytAction:(NSNotification *)notification {
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait
        || [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) {
        self.tombotView.hidden = NO;
        self.webView.frame = self.webView.frame;
        self.isLandscape = NO;
    } else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft
               || [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        self.tombotView.hidden = YES;
        self.webView.frame = self.view.bounds;
        self.isLandscape = YES;
    }
}


-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
//    [self.webView stopLoading];
}

@end
