//
//  CJViewController.m
//  twitterSignInTest
//
//  Created by JI on 15/12/31.
//  Copyright © 2015年 JI. All rights reserved.
//

#import "CJViewController.h"
#import "OAuthConsumer.h"


NSString *client_id = @"U7ne4TpV42fscArpbAqHW8Eqo";                         /**< Consumer Key (API Key)*/
NSString *secret = @"ZhZxY9TZK3sR6C6tTv4TsSBMIGNvsDlEjY72ksAQ1Mwl2CLpL4";   /**< Consumer Secret (API Secret)*/
NSString *callback = @"http://codegerms.com/callback";                      /**< Callback URL*/

@interface CJViewController ()<UIWebViewDelegate>{
    OAConsumer *consumer;
    OAToken *requestToken;
    OAToken *accessToken;
}
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation CJViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    consumer = [[OAConsumer alloc] initWithKey:client_id secret:secret];
    NSURL *requestTokenUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
    OAMutableURLRequest *requestTokenRequest = [[OAMutableURLRequest alloc] initWithURL:requestTokenUrl
                                                                               consumer:consumer
                                                                                  token:nil
                                                                                  realm:nil signatureProvider:nil];
    
    //获取requestToken
    OARequestParameter *callbackParam = [[OARequestParameter alloc] initWithName:@"oauth_callback" value:callback];
    [requestTokenRequest setHTTPMethod:@"POST"];
    [requestTokenRequest setParameters:[NSArray arrayWithObject:callbackParam]];
    
    OADataFetcher *dataFetcher = [[OADataFetcher alloc] init];
    [dataFetcher fetchDataWithRequest:requestTokenRequest
                             delegate:self
                    didFinishSelector:@selector(didReceiveRequestToken:data:)
                      didFailSelector:@selector(didFailOAuth:error:)];
}

#pragma mark - webView代理

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *temp = [NSString stringWithFormat:@"%@",request];
    NSRange textRange = [[temp lowercaseString] rangeOfString:[callback lowercaseString]];
    
    if(textRange.location != NSNotFound){
        
        // Extract oauth_verifier from URL query
        NSString* verifier = nil;
        NSArray* urlParams = [[[request URL] query] componentsSeparatedByString:@"&"];
        for (NSString* param in urlParams) {
            NSArray* keyValue = [param componentsSeparatedByString:@"="];
            NSString* key = [keyValue objectAtIndex:0];
            if ([key isEqualToString:@"oauth_verifier"]) {
                verifier = [keyValue objectAtIndex:1];
                break;
            }
        }
        
        if (verifier) {
            NSURL* accessTokenUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
            OAMutableURLRequest* accessTokenRequest = [[OAMutableURLRequest alloc] initWithURL:accessTokenUrl consumer:consumer token:requestToken realm:nil signatureProvider:nil];
            OARequestParameter* verifierParam = [[OARequestParameter alloc] initWithName:@"oauth_verifier" value:verifier];
            [accessTokenRequest setHTTPMethod:@"POST"];
            [accessTokenRequest setParameters:[NSArray arrayWithObject:verifierParam]];
            OADataFetcher* dataFetcher = [[OADataFetcher alloc] init];
            [dataFetcher fetchDataWithRequest:accessTokenRequest
                                     delegate:self
                            didFinishSelector:@selector(didReceiveAccessToken:data:)
                              didFailSelector:@selector(didFailOAuth:error:)];
        } else {
            // ERROR!
        }
        
        [webView removeFromSuperview];
        
        return NO;
    }
    
    return YES;
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    // ERROR!
}
- (void)webViewDidFinishLoad:(UIWebView *)webView{
}

#pragma mark - 回调函数
/**
 *  成功接收到requestToken,然后根据requestToken请求accessToken
 */
- (void)didReceiveRequestToken:(OAMutableURLRequest *)ticket data:(NSData *)data {
    NSString* httpBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    requestToken = [[OAToken alloc] initWithHTTPResponseBody:httpBody];
    
    NSURL* authorizeUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/authorize"];
    OAMutableURLRequest* authorizeRequest = [[OAMutableURLRequest alloc] initWithURL:authorizeUrl
                                                                            consumer:nil
                                                                               token:nil
                                                                               realm:nil
                                                                   signatureProvider:nil];
    NSString* oauthToken = requestToken.key;
    OARequestParameter* oauthTokenParam = [[OARequestParameter alloc] initWithName:@"oauth_token" value:oauthToken];
    [authorizeRequest setParameters:[NSArray arrayWithObject:oauthTokenParam]];
    
    [self.webView loadRequest:authorizeRequest];
}

/**
 *  成功接收到accessToken,然后根据accessToken请求用户数据
 */
- (void)didReceiveAccessToken:(OAServiceTicket*)ticket data:(NSData*)data {
    NSString* httpBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    accessToken = [[OAToken alloc] initWithHTTPResponseBody:httpBody];
    
    [self getUserInfoViaToken:accessToken];
}

/**
 *  上面函数用到的
 */
- (void)getUserInfoViaToken:(OAToken *)token {
    
    if (token) {
        NSURL *userDataRequest = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/verify_credentials.json"];
        OAMutableURLRequest *requestTokenRequest = [[OAMutableURLRequest alloc] initWithURL:userDataRequest
                                                                                   consumer:consumer
                                                                                      token:token
                                                                                      realm:nil
                                                                          signatureProvider:nil];
        [requestTokenRequest setHTTPMethod:@"GET"];
        OADataFetcher *fetchUserInfo = [[OADataFetcher alloc] init];
        [fetchUserInfo fetchDataWithRequest:requestTokenRequest delegate:self didFinishSelector:@selector(didReceiveuserdata:data:) didFailSelector:@selector(didFailOAuth:error:)];
    }
}

/**
 *  成功接收用户信息
 */
- (void)didReceiveuserdata:(OAServiceTicket*)ticket data:(NSData*)data {
    NSString* httpBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSData *userData = [httpBody dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:userData options:0 error:nil];
#warning 你要的数据
    NSLog(@"%@",json);
}

/**
 *  获取token或信息失败
 */
- (void)didFailOAuth:(OAServiceTicket *)ticket error:(NSError *)error {
    
}

@end
