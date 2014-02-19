//
//  YRDMessageView.m
//  Yerdy
//
//  Created by Darren Clark on 2014-02-18.
//  Copyright (c) 2014 Yerdy. All rights reserved.
//

#import "YRDMessageView.h"
#import "YRDMessageViewController.h"
#import "YRDMessage.h"
#import "YRDFontSizing.h"

typedef enum YRDButtonType {
	YRDButtonTypeCancel,
	YRDButtonTypeConfirm,
} YRDButtonType;


@interface YRDMessageView ()
{
	UIView *_contentContainer;
	
	UIImageView *_imageView;
	
	UILabel *_titleLabel;
	UILabel *_messageLabel;
	UILabel *_expiryLabel;
	
	NSArray *_buttons;
}
@end


@implementation YRDMessageView

- (id)initWithViewController:(YRDMessageViewController *)viewController message:(YRDMessage *)message
{
    self = [super initWithFrame:CGRectZero];
    if (!self)
		return nil;
	
	self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
	[self loadSubviewsForViewController:viewController message:message];
	
    return self;
}

#pragma mark - View Creation & Layout

- (void)loadSubviewsForViewController:(YRDMessageViewController *)viewController message:(YRDMessage *)message
{
	_contentContainer = [[UIView alloc] init];
	_contentContainer.backgroundColor = [self containerBackgroundColor];
	_contentContainer.opaque = YES;
	[self addSubview:_contentContainer];
	
	_titleLabel = [[UILabel alloc] init];
	_titleLabel.text = message.messageTitle;
	_titleLabel.font = [UIFont boldSystemFontOfSize:16.0 * [self deviceScaleFactor]];
	_titleLabel.backgroundColor = [self containerBackgroundColor];
	_titleLabel.textColor = [self textColor];
	[_contentContainer addSubview:_titleLabel];
	
	_messageLabel = [[UILabel alloc] init];
	_messageLabel.text = message.messageText;
	_messageLabel.font = [UIFont systemFontOfSize:14.0 * [self deviceScaleFactor]];
	_messageLabel.backgroundColor = [self containerBackgroundColor];
	_messageLabel.textColor = [self textColor];
	_messageLabel.numberOfLines = 0;
	[_contentContainer addSubview:_messageLabel];
	
	_expiryLabel = [[UILabel alloc] init];
	_expiryLabel.font = [UIFont boldSystemFontOfSize:16.0 * [self deviceScaleFactor]];
	_expiryLabel.text = @"Only X days left"; // TODO: pull expiry date from message
	_expiryLabel.backgroundColor = [self containerBackgroundColor];
	_expiryLabel.textColor = [self expiryTextColor];
	_expiryLabel.textAlignment = UITextAlignmentCenter;
	[_contentContainer addSubview:_expiryLabel];
	
	_imageView = [[UIImageView alloc] init];
	_imageView.backgroundColor = [UIColor greenColor];// [self containerBackgroundColor];
	[_contentContainer addSubview:_imageView];
	// TODO: Load image via network
	
	NSMutableArray *buttons = [NSMutableArray array];
	if (message.confirmLabel.length > 0 && message.cancelLabel.length > 0) {
		UIButton *cancel = [self makeButtonOfType:YRDButtonTypeCancel];
		[cancel setTitle:message.cancelLabel forState:UIControlStateNormal];
		[cancel addTarget:viewController action:@selector(cancelTapped:) forControlEvents:UIControlEventTouchUpInside];
		[buttons addObject:cancel];
		
		UIButton *confirm = [self makeButtonOfType:YRDButtonTypeConfirm];
		[confirm setTitle:message.confirmLabel forState:UIControlStateNormal];
		[confirm addTarget:viewController action:@selector(confirmTapped:) forControlEvents:UIControlEventTouchUpInside];
		[buttons addObject:confirm];
	} else {
		BOOL isConfirm = message.confirmLabel.length > 0;
		// if we have a single button, always make it look like a confirm button,
		// even though it may be wired up to be a "cancel"/"view"
		UIButton *button = [self makeButtonOfType:YRDButtonTypeConfirm];
		
		NSString *title = isConfirm ? message.confirmLabel : message.cancelLabel;
		[button setTitle:title forState:UIControlStateNormal];
		
		SEL tappedSelector = isConfirm ? @selector(confirmTapped:) : @selector(cancelTapped:);
		[button addTarget:viewController action:tappedSelector forControlEvents:UIControlEventTouchUpInside];
		
		[buttons addObject:button];
	}
	for (UIButton *button in buttons)
		[_contentContainer addSubview:button];
	_buttons = buttons;
}

