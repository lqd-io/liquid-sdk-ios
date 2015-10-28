//
//  ViewController.m
//  Liquid
//
//  Created by Liquid Liquid Data Intelligence, S.A. (lqd.io) on 12/06/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LiquidDemoViewController.h"
#import "Liquid.h"
#import "NSDateFormatter+LQDateFormatter.h"
#import "UIColor+LQColor.h"

@interface LiquidDemoViewController ()

@property (nonatomic, strong, readonly) NSDictionary *userProfiles;
@property (nonatomic, strong) NSString *selectedUserProfile;

@end

@implementation LiquidDemoViewController

NSString *const defaultTitle = @"Welcome to our app";
NSString *const defaultBgColor = @"#FF0000";
NSString *const defaultPromoDay = @"2014-05-11T15:17:03.103+0100";
NSInteger const defaultloginVersion = 3;
CGFloat const defaultDiscount = 0.15f;
BOOL const defaultShowAds = YES;

@synthesize userProfiles = _userProfiles;

#pragma mark - Initializers

- (NSDictionary *)userProfiles {
    if (!_userProfiles) {
        NSDictionary *user0Attributes = @{ @"name": @"Anna Martinez", @"age": @25, @"gender": @"female" };
        NSDictionary *user1Attributes = @{ @"name": @"John Clark", @"age": @37, @"gender": @"male" };
        NSDictionary *user2Attributes = @{ @"name": @"Barry Hill", @"age": @16, @"gender": @"male" };
        NSDictionary *user3Attributes = @{ @"name": @"Guilherme Alves", @"age": @1, @"gender": @"male" };
        _userProfiles = [NSDictionary dictionaryWithObjectsAndKeys:user0Attributes, @"100",
                         user1Attributes, @"101", user2Attributes, @"102", user3Attributes, @"103", nil];
    }
    return _userProfiles;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];

    // Pre-select user from previous launch:
    NSString *currentUserIdentifier = [[Liquid sharedInstance] userIdentifier];
    self.selectedUserProfile = currentUserIdentifier;
    self.userUniqueId.text = currentUserIdentifier;
    if ([currentUserIdentifier isEqualToString:@"100"]) {
        [self.userSelectorSegmentedControl setSelectedSegmentIndex:0];
    } else if ([currentUserIdentifier isEqualToString:@"101"]) {
        [self.userSelectorSegmentedControl setSelectedSegmentIndex:1];
    } else if ([currentUserIdentifier isEqualToString:@"102"]) {
        [self.userSelectorSegmentedControl setSelectedSegmentIndex:2];
    } else if ([currentUserIdentifier isEqualToString:@"103"]) {
        [self.userSelectorSegmentedControl setSelectedSegmentIndex:3];
    } else {
        self.anonymousUserButton.selected = YES;
        [self.userSelectorSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    }

    // Being notified about Liquid events (alternative 1):
    [[Liquid sharedInstance] setDelegate:self];

    // Being notified about Liquid events (alternative 2):
    /*
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(receivedValues:)
                               name:LQDidReceiveValues
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(loadedValues:)
                               name:LQDidLoadValues
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(identifiedUser:)
                               name:LQDidIdentifyUser
                             object:nil];
     */
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDelegateNotification:)
                                                 name:@"Push Notification Received"
                                               object:nil];

    [self refrehInformation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}


#pragma mark - UI Elements Actions for Demo App

- (IBAction)resetSDKButtonPressed:(id)sender {
    [[Liquid sharedInstance] softReset];
}

- (IBAction)flushHTTPRequestsButtonPressed:(id)sender {
    [[Liquid sharedInstance] flush];
}

- (IBAction)printIdentifierButtonPressed:(id)sender {
    NSLog(@"User unique_id: %@", [[Liquid sharedInstance] userIdentifier]);
    NSLog(@"Device unique_id: %@", [[Liquid sharedInstance] deviceIdentifier]);
    NSLog(@"Session unique_id: %@", [[Liquid sharedInstance] sessionIdentifier]);
}

- (IBAction)trackEvent1:(id)sender {
    [[Liquid sharedInstance] track:@"Buy Product" attributes:@{
                                                               @"productId": @40,
                                                               @"price": @30.5,
                                                               @"withDiscount": @YES
                                                               }];
    NSLog(@"Track 'Buy Product' event");
}

- (IBAction)trackEvent2:(id)sender {
    [[Liquid sharedInstance] track:@"Play Music" attributes:@{
                                                              @"artist": @"Bee Gees",
                                                              @"track": @"Stayin' Alive",
                                                              @"album": @"Saturday Night Fever",
                                                              @"releaseYear": @1977
                                                              }];
    NSLog(@"Track 'Play Music' event");
}

- (IBAction)trackEvent3:(id)sender {
    [[Liquid sharedInstance] track:self.customEventNameTextField.text];
    NSLog(@"Track '%@' event", self.customEventNameTextField.text);
}

- (IBAction)autoLoadValuesSwitchValueChanged:(id)sender {
    if (self.autoLoadValuesSwitch.isOn) {
        [Liquid sharedInstance].autoLoadValues = YES;
        self.loadValuesButton.enabled = NO;
        NSLog(@"Auto load values (when new values are received from Liquid server) is now ON");
    } else {
        [Liquid sharedInstance].autoLoadValues = NO;
        self.loadValuesButton.enabled = YES;
        NSLog(@"Auto load values (when new values are received from Liquid server) is now OFF");
    }
}

