//
//  JJAppReceiptVerifier.h
//  SubscriptionManager
//
//  Created by Jeffrey Jackson 6/25/2015
//

#import <Foundation/Foundation.h>
#import "JJReceiptVerifier.h"
#import "RMAppReceipt.h"

@interface JJAppReceiptVerifier : NSObject

@property (weak, nonatomic) id<JJReceiptVerifierDelegate> delegate;

- (void)verifyAppReceipt;
- (void)verifyAppReceiptForProduct:(NSString *)productIdentifier;
- (void)clearPurchaseInfo;
- (void)refreshAppReceipt;

@end

@interface RMAppReceipt (JJSubscriptionManager)

- (RMAppReceiptIAP *)lastReceiptForAutoRenewableSubscriptionOfProductIdentifier:(NSString *)productIdentifier;
- (NSDate *)expirationDateOfLatestAutoRenewableSubscriptionOfProductIdentifier:(NSString *)productIdentifier;

@end