- (void)layoutSubviews
{
	CGRect bounds = self.bounds;
	if (bounds.size.height > bounds.size.width) {
		[self layoutPortrait];
	} else {
		[self layoutLandscape];
	}
}

- (void)layoutPortrait
{
	CGRect bounds = self.bounds;
	CGRect containerBounds = CGRectMake(0.0, 0.0, [self shortDimension], [self longDimension]);
	
	_contentContainer.bounds = containerBounds;
	_contentContainer.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
	
	CGFloat currentY = 0.0;
	
	_imageView.frame = CGRectMake(0.0, 0.0, [self shortDimension], [self shortDimension]);
	currentY = CGRectGetMaxY(_imageView.frame);
	currentY += [self padding];
	
	CGSize size = [_titleLabel.text sizeWithFont:_titleLabel.font];
	_titleLabel.frame = CGRectMake([self padding], currentY,
								   containerBounds.size.width - [self padding] * 2.0,
								   size.height);
	currentY = CGRectGetMaxY(_titleLabel.frame);
	currentY += [self padding];
	
	CGFloat buttonY = containerBounds.size.height - [self buttonHeight] - [self padding] * 0.5;
	
	// Y value before buttons at bottom - currentY
	CGFloat bodyMaxHeight = (buttonY - [self padding]) - currentY;
	CGSize bodyMaxSize = CGSizeMake([self shortDimension] - [self padding] * 2.0, bodyMaxHeight);
	CGSize bodySize =[YRDFontSizing sizeForString:_messageLabel.text font:_messageLabel.font
										  maxSize:bodyMaxSize lineBreakMode:NSLineBreakByWordWrapping];
	_messageLabel.frame = CGRectMake([self padding], currentY, bodySize.width, bodySize.height);
	
	CGRect buttonsRect = CGRectMake(0.0, buttonY, containerBounds.size.width, [self buttonHeight]);
	[self layoutButtonsInRect:buttonsRect];
}

- (void)layoutLandscape
{
	CGRect bounds = self.bounds;
	CGRect containerBounds = CGRectMake(0.0, 0.0, [self longDimension], [self shortDimension]);
	
	// old 3.5 inch iPhones are
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
		[UIScreen mainScreen].bounds.size.height < 568.0) {
		containerBounds.size.width += [self padding] * 4.0;
	}
	
	_contentContainer.bounds = containerBounds;
	_contentContainer.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
		
	_imageView.frame = CGRectMake(0.0, 0.0, [self shortDimension], [self shortDimension]);
	
	// the minimum X value for labels and stuff going on the right side of the image
	CGFloat leftX = CGRectGetMaxX(_imageView.frame) + [self padding];
	CGFloat currentY = [self padding];
	
	CGSize size = [_titleLabel.text sizeWithFont:_titleLabel.font];
	_titleLabel.frame = CGRectMake(leftX, currentY,
								   containerBounds.size.width - leftX - [self padding],
								   size.height);
	currentY = CGRectGetMaxY(_titleLabel.frame);
	currentY += [self padding];
	
	CGFloat buttonY = containerBounds.size.height - [self buttonHeight] - [self padding] * 0.5;
	
	// Y value before buttons at bottom - currentY
	CGFloat bodyMaxHeight = (buttonY - [self padding]) - currentY;
	CGSize bodyMaxSize = CGSizeMake(containerBounds.size.width - leftX - [self padding], bodyMaxHeight);
	CGSize bodySize =[YRDFontSizing sizeForString:_messageLabel.text font:_messageLabel.font
										  maxSize:bodyMaxSize lineBreakMode:NSLineBreakByWordWrapping];
	_messageLabel.frame = CGRectMake(leftX, currentY, bodySize.width, bodySize.height);
	
	CGRect buttonsRect = CGRectMake(leftX, buttonY, containerBounds.size.width - leftX - [self padding], [self buttonHeight]);
	[self layoutButtonsInRect:buttonsRect];
}

