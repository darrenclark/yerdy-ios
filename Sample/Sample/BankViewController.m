//
//  BankViewController.m
//  Sample
//
//  Created by Darren Clark on 2014-02-26.
//  Copyright (c) 2014 Yerdy. All rights reserved.
//

#import "BankViewController.h"
#import "Yerdy.h"

NSString *Gold = @"Gold",
		*Silver = @"Silver",
		*Bronze = @"Bronze",
		*Diamonds = @"Diamonds",
		*Pearls = @"Pearls",
		*Rubies = @"Rubies";


@interface BankViewController ()

@end

@implementation BankViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self updateDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)earn:(id)sender
{
	NSDictionary *currencies = [self currenciesFromTextFields];
	
	[self incrementCurrencies:currencies];
	
	
	Yerdy *yerdy = [Yerdy sharedYerdy];
	// ensure both methods are tested...
	if (currencies.count == 1)
		[yerdy earnedCurrency:currencies.allKeys[0]
					   amount:[currencies.allValues[0] unsignedIntegerValue]];
	else
		[yerdy earnedCurrencies:currencies];
}

- (IBAction)buyItem:(id)sender
{
	if (_itemName.text.length == 0) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"Please enter an item name"
													   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSDictionary *currencies = [self currenciesFromTextFields];
	for (NSString *currencyName in currencies) {
		NSInteger balance = [defaults integerForKey:currencyName];
		if (balance < [currencies[currencyName] integerValue]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Insufficient funds" message:nil
														   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			return;
		}
	}
	
	[self decrementCurrencies:currencies];
	
	
	Yerdy *yerdy = [Yerdy sharedYerdy];
	// ensure both methods are tested...
	if (currencies.count == 1)
		[yerdy purchasedItem:_itemName.text withCurrency:currencies.allKeys[0]
					  amount:[currencies.allValues[0] unsignedIntegerValue]];
	else
		[yerdy purchasedItem:_itemName.text withCurrencies:currencies];
}

#pragma mark - Currency input/display

- (NSDictionary *)currenciesFromTextFields
{
	NSMutableDictionary *currencies = [NSMutableDictionary dictionary];
	if (_goldInput.text.length > 0)
		currencies[Gold] = @(_goldInput.text.intValue);
	if (_silverInput.text.length > 0)
		currencies[Silver] = @(_silverInput.text.intValue);
	if (_bronzeInput.text.length > 0)
		currencies[Bronze] = @(_bronzeInput.text.intValue);
	if (_diamondsInput.text.length > 0)
		currencies[Diamonds] = @(_diamondsInput.text.intValue);
	if (_pearlsInput.text.length > 0)
		currencies[Pearls] = @(_pearlsInput.text.intValue);
	if (_rubiesInput.text.length > 0)
		currencies[Rubies] = @(_rubiesInput.text.intValue);
	return currencies;
}

- (void)updateDisplay
{
	NSDictionary *labels = @{
		Gold : _gold,
		Silver : _silver,
		Bronze : _bronze,
		Diamonds : _diamonds,
		Pearls : _pearls,
		Rubies : _rubies,
	};
	
	for (NSString *currency in labels) {
		UILabel *label = labels[currency];
		int value = [[NSUserDefaults standardUserDefaults] integerForKey:currency];
		label.text = [NSString stringWithFormat:@"%d", value];
	}
}

- (void)incrementCurrencies:(NSDictionary *)currencies
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	for (NSString *currencyName in currencies) {
		int change = [currencies[currencyName] intValue];
		NSInteger current = [defaults integerForKey:currencyName];
		[defaults setInteger:current + change forKey:currencyName];
	}
	
	[self updateDisplay];
}

- (void)decrementCurrencies:(NSDictionary *)currencies
{
	NSMutableDictionary *negative = [NSMutableDictionary dictionary];
	for (NSString *key in currencies) {
		negative[key] = @(-1 * [currencies[key] intValue]);
	}
	[self incrementCurrencies:negative];
}

@end