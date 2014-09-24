//
//  EMConnectLoginViewController.m
//  EdmodoTestMobile
//
//  Created by Luca Prasso on 12/16/13.
//  Copyright (c) 2013 Luca Prasso Edmodo. All rights reserved.
//

#import <CoreFoundation/CFURL.h>

#import "EMObjects.h"
#import "EMConnectDataStore.h"

#import "EMConnectLoginView.h"

@interface EMConnectLoginView ()

@end

@implementation EMConnectLoginView {
    UIWebView *_webView;
    NSString* _clientID;
    NSString* _redirectURI;
    NSArray* _scopes;
    BOOL _responsive;
    EMStringResultBlock_t _successHandler;
    EMVoidResultBlock_t _cancelHandler;
    EMNSErrorBlock_t _errorHandler;
}


static NSString* const EDMODO_CONNECT_LOGIN_BEGINNING = @"https://api.edmodo.com/oauth/authorize?nr=1&";
static NSString* const EDMODO_CONNECT_LOGIN_BEGINNING_RESPONSIVE = @"https://api.edmodo.com/oauth/authorize?";

- (id)initWithFrame:(CGRect)rect
       withClientID:(NSString*)clientID
    withRedirectURI:(NSString*)redirectURI
         withScopes:(NSArray*)scopes
          onSuccess:(EMStringResultBlock_t)successHandler
           onCancel:(EMVoidResultBlock_t)cancelHandler
            onError:(EMNSErrorBlock_t)errorHandler {
    return [self initWithFrame:rect
				  withClientID:clientID
			   withRedirectURI:redirectURI
					withScopes:scopes
					responsive:NO
					 onSuccess:successHandler
					  onCancel:cancelHandler
					   onError:errorHandler];
}
- (id)initWithFrame:(CGRect)rect
	   withClientID:(NSString*)clientID
	withRedirectURI:(NSString*)redirectURI
		 withScopes:(NSArray*)scopes
		 responsive:(BOOL)responsive
		  onSuccess:(EMStringResultBlock_t)successHandler
		   onCancel:(EMVoidResultBlock_t)cancelHandler
			onError:(EMNSErrorBlock_t)errorHandler {
	self = [super initWithFrame:rect];
	if (self) {
		[self __internalInitWithClientID:clientID
						 withRedirectURI:redirectURI
							  withScopes:scopes
							  responsive: responsive
							   onSuccess:successHandler
								onCancel:cancelHandler
								 onError:errorHandler];
	}
	return self;
}

- (void) __internalInitWithClientID:(NSString*)clientID
                    withRedirectURI:(NSString*)redirectURI
                         withScopes:(NSArray*)scopes
						 responsive:(BOOL)responsive
                          onSuccess:(EMStringResultBlock_t)successHandler
                           onCancel:(EMVoidResultBlock_t)cancelHandler
                            onError:(EMNSErrorBlock_t)errorHandler {
    _clientID = clientID;
    _redirectURI = redirectURI;
    _scopes = scopes;
	_responsive = responsive;
    _successHandler = successHandler;
    _cancelHandler = cancelHandler;
    _errorHandler = errorHandler;
    
    [self __createWidgets];
}

- (NSString *) __urlEscapeString:(NSString*)string
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                 NULL,
                                                                                 (__bridge CFStringRef) string,
                                                                                 NULL,
                                                                                 CFSTR("!*'();:@&=+$,/?%#[]\" "),
                                                                                 kCFStringEncodingUTF8));
}

- (NSString*) __createUrlParamsString:(NSDictionary*)params
{
    NSMutableString* str = [NSMutableString stringWithString:@""];
    
    BOOL first = YES;
    for (NSString *key in [params allKeys]) {
        NSString *escapedValue = [self __urlEscapeString:[params objectForKey:key]];
        if (!first) {
            [str appendString:@"&"];
        }
        first = NO;
        
        [str appendString:key];
        [str appendString:@"="];
        [str appendString:escapedValue];
    }
    return [NSString stringWithString:str];
}

