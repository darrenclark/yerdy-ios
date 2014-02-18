//
//  YRDMessagePresenter.m
//  Yerdy
//
//  Created by Darren Clark on 2014-02-11.
//  Copyright (c) 2014 Yerdy. All rights reserved.
//

#import "YRDMessagePresenter.h"
#import "Yerdy.h"
#import "YRDAppActionParser.h"
#import "YRDLog.h"
#import "YRDMessagePresenterImage.h"
#import "YRDMessagePresenterSystem.h"
#import "YRDMessage.h"
#import "YRDURLConnection.h"
#import "YRDWebViewController.h"

@implementation YRDMessagePresenter

+ (YRDMessagePresenter *)presenterForMessage:(YRDMessage *)message window:(UIWindow *)window
{
	if (message.style == YRDMessageStyleSystem)
		return [[YRDMessagePresenterSystem alloc] initWithMessage:message window:window];
	else if (message.style == YRDMessageStyleImage)
		return [[YRDMessagePresenterImage alloc] initWithMessage:message window:window];
	else
		return nil; // TODO: Support all message styles
}

- (id)initWithMessage:(YRDMessage *)message window:(UIWindow *)window
{
	self = [super init];
	if (!self)
		return nil;
	
	_message = message;
	_window = window;
	
	return self;
}

- (void)present
{
	[NSException raise:NSInternalInconsistencyException
				format:@"-[%@ %@] not implemented", [self class], NSStringFromSelector(_cmd)];
}

- (void)messageClicked
{
	if (_message.actionType == YRDMessageActionTypeExternalBrowser) {
		[[UIApplication sharedApplication] openURL:_message.clickURL];
	} else if (_message.actionType == YRDMessageActionTypeInternalBrowser) {
		YRDWebViewController *vc = [[YRDWebViewController alloc] initWithWindow:_window
																			URL:_message.clickURL];
		[vc present];
	} else {
		YRDAppActionParser *parser = [[YRDAppActionParser alloc] initWithAppAction:_message.action messagePresenter:self];
		if (parser != nil) {
			switch (parser.actionType) {
				case YRDAppActionTypeEmpty:
					[self reportOutcomeToURL:_message.clickURL];
					break;
					
				case YRDAppActionTypeInAppPurchase:
					[_delegate yerdy:_delegate handleInAppPurchase:parser.actionInfo];
					break;
					
				case YRDAppActionTypeItemPurchase:
					[_delegate yerdy:_delegate handleItemPurchase:parser.actionInfo];
					break;
					
				case YRDAppActionTypeReward:
					[_delegate yerdy:_delegate handleReward:parser.actionInfo];
					[self reportOutcomeToURL:_message.clickURL];
					break;
					
				default:
					break;
			}
		} else {
			YRDError(@"Failed to parse app action '%@', reporting view...", _message.action);
			[self reportOutcomeToURL:_message.viewURL];
		}
	}
}

- (void)messageCancelled
{
	[self reportOutcomeToURL:_message.viewURL];
}

- (void)reportAppActionSuccess
{
	[self reportOutcomeToURL:_message.clickURL];
}

- (void)reportAppActionFailure
{
	[self reportOutcomeToURL:_message.viewURL];
}

- (void)reportOutcomeToURL:(NSURL *)URL
{
	YRDRequest *request = [[YRDRequest alloc] initWithURL:URL];
	[YRDURLConnection sendRequest:request completionHandler:^(id response, NSError *error) {
		if (error)
			YRDError(@"Failed to report message outcome to '%@': %@", request.URL, error);
	}];
}

@end
