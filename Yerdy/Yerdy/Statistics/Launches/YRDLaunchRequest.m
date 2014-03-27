//
//  YRDLaunchRequest.m
//  Yerdy
//
//  Created by Darren Clark on 2014-02-13.
//  Copyright (c) 2014 Yerdy. All rights reserved.
//

#import "YRDLaunchRequest.h"
#import "YRDJSONResponseHandler.h"
#import "YRDLaunchResponse.h"
#import "YRDUtil.h"

#import <UIKit/UIKit.h>

#if ENABLE_IDFA
#import <AdSupport/AdSupport.h>
#endif


static NSString *Path = @"stats/launch.php";


@implementation YRDLaunchRequest

+ (instancetype)launchRequestWithToken:(NSData *)token
							  launches:(NSInteger)launches
							   crashes:(NSInteger)crashes
							  playtime:(NSTimeInterval)playtime
							  currency:(NSArray *)currency
						  screenVisits:(NSDictionary *)screenVisits
{
	NSDictionary *queryParameters = [self queryParametersForToken:token
														 launches:launches
														  crashes:crashes
														 playtime:playtime
														 currency:currency];
	
	NSMutableDictionary *bodyParameters = [NSMutableDictionary dictionary];
	
	[bodyParameters addEntriesFromDictionary:[self bodyParametersForAds]];
	if (screenVisits.count > 0) {
		[bodyParameters addEntriesFromDictionary:[self bodyParametersForScreenVisits:screenVisits]];
	}

	YRDLaunchRequest *request = [[self alloc] initWithPath:Path queryParameters:queryParameters bodyParameters:bodyParameters];
	request.responseHandler = [[YRDJSONResponseHandler alloc] initWithObjectType:[YRDLaunchResponse class] rootKey:@"@attributes"];
	return request;
}

+ (NSDictionary *)queryParametersForToken:(NSData *)token
								 launches:(NSInteger)launches
								  crashes:(NSInteger)crashes
								 playtime:(NSTimeInterval)playtime
								 currency:(NSArray *)currency
{
	// timezone string format: -700 for -7 hours, 300 for +3 hours, etc...
	NSTimeZone *timezone = [NSTimeZone localTimeZone];
	NSString *timezoneString = [NSString stringWithFormat:@"%04.0ld", (long)[timezone secondsFromGMT] / 36];
	
	UIDevice *device = [UIDevice currentDevice];
	NSString *os = [NSString stringWithFormat:@"%@ %@", device.systemName, device.systemVersion];
	
	NSLocale *locale = [NSLocale currentLocale];
	NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
	NSString *languageCode = [locale objectForKey:NSLocaleLanguageCode];
	
	NSString *currencyString = [currency componentsJoinedByString:@";"];
	
	return @{
		@"api" : @2,
		@"token" : YRDToString([YRDUtil base64String:token]),
		@"token_type" : @"apn",
		@"timezone" : YRDToString(timezoneString),
		@"type" : YRDToString(device.model),
		@"os" : YRDToString(os),
		@"country" : YRDToString(countryCode),
		@"language" : YRDToString(languageCode),
		@"launches" : @(launches),
		@"crashes" : @(crashes),
		@"playtime" : @((int)round(playtime)),
		@"currency" : currencyString,
	};
}

+ (NSDictionary *)bodyParametersForScreenVisits:(NSDictionary *)screenVisits
{
	NSMutableDictionary *bodyParameters = [NSMutableDictionary dictionary];
	for (NSString *screenName in screenVisits) {
		NSString *sanitizedName = [[screenName stringByReplacingOccurrencesOfString:@"[" withString:@" "]
								   stringByReplacingOccurrencesOfString:@"]" withString:@" "];
		
		NSString *paramName = [NSString stringWithFormat:@"nav[%@]", sanitizedName];
		bodyParameters[paramName] = screenVisits[screenName];
	}
	return bodyParameters;
}

+ (NSDictionary *)bodyParametersForAds
{
#if ENABLE_IDFA
	if ([ASIdentifierManager class]) {
		NSUUID *idfa = [ASIdentifierManager sharedManager].advertisingIdentifier;
		BOOL trackAds = [ASIdentifierManager sharedManager].isAdvertisingTrackingEnabled;
		
		if (idfa) {
			return @{
				@"ad_aid" : [idfa UUIDString],
				@"ad_track" : @(trackAds)
			};
		}
	}
#endif
	
	return @{};
}

@end
