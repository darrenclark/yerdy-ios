//
//  YRDUtil.m
//  Yerdy
//
//  Created by Darren Clark on 2014-02-03.
//  Copyright (c) 2014 Yerdy. All rights reserved.
//

#import "YRDUtil.h"
#import "YRDConstants.h"
#import "YRDDataStore.h"
#import "YRDLog.h"

#import <UIKit/UIKit.h>

#if ENABLE_IDFA
#import	<AdSupport/AdSupport.h>
#endif

#if !YRD_COMPILING_FOR_IOS_7

// -[NSData base64Encoding] has existed since iOS 4, but was only publicly
// introduced in iOS 7.  As per Apple docs, it is fine to use on iOS 4+.  See:
// https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSData_Class/DeprecationAppendix/AppendixADeprecatedAPI.html#//apple_ref/occ/instm/NSData/initWithBase64Encoding:

@interface NSData (PreventWarnings)
- (NSString *)base64Encoding;
@end

#endif


static NSString *BundleVersionKey = @"CFBundleVersion";
static NSString *BundleShortVersionKey = @"CFBundleShortVersionString";

static NSString *PlatformSuffix = @"iOS";

static NSString *URLCharactersToEscape = @"￼=,!$&'()*+;?\n\"<>#\t :/";


@implementation YRDUtil

+ (NSString *)deviceIdentifier
{
	// try for IDFV
	if ([UIDevice instancesRespondToSelector:@selector(identifierForVendor)]) {
		NSUUID *idfv = [UIDevice currentDevice].identifierForVendor;
		if (idfv)
			return idfv.UUIDString;
	}
	
	// fallback on custom ID
	NSString *customID = [[YRDDataStore sharedDataStore] stringForKey:YRDCustomDeviceIDDefaultsKey];
	if (!customID) {
		CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
		customID = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
		CFRelease(uuid);
		
		[[YRDDataStore sharedDataStore] setObject:customID forKey:YRDCustomDeviceIDDefaultsKey];
	}
	return customID;
}

+ (NSString *)testIdentifier
{
#if ENABLE_IDFA
	if ([ASIdentifierManager class]) {
		NSUUID *idfa = [ASIdentifierManager sharedManager].advertisingIdentifier;
		return idfa.UUIDString;
	}
#endif
	return nil;
}

+ (NSString *)appBundleIdentifierAndPlatform
{
	NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	return [NSString stringWithFormat:@"%@.%@", bundleIdentifier, PlatformSuffix];
}

+ (NSString *)appVersion
{
	NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
	
	// return the -description of the values in case someone accidentally uses
	// an NSNumber in the Info.plist
	if (infoDictionary[BundleShortVersionKey]) {
		return [infoDictionary[BundleShortVersionKey] description];
	} else if (infoDictionary[BundleVersionKey]) {
		return [infoDictionary[BundleVersionKey] description];
	} else {
		NSLog(@"[Yerdy] WARNING: No app version set in Info.plist.  ");
		NSLog(@"[Yerdy] Please add CFBundleVersion or CFBundleShortVersionString to your Info.plist!");
		
		return @"0.0.0";
	}
}

+ (NSString *)stripCharactersInSet:(NSCharacterSet *)charSet fromString:(NSString *)string
{
	if (string == nil) {
		return nil;
	}
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	NSMutableString *stripped = [NSMutableString stringWithCapacity:string.length];
	
	while (![scanner isAtEnd]) {
		NSString *result;
		if ([scanner scanUpToCharactersFromSet:charSet intoString:&result]) {
			[stripped appendString:result];
			[scanner scanCharactersFromSet:charSet intoString:NULL];
		}
	}
	
	return stripped;
}

+ (NSString *)base64String:(NSData *)data
{
	NSString *base64;
	
#if YRD_COMPILING_FOR_IOS_7
	if ([data respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
		// iOS 7+
		base64 = [data base64EncodedStringWithOptions:0];
	} else {
		// iOS 4-6
		base64 = [data base64Encoding];
	}
#else
	base64 = [data base64Encoding];
#endif
	
	return [self stripCharactersInSet:[NSCharacterSet newlineCharacterSet] fromString:base64];
}

+ (NSString *)URLEncode:(NSString *)string
{
	CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(
		kCFAllocatorDefault,
		(__bridge CFStringRef)string,
		NULL,
		(__bridge CFStringRef)URLCharactersToEscape,
		kCFStringEncodingUTF8);
	return CFBridgingRelease(escaped);
}

+ (UIColor *)colorFromHexString:(NSString *)hex
{
	if (!hex)
		return nil;
	
	int r, g, b;
	if (sscanf([hex UTF8String], "#%02x%02x%02x", &r, &g, &b) != 3)
		return nil;
	
	float fr = (float)r/(float)255;
	fr = MAX(0.0, MIN(fr, 1.0));
	
	float fg = (float)g/(float)255;
	fg = MAX(0.0, MIN(fg, 1.0));
	
	float fb = (float)b/(float)255;
	fb = MAX(0.0, MIN(fb, 1.0));
	
	return [UIColor colorWithRed:fr green:fg blue:fb alpha:1.0];
}

+ (NSString *)sanitizeParamKey:(NSString *)input context:(NSString *)context
{
	static NSRegularExpression *regex = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSError *error;
		regex = [[NSRegularExpression alloc] initWithPattern:@"[^a-zA-Z0-9._\\- ]" options:0 error:&error];
		if (!regex)
			YRDError(@"Failed to create regex: %@", error);
	});
	
	NSString *sanitized = [regex stringByReplacingMatchesInString:input
														  options:0
															range:NSMakeRange(0, input.length)
													 withTemplate:@""];
	if (context && [sanitized isEqualToString:input] == NO) {
		YRDWarn(@"%@ (\"%@\") has some invalid characters.  Using \"%@\" instead", context, input, sanitized);
	}
	return sanitized;
}

@end

NSString *YRDToString(id object)
{
	NSString *descrip = [object description];
	return descrip != nil ? descrip : @"";
}
