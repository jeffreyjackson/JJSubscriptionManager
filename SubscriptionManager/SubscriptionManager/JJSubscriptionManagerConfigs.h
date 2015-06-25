//
//  JJSubscriptionManagerConfigs.h
//  SubscriptionManager
//
//  Created by Jeffrey Jackson 6/25/2015
//

#ifndef SANDBOX_MODE
#if DEBUG
#define SANDBOX_MODE YES
#else
#define SANDBOX_MODE NO
#endif
#endif

// Apple's server is used to verify receipt if your server is down.
#ifndef APPLE_VERIFICATION_SERVER
#if DEBUG
#define APPLE_VERIFICATION_SERVER @"https://sandbox.itunes.apple.com/verifyReceipt" // Test server.
#else
#define APPLE_VERIFICATION_SERVER @"https://buy.itunes.apple.com/verifyReceipt" // Production server.
#endif
#endif

// This is your shared secret for autorenewable subscriptions on iTunesConnect.
//#warning Set to your app's shared secret.
//#ifndef AUTORENEWABLE_SUBSCRIPTION_SHARED_SECRET
//#define AUTORENEWABLE_SUBSCRIPTION_SHARED_SECRET @"f374a716e451449dbe2dd52f5939f882"
//#endif
