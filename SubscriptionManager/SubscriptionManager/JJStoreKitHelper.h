//
//  JJStoreKitHelper.h
//  SubscriptionManager
//
//  Created by Jeffrey Jackson 6/25/2015
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class JJStoreKitHelper;

@protocol JJStoreKitHelperDelegate <NSObject>

- (void)storeKitHelper:(JJStoreKitHelper *)helper didCompleteTransaction:(SKPaymentTransaction *)transaction;

@end

@interface JJStoreKitHelper : NSObject <SKPaymentTransactionObserver>

@property (weak, nonatomic) id<JJStoreKitHelperDelegate> delegate;
@property (nonatomic, readonly) NSArray *products;

- (BOOL)requestProductData;
- (BOOL)buyProductWithIdentifier:(NSString *)productIdentifier completion:(void (^)(BOOL, NSError *))completion error:(NSError **)error;
- (BOOL)restorePreviousTransactionsWithCompletion:(void (^)(BOOL, NSError *))completion error:(NSError *__autoreleasing *)error;

@end
