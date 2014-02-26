//
//  YRDCurrencyTracker.m
//  Yerdy
//
//  Created by Darren Clark on 2014-02-25.
//  Copyright (c) 2014 Yerdy. All rights reserved.
//

#import "YRDCurrencyTracker.h"
#import "YRDLog.h"

static const NSUInteger MAX_CURRENCIES = 6;


@interface YRDCurrencyTracker ()
{
	NSString __strong *_currencies[MAX_CURRENCIES];
	
	NSInteger _earned[MAX_CURRENCIES];
	NSInteger _spent[MAX_CURRENCIES];
	NSInteger _purchased[MAX_CURRENCIES];
}
@end


@implementation YRDCurrencyTracker

#pragma mark - Currency setup

- (void)registerCurrencies:(NSDictionary *)currencies
{
	for (NSUInteger i = 0; i < MAX_CURRENCIES; i++)
		_currencies[i] = nil;
	
	for (id key in currencies) {
		int index = [key intValue];
		if (index < 0 || index >= MAX_CURRENCIES) {
			YRDError(@"%@ outside range of possible currencies (0..%ld).  Ignoring.", key, (unsigned long)MAX_CURRENCIES);
			continue;
		}
		
		_currencies[index] = currencies[key];
	}
}

- (NSUInteger)indexForCurrency:(NSString *)string
{
	for (NSUInteger i = 0; i < MAX_CURRENCIES; i++)
		if ([string isEqualToString:_currencies[i]])
			return i;
	return NSNotFound;
}

#pragma mark - Type conversion

- (NSArray *)arrayFromCArray:(NSInteger[MAX_CURRENCIES])cArray
{
	id objects[MAX_CURRENCIES];
	for (NSUInteger i = 0; i < MAX_CURRENCIES; i++)
		objects[i] = @(cArray[i]);
	return [NSArray arrayWithObjects:objects count:MAX_CURRENCIES];
}

- (void)array:(NSArray *)array toCArray:(NSInteger[MAX_CURRENCIES])cArray
{
	NSUInteger count = MAX(array.count, MAX_CURRENCIES);
	for (NSUInteger i = 0; i < count; i++)
		cArray[i] = [array[i] integerValue];
}

#pragma mark - Reading currency amounts

- (NSArray *)currencyBalance
{
	NSInteger computed[MAX_CURRENCIES];
	
	for (NSUInteger i = 0; i < MAX_CURRENCIES; i++)
		computed[i] = _earned[i] + _purchased[i] - _spent[i];
	
	return [self arrayFromCArray:computed];
}

- (NSArray *)currencyEarned
{
	return [self arrayFromCArray:_earned];
}

- (NSArray *)currencySpent
{
	return [self arrayFromCArray:_spent];
}

- (NSArray *)currencyPurchased
{
	return [self arrayFromCArray:_purchased];
}

#pragma mark - Updating currency

- (void)addCurrencies:(NSDictionary *)currencies toCArray:(NSInteger[MAX_CURRENCIES])cArray
{
	for (NSString *currencyName in currencies) {
		NSInteger value = [currencies[currencyName] integerValue];
		
		NSUInteger index = [self indexForCurrency:currencyName];
		if (index == NSNotFound) {
			YRDError(@"Currency named '%@' not registered. Ignoring!", currencyName);
			continue;
		}
		
		cArray[index] += value;
	}
}

- (void)earnedCurrency:(NSString *)currency amount:(NSUInteger)amount
{
	if (currency == nil) {
		YRDError(@"'currency' is nil. Ignoring!");
		return;
	}
	
	NSDictionary *currencies = @{ currency : @(amount) };
	[self earnedCurrencies:currencies];
}

- (void)earnedCurrencies:(NSDictionary *)currencies
{
	[self addCurrencies:currencies toCArray:_earned];
}

- (void)spentCurrency:(NSString *)currency amount:(NSUInteger)amount
{
	if (currency == nil) {
		YRDError(@"'currency' is nil. Ignoring!");
		return;
	}
	
	NSDictionary *currencies = @{ currency : @(amount) };
	[self spentCurrencies:currencies];
}

- (void)spentCurrencies:(NSDictionary *)currencies
{
	[self addCurrencies:currencies toCArray:_spent];
}

- (void)purchasedCurrency:(NSString *)currency amount:(NSUInteger)amount
{
	if (currency == nil) {
		YRDError(@"'currency' is nil. Ignoring!");
		return;
	}
	
	NSDictionary *currencies = @{ currency : @(amount) };
	[self purchasedCurrencies:currencies];
}

- (void)purchasedCurrencies:(NSDictionary *)currencies
{
	[self addCurrencies:currencies toCArray:_purchased];
}

@end