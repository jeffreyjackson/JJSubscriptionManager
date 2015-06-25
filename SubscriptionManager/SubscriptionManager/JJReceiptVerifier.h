//
//  JJReceiptVerifier.h
//  SubscriptionManager
//
//  Created by Jeffrey Jackson 6/25/2015
//

#import <Foundation/Foundation.h>

@protocol JJReceiptVerifierDelegate <NSObject>

- (void)receiptVerifier:(id)verifier verifiedExpiration:(NSNumber *)expirationIntervalSince1970;

@end

@interface JJReceiptVerifier : NSObject

@property (weak, nonatomic) id<JJReceiptVerifierDelegate> delegate;

- (void)verifySavedReceipt;
- (void)verifyReceipt:(NSData *)receipt forProduct:(NSString *)productIdentifier;
- (void)checkForRenewedSubscription;
- (void)clearPurchaseInfo;

@end