- (void)layoutButtonsInRect:(CGRect)rect
{
	// width of buttons + padding
	CGFloat totalWidth = _buttons.count * [self buttonWidth] + [self padding] * (_buttons.count - 1);
	CGFloat centerX = CGRectGetMidX(rect);
	
	for (NSUInteger i = 0; i < _buttons.count; i++) {
		CGFloat x = centerX - totalWidth/2.0 + i * [self buttonWidth] + i * [self padding];
		CGFloat y = rect.origin.y;
		
		CGFloat centerX = x + [self buttonWidth] / 2.0;
		CGFloat centerY = y + [self buttonHeight] / 2.0;
		
		UIButton *button = _buttons[i];
		button.center = CGPointMake(centerX, centerY);
	}
}

#pragma mark - Button creation

- (UIButton *)makeButtonOfType:(YRDButtonType)buttonType
{
	CGSize buttonSize = CGSizeMake([self buttonWidth], [self buttonHeight]);
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.titleLabel.font = [UIFont boldSystemFontOfSize:14.0 * [self deviceScaleFactor]];
	button.bounds = CGRectMake(0.0, 0.0, buttonSize.width, buttonSize.height);
	
	if (buttonType == YRDButtonTypeConfirm) {
		[button setTitleColor:[self confirmButtonTextColor] forState:UIControlStateNormal];
		
		UIImage *background = [self buttonBackgroundWithSize:buttonSize rectHeightRatio:0.9 color:[self confirmButtonColor]];
		[button setBackgroundImage:background forState:UIControlStateNormal];
	} else if (buttonType == YRDButtonTypeCancel) {
		[button setTitleColor:[self cancelButtonTextColor] forState:UIControlStateNormal];
		
		UIImage *background = [self buttonBackgroundWithSize:buttonSize rectHeightRatio:0.8 color:[self cancelButtonColor]];
		[button setBackgroundImage:background forState:UIControlStateNormal];
	}
	
	return button;
}

- (UIImage *)buttonBackgroundWithSize:(CGSize)size rectHeightRatio:(CGFloat)rectHeightRatio color:(UIColor *)color
{
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
	
	[color setFill];
	
	CGFloat rectHeight = size.height * rectHeightRatio;
	CGRect rect = CGRectMake(0, size.height/2.0 - rectHeight/2.0, size.width, rectHeight);
	
	CGFloat cornerRadius = rectHeight * (1.0/3.0);
	// floorf & -1.0 required so that retina devices don't lose their mind when trying to render
	// the corner radii (comment out line and run on non-retina & retina device to see what I mean)
	cornerRadius = floorf(cornerRadius - 1.0);
	
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
	[path fill];
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

#pragma mark - "Contants"

// width in portrait, height in landscape
// also defines the width & height of the image
- (CGFloat)shortDimension
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		return 240.0;
	} else {
		return 560.0;
	}
}

// height in portrait, width in landscape
- (CGFloat)longDimension
{
	CGRect screenBounds = [UIScreen mainScreen].bounds;
	return screenBounds.size.height - 80.0;
}

// padding/spacing used in various places
- (CGFloat)padding
{
	return 10.0 * [self deviceScaleFactor];
}

- (CGFloat)buttonHeight
{
	return 44.0 * [self deviceScaleFactor];
}

- (CGFloat)buttonWidth
{
	return 80.0 * [self deviceScaleFactor];
}

- (UIColor *)containerBackgroundColor
{
	return [UIColor redColor];
}

- (UIColor *)textColor
{
	return [UIColor whiteColor];
}

- (UIColor *)expiryTextColor
{
	return [UIColor yellowColor];
}

- (UIColor *)confirmButtonColor
{
	return [UIColor orangeColor];
}

- (UIColor *)confirmButtonTextColor
{
	return [UIColor whiteColor];
}

- (UIColor *)cancelButtonColor
{
	return [UIColor grayColor];
}

- (UIColor *)cancelButtonTextColor
{
	return [UIColor whiteColor];
}

- (CGFloat)deviceScaleFactor
{
	return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 2.0 : 1.0;
}

@end