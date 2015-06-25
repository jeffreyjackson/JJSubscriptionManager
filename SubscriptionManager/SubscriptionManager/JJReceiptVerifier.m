//
//  JJReceiptVerifier.m
//  SubscriptionManager
//
//  Created by Jeffrey Jackson 6/25/2015
//


#import "JJReceiptVerifier.h"
#import "JJSubscriptionManager.h"
#import "JJAppReceiptVerifier.h"

@interface JJReceiptVerifier () <JJReceiptVerifierDelegate>

@property (strong, nonatomic) JJAppReceiptVerifier *appReceiptVerifier;
@property (strong, nonatomic) NSNumber *latestVerifiedExpirationIntervalSince1970;

@end

static NSNumber *_appReceiptAvailable = nil;

@implementation JJReceiptVerifier

#pragma mark - Private

+ (BOOL)isAppReceiptAvailable
{
    if (!_appReceiptAvailable) {
        _appReceiptAvailable = [NSNumber numberWithBool:(floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)];
    }
    return [_appReceiptAvailable boolValue];
}

- (JJAppReceiptVerifier *)appReceiptVerifier
{
    if (!_appReceiptVerifier) {
        _appReceiptVerifier = [[JJAppReceiptVerifier alloc] init];
        _appReceiptVerifier.delegate = self;
    }
    return _appReceiptVerifier;
}

#pragma mark - Public

- (void)verifySavedReceipt
{
    if ([self.class isAppReceiptAvailable]) {
        [self.appReceiptVerifier verifyAppReceipt];
    }
}

- (void)verifyReceipt:(NSData *)receipt forProduct:(NSString *)productIdentifier
{
    if ([self.class isAppReceiptAvailable]) {
        [self.appReceiptVerifier verifyAppReceiptForProduct:productIdentifier];
    }
}

- (void)checkForRenewedSubscription
{
    if ([self.class isAppReceiptAvailable]) {
        [self.appReceiptVerifier refreshAppReceipt];
    }
}

#pragma mark - JCLegacyReceiptVerifierDelegate

- (void)receiptVerifier:(id)verifier
     verifiedExpiration:(NSNumber *)expirationIntervalSince1970
{
    BOOL expirationValid = (expirationIntervalSince1970.doubleValue > [[NSDate date] timeIntervalSince1970]);
    
    if (!expirationValid &&
        self.latestVerifiedExpirationIntervalSince1970.doubleValue > [[NSDate date] timeIntervalSince1970]) {
            return;
    }

    if (expirationIntervalSince1970.doubleValue <= self.latestVerifiedExpirationIntervalSince1970.doubleValue) {
        return;
    }
    self.latestVerifiedExpirationIntervalSince1970 = expirationIntervalSince1970;

    if (self.delegate &&
        [self.delegate conformsToProtocol:@protocol(JJReceiptVerifierDelegate)] &&
        [self.delegate respondsToSelector:@selector(receiptVerifier:verifiedExpiration:)]) {
        [self.delegate receiptVerifier:self
                    verifiedExpiration:(expirationValid ? expirationIntervalSince1970 : nil)];
    }
}

#pragma mark - Testing

- (void)clearPurchaseInfo
{
    if ([self.class isAppReceiptAvailable]) {
        [self.appReceiptVerifier clearPurchaseInfo];
    }
}

@end
