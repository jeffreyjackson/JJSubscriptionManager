//
//  JJStoreKitHelper.m
//  SubscriptionManager
//
//  Created by Jeffrey Jackson 6/25/2015
//

#import "JJStoreKitHelper.h"
#import "JJSubscriptionManager.h"
#import "Reachability.h"

@interface JJStoreKitHelper () <SKProductsRequestDelegate>

@property (strong, nonatomic) NSArray *products;
@property (strong, nonatomic) SKProductsRequest *productsRequest;
@property (strong, nonatomic) NSTimer *productsRequestRetryTimer;
@property (strong, nonatomic) Reachability *internetReachability;
@property (strong, nonatomic) void (^onPurchaseCompletion) (BOOL, NSError *);
@property (strong, nonatomic) void (^onRestoreCompletion) (BOOL, NSError *);

@end

NSTimeInterval kProductRequestRetryInterval = 15.0;

@implementation JJStoreKitHelper

- (void)dealloc
{
    if (_productsRequestRetryTimer) {
        [_productsRequestRetryTimer invalidate];
        _productsRequestRetryTimer = nil;
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        self.internetReachability = [Reachability reachabilityForInternetConnection];
        [self.internetReachability startNotifier];
    }
    return self;
}

+ (NSArray *)productIdentifiers
{
    NSArray *identifiers = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ProductIdentifiers" ofType:@"plist"]];
    return identifiers;
}

- (BOOL)isInternetReachable
{
    return (self.internetReachability.currentReachabilityStatus != NotReachable);
}

#pragma mark - Making Purchases

- (BOOL)addProductToPaymentQueue:(NSString *)productId
{
        NSInteger productIndex = [self.products indexOfObjectPassingTest:^BOOL(SKProduct *obj, NSUInteger idx, BOOL *stop)
                                  {
                                      if ([obj.productIdentifier isEqualToString:productId]) {
                                          *stop = YES;
                                          return YES;
                                      }
                                      return NO;
                                  }];

        if (productIndex == NSNotFound) {
            return NO;
        }
        
        SKProduct *product = [self.products objectAtIndex:productIndex];
    
		SKPayment *payment = [SKPayment paymentWithProduct:product];
		[[SKPaymentQueue defaultQueue] addPayment:payment];
        
        return YES;
}

#pragma mark - Public

- (BOOL)requestProductData
{
    if (self.products.count != 0) {
        return NO;
    }
    
    if (self.productsRequest) {
        return NO;
    }
    
    if (self.internetReachability.currentReachabilityStatus == NotReachable) {
        return NO;
    }
    
    NSArray *productIdentifiers = [self.class productIdentifiers];
	self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
	self.productsRequest.delegate = self;
	[self.productsRequest start];
    
    return YES;
}

- (BOOL)canStoreTransactionProceed:(NSError *__autoreleasing *)error
{
    BOOL hasError = NO;
    NSString *errorMessage = nil;
    if (self.onPurchaseCompletion || self.onRestoreCompletion) {
        errorMessage = @"Could not start transaction because another transaction is in progress.";
        hasError = YES;
    }
    
    if (!hasError && ![self isInternetReachable]) {
        errorMessage = @"Could not start transaction because internet is not reachable.";
        hasError = YES;
    }
    
    if (!hasError && ![SKPaymentQueue canMakePayments]) {
        errorMessage = @"Could not add product to SKPaymentQueue because IAP is disabled in Settings.";
        hasError = YES;
    }

    if (hasError) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:errorMessage forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"JJStoreKitHelperDomain" code:0 userInfo:errorDetail];
    }

    return !hasError;
}

