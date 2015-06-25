//
//  JJSubscriptionManager.m
//  SubscriptionManager
//
//  Created by Jeffrey Jackson 6/25/2015
//

#import "JJSubscriptionManager.h"
#import <StoreKit/StoreKit.h>
#import "JJStoreKitHelper.h"
#import "Lockbox.h"
#import "JJReceiptVerifier.h"
#import "Reachability.h"

#pragma mark - Notifications

NSString *const JJSubscriptionExpiredNotification = @"JJSubscriptionExpiredNotification";
NSString *const JJSubscriptionWasMadeNotification = @"JJSubscriptionWasMadeNotification";
NSString *const JJProductDataWasFetchedNotification = @"JJProductDataWasFetchedNotification";

#pragma mark - Constants

static JJSubscriptionManager *_sharedManager = nil;
NSString *const kLockboxSubscriptionExpirationIntervalKey = @"subscription-expiration-interval";

#pragma mark - JJSubscriptionManager

@interface JJSubscriptionManager () <JJReceiptVerifierDelegate, JJStoreKitHelperDelegate>

@property (strong, nonatomic) JJReceiptVerifier *receiptVerifier;
@property (nonatomic, getter = isReceiptVerifiedOnce) BOOL receiptVerifiedOnce;
@property (strong, nonatomic) JJStoreKitHelper *storeKitHelper;

@end

@implementation JJSubscriptionManager

#pragma mark - Singleton

+ (JJSubscriptionManager *)sharedManager
{
    if (_sharedManager) {
        return _sharedManager;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[super allocWithZone:NULL] init];
    });
    return _sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedManager];
}

- (id)init
{
    if (_sharedManager) {
        return _sharedManager;
    }

    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self.storeKitHelper];
        [self.storeKitHelper requestProductData];
    }
    return self;
}

#pragma mark - Accessors

- (JJReceiptVerifier *)receiptVerifier
{
    if (!_receiptVerifier) {
        _receiptVerifier = [[JJReceiptVerifier alloc] init];
        _receiptVerifier.delegate = self;
    }
    return _receiptVerifier;
}

- (JJStoreKitHelper *)storeKitHelper
{
    if (!_storeKitHelper) {
        _storeKitHelper = [[JJStoreKitHelper alloc] init];
        _storeKitHelper.delegate = self;
    }
    return _storeKitHelper;
}

#pragma mark - Public Methods

- (NSArray *)products
{
    NSArray *products = self.storeKitHelper.products;
    if (!products) {
        [self.storeKitHelper requestProductData];
    }
    return products;
}

- (BOOL)isSubscriptionActive
{
    if (!self.isReceiptVerifiedOnce) {
        [self.receiptVerifier verifySavedReceipt];
    }

    NSNumber *expirationInterval = [self subscriptionExpirationIntervalSince1970];
    if (expirationInterval) {
        if (expirationInterval.doubleValue > [[NSDate date] timeIntervalSince1970]) {
            return YES;
        } else {
            [self setSubscriptionExpirationIntervalSince1970:nil];
            return NO;
        }
    }
    
    return NO;
}

- (BOOL)buyProductWithIdentifier:(NSString *)productIdentifier completion:(void (^)(BOOL, NSError *))completion error:(NSError *__autoreleasing *)error
{
    return [self.storeKitHelper buyProductWithIdentifier:productIdentifier
                                              completion:completion
                                                   error:error];
}

- (BOOL)restorePreviousTransactionsWithCompletion:(void (^)(BOOL, NSError *))completion error:(NSError *__autoreleasing *)error
{
    return [self.storeKitHelper restorePreviousTransactionsWithCompletion:completion error:error];
}

#pragma mark - JJReceiptVerifierDelegate

- (void)receiptVerifier:(id)verifier
     verifiedExpiration:(NSNumber *)expirationIntervalSince1970
{
    self.receiptVerifiedOnce = YES;
    [self setSubscriptionExpirationIntervalSince1970:expirationIntervalSince1970];
}

#pragma mark - JJStoreKitHelperDelegate

- (void)storeKitHelper:(JJStoreKitHelper *)helper didCompleteTransaction:(SKPaymentTransaction *)transaction
{
    NSData *receipt = nil;
    if ([transaction respondsToSelector:@selector(transactionReceipt)]) {
        receipt = transaction.transactionReceipt;
    }
    
    [self.receiptVerifier verifyReceipt:receipt forProduct:transaction.payment.productIdentifier];
}

#pragma mark - Keychain Storage

- (NSNumber *)subscriptionExpirationIntervalSince1970
{
    NSString *string = [Lockbox stringForKey:kLockboxSubscriptionExpirationIntervalKey];
    if (!string) {
        return nil;
    }
    return @([string integerValue]);
}

- (BOOL)setSubscriptionExpirationIntervalSince1970:(NSNumber *)interval
{
    NSNumber *currentExpiration = [self subscriptionExpirationIntervalSince1970];
    BOOL wasSubscribed = (currentExpiration != nil);
    BOOL isSubscribed = (interval != nil);
    
    BOOL returnValue;
    if (interval == nil) {
        returnValue = [Lockbox setString:nil forKey:kLockboxSubscriptionExpirationIntervalKey];
    } else {
        returnValue = [Lockbox setString:[interval stringValue] forKey:kLockboxSubscriptionExpirationIntervalKey];
    }
    
    if (wasSubscribed && !isSubscribed) {
        [self.receiptVerifier checkForRenewedSubscription];
        [[NSNotificationCenter defaultCenter] postNotificationName:JJSubscriptionExpiredNotification object:nil];
    } else if (isSubscribed && !wasSubscribed) {
        [[NSNotificationCenter defaultCenter] postNotificationName:JJSubscriptionWasMadeNotification object:nil];
    }
    
    return returnValue;
}

- (void)clearPurchaseInfo
{
    [Lockbox setString:nil forKey:kLockboxSubscriptionExpirationIntervalKey];
    [self.receiptVerifier clearPurchaseInfo];
}

@end


@implementation SKProduct (JJSubscriptionManager)

- (NSString *)formattedPrice
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:self.priceLocale];
    NSString *formattedString = [numberFormatter stringFromNumber:self.price];
    
    return formattedString;
}

@end

