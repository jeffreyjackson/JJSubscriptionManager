# JJSubscriptionManager
In-App Purchase Autorenewable Subscription Manager

#### What is it?

-  JJSubscriptionManager is a drop in singleton used for managing autorenewable subscriptions, a type of in-app purchase for iOS.  

#### Which iOS versions?

-  It's good for iOS7 and up.  This singleton does not support manual receipt validation which was required in iOS6 and earlier.  

#### How do I use it?

-  Setting up JJSubscription is pretty straight forward.  It requires at minimum the following 3 steps.

##### ProductIdentifiers.plist

-  Create `ProductIdentifiers.plist` to track Product Identifiers and add to main xcodeproj

##### Initialize

-  Find a place to fire it up, I usually drop it in AppDelegate's didFinishLaunching

```
[JJSubscriptionManager sharedManager];
```

##### Buy and watch subcription

-  Get a list of products
```
NSArray *products = [[JJSubscriptionManager sharedManager] products];
```

-  Make the purchase

```
SKProduct *autorenewableProduct = products[0];
NSError *pretransactionError = nil;
BOOL purchaseStarted = [[JJSubscriptionManager sharedManager] buyProductWithIdentifier:autorenewableProduct.productIdentifier
                                                                            completion:^(BOOL success, NSError *error) {
                                                                                if (!success) {
                                                                                    NSLog(@"NEGATIVE GHOST RIDER");
                                                                                }
                                                                            }
                                                                                 error:&pretransactionError];
```

-  Verify subscription is active
```
[[JJSubscriptionManager sharedManager] isSubscriptionActive];
```



#### Todo

- [ ] Determine Mac OS X compatibility
- [ ] Remove need for plist
- [ ] Support more than 1 autorenewable subscription