- (BOOL)buyProductWithIdentifier:(NSString *)productIdentifier
                      completion:(void (^)(BOOL, NSError *))completion
                           error:(NSError *__autoreleasing *)error
{
    NSError *transactionError = nil;
    BOOL transactionAllowed = [self canStoreTransactionProceed:&transactionError];
    if (!transactionAllowed) {
        *error = transactionError;
        return NO;
    }

    if (completion) {
        self.onPurchaseCompletion = completion;
    }
    
    BOOL addedToPaymentQueue = [self addProductToPaymentQueue:productIdentifier];
    
    if (!addedToPaymentQueue) {
        self.onPurchaseCompletion = nil;
        
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Could not add product to payment queue."
                       forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"JJStoreKitHelperDomain" code:0 userInfo:errorDetail];
    }
    
    return addedToPaymentQueue;
}

- (BOOL)restorePreviousTransactionsWithCompletion:(void (^)(BOOL, NSError *))completion
                                            error:(NSError *__autoreleasing *)error
{
    NSError *transactionError = nil;
    BOOL transactionAllowed = [self canStoreTransactionProceed:&transactionError];
    if (!transactionAllowed) {
        *error = transactionError;
        return NO;
    }
    
    if (completion) {
        self.onRestoreCompletion = completion;
    }
    
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];

    return YES;
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    if (request != self.productsRequest) {
        return;
    }
    self.productsRequest = nil;
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"productIdentifier" ascending:YES];
    NSArray *descriptors = [NSArray arrayWithObject:descriptor];
    self.products = [response.products sortedArrayUsingDescriptors:descriptors];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:JJProductDataWasFetchedNotification
                                                        object:nil];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    if (request == self.productsRequest) {
        self.productsRequest = nil;
        
        if (self.productsRequestRetryTimer) {
            [self.productsRequestRetryTimer invalidate];
        }
        self.productsRequestRetryTimer = [NSTimer scheduledTimerWithTimeInterval:kProductRequestRetryInterval
                                                                          target:self
                                                                        selector:@selector(requestProductData)
                                                                        userInfo:nil
                                                                         repeats:NO];
    }
}

- (void)requestDidFinish:(SKRequest *)request
{
    if (request == self.productsRequest) {
        self.productsRequest = nil;
    }
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for (SKPaymentTransaction *transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
                [self purchaseTransactionCompleted:transaction];
                break;
				
            case SKPaymentTransactionStateFailed:
                [self transactionFailed:transaction];
                break;
				
            case SKPaymentTransactionStateRestored:
                [self restoreTransactionCompleted:transaction];
                break;
				
            default:
                break;
		}
	}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    if (self.onRestoreCompletion) {
        self.onRestoreCompletion(YES, nil);
        self.onRestoreCompletion = nil;
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    if (self.onRestoreCompletion) {
        self.onRestoreCompletion(NO, error);
        self.onRestoreCompletion = nil;
    }
}

- (void)transactionFailed:(SKPaymentTransaction *)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if (self.onPurchaseCompletion)
    {
        self.onPurchaseCompletion(NO, transaction.error);
        self.onPurchaseCompletion = nil;
    } else if (self.onRestoreCompletion) {
        self.onRestoreCompletion(NO, transaction.error);
        self.onRestoreCompletion = nil;
    }
}

#pragma mark Purchase and Restore

- (void)purchaseTransactionCompleted:(SKPaymentTransaction *)transaction
{
    [self provideContentForTransaction:transaction];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    // callback
    if (self.onPurchaseCompletion) {
        self.onPurchaseCompletion(YES, nil);
        self.onPurchaseCompletion = nil;
    }
}

- (void)restoreTransactionCompleted:(SKPaymentTransaction *)transaction
{
	[self provideContentForTransaction:transaction];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)provideContentForTransaction:(SKPaymentTransaction *)transaction
{
    if (self.delegate && [self.delegate conformsToProtocol:@protocol(JJStoreKitHelperDelegate)] && [self.delegate respondsToSelector:@selector(storeKitHelper:didCompleteTransaction:)]) {
        [self.delegate storeKitHelper:self didCompleteTransaction:transaction];
    }
}

@end
