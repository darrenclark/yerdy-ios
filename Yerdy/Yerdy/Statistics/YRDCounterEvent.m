//
//  YRDCounterEvent.m
//  Yerdy
//
//  Created by Darren Clark on 2014-03-06.
//  Copyright (c) 2014 Yerdy. All rights reserved.
//

#import "YRDCounterEvent.h"
#import "YRDLog.h"
#import "YRDUtil.h"

@interface YRDCounterEvent ()
{
	NSMutableDictionary *_idx;
	NSMutableDictionary *_mod;
}
@end

@implementation YRDCounterEvent

@synthesize idx = _idx;
@synthesize mod = _mod;

- (id)initWithType:(YRDCounterType)type name:(NSString *)name value:(NSString *)value
{
	return [self initWithType:type name:name value:value increment:1];
}

- (id)initWithType:(YRDCounterType)type name:(NSString *)name value:(NSString *)value increment:(NSUInteger)increment
{
	self = [super init];
	if (!self)
		return nil;

	_type = type;
	
	name = [YRDUtil sanitizeParamKey:name context:@"Event name"];
	_name = [name copy];
	
	_idx = [@{ name : value } mutableCopy];
	_mod = [@{ name : @(increment) } mutableCopy];
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (!self)
		return nil;
	
	_type = [aDecoder decodeIntForKey:@"type"];
	_name = [aDecoder decodeObjectForKey:@"name"];
	
	_idx = [aDecoder decodeObjectForKey:@"idx"];
	_mod = [aDecoder decodeObjectForKey:@"mod"];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeInt:_type forKey:@"type"];
	if (_name) [aCoder encodeObject:_name forKey:@"name"];
	if (_idx) [aCoder encodeObject:_idx forKey:@"idx"];
	if (_mod) [aCoder encodeObject:_mod forKey:@"mod"];
}

- (id)copyWithZone:(NSZone *)zone
{
	YRDCounterEvent *copy = [[[self class] alloc] init];
	if (!copy)
		return nil;
	
	copy->_type = _type;
	copy->_name = _name;
	copy->_idx = [_idx mutableCopy];
	copy->_mod = [_mod mutableCopy];
	
	return self;
}

- (void)setValue:(NSString *)value forParameter:(NSString *)param
{
	[self setValue:value increment:1 forParameter:param];
}

- (void)setValue:(NSString *)value increment:(NSUInteger)increment forParameter:(NSString *)param
{
	param = [YRDUtil sanitizeParamKey:param context:@"Parameter name"];
	_idx[param] = value;
	_mod[param] = @(increment);
}

- (void)incrementParameter:(NSString *)param byAmount:(NSUInteger)increment
{
	param = [YRDUtil sanitizeParamKey:param context:@"Parameter name"];
	
	if (!_idx[param]) {
		YRDError(@"Attempting to increment non-existent parameter: %@", param);
		return;
	}
	_mod[param] = @([_mod[param] integerValue] + increment);
}

- (void)removeParameter:(NSString *)param
{
	param = [YRDUtil sanitizeParamKey:param context:@"Parameter name"];
	
	[_idx removeObjectForKey:param];
	[_mod removeObjectForKey:param];
}

- (NSArray *)parameterNames
{
	return _idx.allKeys;
}

- (NSString *)valueForParameter:(NSString *)param
{
	param = [YRDUtil sanitizeParamKey:param context:@"Parameter name"];
	return _idx[param];
}

- (NSUInteger)incrementForParameter:(NSString *)param
{
	param = [YRDUtil sanitizeParamKey:param context:@"Parameter name"];
	return [_mod[param] unsignedIntegerValue];
}

@end
