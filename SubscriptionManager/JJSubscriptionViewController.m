//
//  JJSubscriptionViewController.m
//  SubscriptionManager
//
//  Created by Jeffrey Jackson 6/25/2015
//

#import "JJSubscriptionViewController.h"

#import "JJSubscriptionManager.h"

#import <AudioToolbox/AudioToolbox.h>

@interface JJSubscriptionViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UILabel *statusLabel;
@property (strong, nonatomic) UITableView *productTableView;
@property (strong, nonatomic) UIButton *restoreButton;
@property (strong, nonatomic) JJActivityView *activityView;

@property (strong, nonatomic) NSTimer *statusUpdateTimer;
@property (nonatomic) NSDate *subscribedDate;

@end

void ShowAlert(NSString *title, NSString *message)
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

@implementation JJSubscriptionViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_statusUpdateTimer) {
        [_statusUpdateTimer invalidate];
        _statusUpdateTimer = nil;
    }
}

- (id)init
{
    if ((self = [super init])) {
        [self registerForNotifications];
    }
    return self;
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedProductDataWasFetchedNotification:)
                                                 name:JJProductDataWasFetchedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedSubscriptionWasMadeNotification:)
                                                 name:JJSubscriptionWasMadeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedSubscriptionExpiredNotification:)
                                                 name:JJSubscriptionExpiredNotification
                                               object:nil];
}

#pragma mark - Accessors

- (JJActivityView *)activityView
{
    if (!_activityView) {
        _activityView = [[JJActivityView alloc] init];
    }
    return _activityView;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _statusLabel = [[UILabel alloc] init];
    [self.view addSubview:_statusLabel];
    
    _productTableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                     style:UITableViewStyleGrouped];
    _productTableView.dataSource = self;
    _productTableView.delegate = self;
    [self.view addSubview:_productTableView];
    
    self.restoreButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_restoreButton setTitle:@"Tap to Restore Purchases" forState:UIControlStateNormal];
    [_restoreButton addTarget:self
                       action:@selector(tappedRestoreButton:)
             forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_restoreButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateStatus];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat const statusRelativeHeight = 0.2f;
    CGFloat const productRelativeHeight = 0.6f;
    CGFloat const restoreRelativeHeight = 0.2f;
    CGFloat const textRelativeSize = 0.2f;
    
    CGFloat const width = self.view.bounds.size.width;
    CGFloat const height = self.view.bounds.size.height;
    
    CGFloat y = 0.0f;
    CGFloat const statusHeight = statusRelativeHeight * height;
    self.statusLabel.frame = CGRectMake(0.0f, y, width, statusHeight);
    self.statusLabel.font = [UIFont systemFontOfSize:statusHeight * textRelativeSize];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    y += statusHeight;
    
    CGFloat const productHeight = productRelativeHeight * height;
    self.productTableView.frame = CGRectMake(0.0f, y, width, productHeight);
    y += productHeight;
    
    CGFloat const restoreHeight = restoreRelativeHeight * height;
    self.restoreButton.frame = CGRectMake(0.0f, y, width, restoreHeight);
    self.restoreButton.titleLabel.font = [UIFont systemFontOfSize:restoreHeight * textRelativeSize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (void)updateStatus
{
    static NSNumber *wasSubscribed = nil;
    BOOL isSubscribed = [[JJSubscriptionManager sharedManager] isSubscriptionActive];
    if (wasSubscribed && !isSubscribed && wasSubscribed.boolValue == isSubscribed) {
        return;
    }
    wasSubscribed = @(isSubscribed);
    
    self.restoreButton.enabled = !isSubscribed;
    self.productTableView.userInteractionEnabled = !isSubscribed;

    NSString *statusText;
    if (isSubscribed) {
        statusText = [NSString stringWithFormat:@"Subscribed %@", [self durationFromDate:self.subscribedDate]];
        self.productTableView.alpha = 0.5f;
    } else {
        statusText = @"Not Subscribed";
        self.productTableView.alpha = 1.0f;
    }
    self.statusLabel.text = [@"Status: " stringByAppendingString:statusText];
    
    if (!isSubscribed && !self.statusUpdateTimer) {
        self.statusUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                  target:self
                                                                selector:@selector(updateStatus)
                                                                userInfo:nil
                                                                 repeats:YES];
    }
}

