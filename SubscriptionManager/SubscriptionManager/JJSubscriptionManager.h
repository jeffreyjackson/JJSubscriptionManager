//
//  JJSubscriptionManager.h
//  SubscriptionManager
//
//  Created by Jeffrey Jackson 6/25/2015
//

#import <StoreKit/StoreKit.h>

extern NSString *const JJSubscriptionExpiredNotification;
extern NSString *const JJSubscriptionWasMadeNotification;
extern NSString *const JJProductDataWasFetchedNotification;

@interface JJSubscriptionManager : NSObject

+ (JJSubscriptionManager *)sharedManager;

- (BOOL)isSubscriptionActive;
- (NSArray *)products;
- (BOOL)buyProductWithIdentifier:(NSString *)productIdentifier completion:(void (^)(BOOL success, NSError *transactionError))completion error:(NSError *__autoreleasing *)pretransactionError;
- (BOOL)restorePreviousTransactionsWithCompletion:(void (^)(BOOL success, NSError *transactionError))completion error:(NSError *__autoreleasing *)pretransactionError;
- (void)clearPurchaseInfo;

@end

@interface SKProduct (JJSubscriptionManager)

- (NSString *)formattedPrice;

@end