- (IBAction)requestValuesButtonPressed:(id)sender {
    [[Liquid sharedInstance] requestValues];
}

- (IBAction)loadValuesButtonPressed:(id)sender {
    [[Liquid sharedInstance] loadValues];
}

- (void)refrehInformation {
    NSString *title = [[Liquid sharedInstance] stringForKey:@"title" fallback:defaultTitle];
    NSDate *promoDay = [[Liquid sharedInstance] dateForKey:@"promoDay" fallback:[NSDateFormatter dateFromISO8601String:defaultPromoDay]];
    UIColor *bgColor = [[Liquid sharedInstance] colorForKey:@"bgColor" fallback:[UIColor colorFromHexadecimalString:defaultBgColor]];
    NSInteger loginVersion = [[Liquid sharedInstance] intForKey:@"login" fallback:defaultloginVersion];
    CGFloat discount = [[Liquid sharedInstance] floatForKey:@"discount" fallback:defaultDiscount];
    BOOL showAds = [[Liquid sharedInstance] boolForKey:@"showAds" fallback:defaultShowAds];
    
    [self.bgColorLabel setText:[UIColor hexadecimalStringFromUIColor:bgColor]];
    [self.bgColorSquare setBackgroundColor:bgColor];
    [self.showAdsLabel setText:(showAds ? @"yes" : @"no")];
    [self.titleLabel setText:title];
    
    NSLog(@"title: %@", title);
    NSLog(@"promoDay: %@", promoDay);
    NSLog(@"bgColor: %@", bgColor);
    NSLog(@"loginVersion: %d", (int)loginVersion);
    NSLog(@"discount: %f", discount);
    NSLog(@"showAds: %@", (showAds ? @"yes" : @"no"));
}

- (IBAction)IdentifyAnonymousButton:(UIButton *)sender {
    [[Liquid sharedInstance] resetUser];
    [sender setSelected:YES];
    // Unselect all Segmented Control buttons
    [self.userSelectorSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    self.selectedUserProfile = [[Liquid sharedInstance] userIdentifier];
    self.userUniqueId.text = [[Liquid sharedInstance] userIdentifier];
}

- (void)setCurrentUserWithIdentifier:(NSString *)userIdentifier {
    NSDictionary *userAttributes = [self.userProfiles objectForKey:userIdentifier];
    [[Liquid sharedInstance] identifyUserWithIdentifier:userIdentifier attributes:userAttributes];

    // Update interface:
    self.anonymousUserButton.selected = NO;
    self.selectedUserProfile = userIdentifier;
    self.userUniqueId.text = [[Liquid sharedInstance] userIdentifier];
}

#pragma mark - Liquid Delegate methods

- (void)liquidDidReceiveValues {
    NSLog(@"Received new values from Liquid Server. They were stored in cache, waiting to be loaded.");
}

- (void)liquidDidLoadValues {
    [self refrehInformation];
    NSLog(@"Cached values were loaded into memory.");
}

- (void)liquidDidIdentifyUserWithIdentifier:(NSString *)identifier {
    NSDictionary *userAttributes = [self.userProfiles objectForKey:identifier];
    NSLog(@"Current user is now '%@', with attributes: %@", identifier, userAttributes);
}

#pragma mark - Liquid NSNotification callback methods

- (void)receivedValues:(NSNotification *)notification {
    NSLog(@"Received new values from Liquid Server. They were stored in cache, waiting to be loaded.");
}

- (void)loadedValues:(NSNotification *)notification {
    [self refrehInformation];

    NSLog(@"Cached values were loaded into memory.");
}

- (void)identifiedUser:(NSNotification *)notification {
    [self refrehInformation];

    NSString *userIdentifier = [[notification userInfo] objectForKey:@"identifier"];
    NSDictionary *userAttributes = [self.userProfiles objectForKey:userIdentifier];
    NSLog(@"Current user is now '%@', with attributes: %@", userIdentifier, userAttributes);
}

- (void)applicationDelegateNotification:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"Push Notification Received"]) {
        NSLog(@"Push Notification received");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Push notification received"
                                                            message:@"Do whatever you want with this notification."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Close"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark - UITableViewDelegate, UITableViewDataSource methods

- (IBAction)profileSelectorPressed:(UISegmentedControl *)sender {
    [self setCurrentUserWithIdentifier:[NSString stringWithFormat:@"%d", (int) (100 + sender.selectedSegmentIndex)]];
    [self.userAttributesTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
    if (tableView.tag == 1) return [[self.userProfiles objectForKey:self.selectedUserProfile] count];
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    NSString *key = @"";
    NSString *value = @"";
    
    if (tableView.tag == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"PropertyCell"];
        key = [[[self.userProfiles objectForKey:self.selectedUserProfile] allKeys] objectAtIndex:indexPath.row];
        value = [NSString stringWithFormat:@"%@", [[self.userProfiles objectForKey:self.selectedUserProfile] objectForKey:key]];
    }
    cell.textLabel.text = key;
    cell.detailTextLabel.text = value;

    return cell;
}

@end