- (void) __createWidgets
{
    self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue: 1.0 alpha: 0.8];
    
    // create UIWebview at some nice size, centered.
    // Caller can overload if they want.
    CGFloat x = (self.frame.size.width - EM_WebViewWidth)/2;
    // Scoot it up above center to make room for keyboard
    CGFloat y = (self.frame.size.height - EM_WebViewHeight)/5;
    
    CGRect wvFrame = CGRectMake(x, y, EM_WebViewWidth, EM_WebViewHeight);
    
    self.webView = [[UIWebView alloc]initWithFrame:wvFrame];
    self.webView.delegate = self;
    self.webView.scrollView.bounces = NO;
    self.webView.suppressesIncrementalRendering = YES;
    
    
    self.webView.layer.borderColor = [UIColor blackColor].CGColor;
    self.webView.layer.borderWidth = EM_WebViewBorderWidth;
    self.webView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7];
    
    
    // add webview to view stack
    [self addSubview:self.webView];
    
	UITapGestureRecognizer *tapRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(quitLogin:)];
	[tapRecognizer setNumberOfTapsRequired:1];
	[tapRecognizer setDelegate:self];
	[self addGestureRecognizer:tapRecognizer];
    
    
    NSString* scopesString = [_scopes componentsJoinedByString:@" "];
    
    NSMutableDictionary* params = [[NSMutableDictionary alloc] initWithObjects: @[
                                                                                  _clientID,
                                                                                  @"token",
                                                                                  scopesString,
                                                                                  _redirectURI,
                                                                                  ]
                                                                       forKeys: @[
                                                                                  @"client_id",
                                                                                  @"response_type",
                                                                                  @"scope",
                                                                                  @"redirect_uri",
                                                                                  ]];
	NSString* loginBeginning = _responsive ? EDMODO_CONNECT_LOGIN_BEGINNING_RESPONSIVE : EDMODO_CONNECT_LOGIN_BEGINNING;
    NSString* fullURL = [loginBeginning stringByAppendingString:[self __createUrlParamsString:params]];
    
    NSURL *url = [NSURL URLWithString:fullURL];
    
    NSURLRequest *requestURL = [NSURLRequest requestWithURL:url];
    
    // load webview
    [self.webView loadRequest:requestURL];
}

-(void) quitLogin:(id)sender
{
    _cancelHandler();
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

// function not used curently
// created to test cookies may be used later if login procedure changes
- (void) logCookies {
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [cookieJar cookies]) {
        NSLog(@" Cookie [%@]", [cookie name]);
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (webView.scrollView.contentSize.width > webView.frame.size.width) {
        CGFloat newContentOffsetX = (webView.scrollView.contentSize.width/2) - (webView.bounds.size.width/2);
        [webView.scrollView setContentOffset:CGPointMake(newContentOffsetX, 0)];
    }
    
    // Commented out for later in case we need to use cookies
    //[self logCookies];
    
    // extract data from webview URL
    NSString *fragment = [webView.request.URL fragment];
    // check if fragment contains access code
    if ([fragment length] && [fragment rangeOfString:@"access_token="].location != NSNotFound) {
        NSArray *fragmentComponents = [fragment componentsSeparatedByString:@"&"];
        
        // find access token component
        for (int i = 0; i < [fragmentComponents count]; i++) {
            NSString *component = [fragmentComponents objectAtIndex:i];
            if ([component rangeOfString:@"access_token="].location != NSNotFound) {
                NSString *accessToken = [component stringByReplacingOccurrencesOfString:@"access_token=" withString:@""];
                if ([accessToken length]) {
                    return _successHandler(accessToken);
				}
            }
        }
	} else if ([webView.request.URL.host isEqualToString: @"api.edmodo.com"] && [webView.request.URL.path hasPrefix: @"/oauth/authorize/"]) {
		// alternatively, it could be an out-of-band (oob) authorization
		NSString* accessToken = [webView.request.URL.path substringFromIndex: [@"/oauth/authorize/" length]];
		if ([accessToken length]) {
			return _successHandler(accessToken);
		}
	}

	_cancelHandler();
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