- (void)tappedRestoreButton:(UIButton *)button
{
    NSError *pretransactionError = nil;
    BOOL restoreStarted = [[JJSubscriptionManager sharedManager] restorePreviousTransactionsWithCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            ShowAlert(@"Restore Failed", error.localizedDescription);
        }
        
        [self.activityView hide];
    }
                                                                                                     error:&pretransactionError];
    
    if (restoreStarted) {
        [self.activityView showInView:self.view];
    } else {
        ShowAlert(@"Restore Failed", pretransactionError.localizedDescription);
    }
}

#pragma mark - UITableViewDataSource

- (SKProduct *)productForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *products = [[JJSubscriptionManager sharedManager] products];
    NSInteger row = indexPath.row;
    if (indexPath.row > products.count) {
        return nil;
    }
    
    return [products objectAtIndex:row];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Products";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger productCount = [[[JJSubscriptionManager sharedManager] products] count];
    if (productCount == 0) {
        return 1;
    }
    return productCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SKProduct *product = [self productForIndexPath:indexPath];
    if (!product && indexPath.row > 0) {
        return nil;
    }
    
    static NSString *const reuseId = @"Cell";
    UITableViewCell *cell = [self.productTableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseId];
    }
    
    if (product) {
        cell.textLabel.text = product.productIdentifier;
        cell.detailTextLabel.text = [product formattedPrice];
    } else {
        cell.textLabel.text = @"None";
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView  deselectRowAtIndexPath:indexPath animated:YES];
    
    SKProduct *product = [self productForIndexPath:indexPath];
    if (!product) {
        ShowAlert(@"Please Wait", @"Product data not yet fetched.");
        return;
    }
    
    if ([[JJSubscriptionManager sharedManager] isSubscriptionActive]) {
        ShowAlert(@"Action Canceled", @"You are already subscribed.");
        return;
    }
    
    NSError *pretransactionError = nil;
    BOOL purchaseStarted = [[JJSubscriptionManager sharedManager] buyProductWithIdentifier:product.productIdentifier
                                                                                completion:^(BOOL success, NSError *error) {
                                                                                    if (!success) {
                                                                                        ShowAlert(@"Purchase Failed", error.localizedDescription);
                                                                                    }
                                                                                    
                                                                                    [self.activityView hide];
                                                                                }
                                                                                     error:&pretransactionError];
    if (purchaseStarted) {
        [self.activityView showInView:self.view];
    } else {
        ShowAlert(@"Purchase Failed", pretransactionError.localizedDescription);
    }
}

#pragma mark - Notifications

- (void)beep
{
    SystemSoundID soundID;
    NSString *soundFile = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"aiff"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundFile], &soundID);
    AudioServicesPlayAlertSound(soundID);
}

- (void)receivedProductDataWasFetchedNotification:(NSNotification *)notification
{
    [self.productTableView reloadData];
}

- (void)receivedSubscriptionWasMadeNotification:(NSNotification *)notification
{
    [self beep];
    self.subscribedDate = [NSDate date];
    ShowAlert(nil, @"Received subscribed notification.");
    
    [self updateStatus];
}

- (void)receivedSubscriptionExpiredNotification:(NSNotification *)notification
{
    [self beep];
    ShowAlert(@"Received Expired Notification", [NSString stringWithFormat:@"Time subscribed: %@", [self durationFromDate:self.subscribedDate]]);
    self.subscribedDate = nil;
    
    [self updateStatus];
}

- (NSString *)durationFromDate:(NSDate *)fromDate
{
    NSInteger interval = (NSInteger)[[NSDate date] timeIntervalSinceDate:fromDate];
    return [NSString stringWithFormat:@"%i:%02i", (int)(interval / 60), (int)(interval % 60)];
}
                                                 
@end

#pragma mark - Activity Indicator View

@interface JJActivityView ()

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation JJActivityView

- (UIActivityIndicatorView *)activityIndicator
{
    if (!_activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:_activityIndicator];
    }
    return _activityIndicator;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.activityIndicator.center = CGPointMake(self.bounds.size.width * 0.5f, self.bounds.size.height * 0.5f);
}

- (void)showInView:(UIView *)view
{
    [self.activityIndicator startAnimating];

    self.frame = view.bounds;
    [view addSubview:self];
}

- (void)hide
{
    [self removeFromSuperview];
    [self.activityIndicator stopAnimating];
}

@end
