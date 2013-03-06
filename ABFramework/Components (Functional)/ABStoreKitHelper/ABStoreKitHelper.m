//
//  ABStoreKitHelper.m
//  ABFramework
//
//  Created by Alexander Blunck on 2/23/13.
//  Copyright (c) 2013 Ablfx. All rights reserved.
//

#import "ABStoreKitHelper.h"

//APPLE FRAMEWORKS
#import <StoreKit/StoreKit.h>

#pragma mark - ABStoreKitItem
/**
 * ABStoreKitItem
 */
@implementation ABStoreKitItem

#pragma mark - Utility
+(id) itemWithProductIdentifier:(NSString*)productIdentifier type:(ABStoreKitItemType)type
{
    return [[self alloc] initWithProductIdentifier:productIdentifier type:type];
}

#pragma mark - Initializer
-(id) initWithProductIdentifier:(NSString*)productIdentifier type:(ABStoreKitItemType)type
{
    self = [super init];
    if (self)
    {
        self.productIdentifier = productIdentifier;
        self.type = type;
    }
    return self;
}

#pragma mark - NSCoding
-(id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super init];
    if (self)
    {
        self.productIdentifier = [aDecoder decodeObjectForKey:@"productIdentifier"];
        self.type = [[aDecoder decodeObjectForKey:@"type"] integerValue];
        self.subscriptionTimeInterval = [[aDecoder decodeObjectForKey:@"subscriptionTimeInterval"] doubleValue];
        self.transactionDate = [aDecoder decodeObjectForKey:@"transactionDate"];
        self.transactionIdentifier = [aDecoder decodeObjectForKey:@"transactionIdentifier"];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder*) aCoder
{
    [aCoder encodeObject:self.productIdentifier forKey:@"productIdentifier"];
    [aCoder encodeObject:[NSNumber numberWithInteger:self.type] forKey:@"type"];
    [aCoder encodeObject:[NSNumber numberWithDouble:self.subscriptionTimeInterval] forKey:@"subscriptionTimeInterval"];
    [aCoder encodeObject:self.transactionDate forKey:@"transactionDate"];
    [aCoder encodeObject:self.transactionIdentifier forKey:@"transactionIdentifier"];
}

@end



#pragma mark - ABStoreKitHelper
/**
 * ABStoreKitHelper
 */
@interface ABStoreKitHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    NSMutableSet *_productIdentifiers;
    NSMutableSet *_validatedProducts;
    NSMutableDictionary *_blockDictionary;
}
@end

@implementation ABStoreKitHelper

#pragma mark - Utility
+ (id)sharedHelper
{
    static dispatch_once_t pred;
    static ABStoreKitHelper *helper = nil;
    
    dispatch_once(&pred, ^{ helper = [[self alloc] init]; });
    return helper;
}



#pragma mark - Initializer
- (id)init {
    if ((self = [super init]))
    {
        if(ABSKH_LOG) NSLog(@"ABStoreKitHelper: Started");
        
        //Allocation
        _validatedProducts = [NSMutableSet new];
        _productIdentifiers = [NSMutableSet new];
        _blockDictionary = [NSMutableDictionary new];
        
        //Add SKPaymentTransactionObserver
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}



#pragma mark - Product Validation
-(void) getNewProductData
{
    if (![self allProductsValidated])
    {
        if(ABSKH_LOG) NSLog(@"ABStoreKitHelper: Checking if Product Identifiers are valid...");
        
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
        request.delegate = self;
        [request start];
        
        [self performSelector:@selector(getNewProductData) withObject:nil afterDelay:30];
    }
}



#pragma mark - Helper
-(BOOL) isPurchased:(NSString*)productIdentifier
{
    //Retrieve all stored ABStoreKitItems
    NSArray *items = [self loadStoreKitItemArray];
    
    //Find specific item
    for (ABStoreKitItem *item in items)
    {
        //Return YEs if it exists
        if ([item.productIdentifier isEqualToString:productIdentifier])
        {
            return YES;
        }
    }
    return NO;
}

-(BOOL) isSubscriptionActive:(NSString*)productIdentifier
{
    //Retrieve all stored ABStoreKitItems
    NSArray *items = [self loadStoreKitItemArray];
    
    //Find specific subscription
    //In case of Auto-Renewable subscriptions there might be more than one ABStoreKitItem saved
    //If one of them is still active this method will return YES immediately
    for (ABStoreKitItem *item in items)
    {
        if (
            [item.productIdentifier isEqualToString:productIdentifier]
            &&
            (item.type == ABStoreKitItemTypeAutoRenewableSubscription || item.type == ABStoreKitItemTypeNonRenewingSubscription)
            )
        {
            //Offline check if subscription is still active
            NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
            NSTimeInterval purchaseTime = [item.transactionDate timeIntervalSince1970];
            NSTimeInterval subscriptionExpireTime = purchaseTime + item.subscriptionTimeInterval;
            
            if (purchaseTime <= currentTime && currentTime <= subscriptionExpireTime)
            {
                return YES;
            }
        }
    }
    
    return NO;
}

-(NSArray*) purchasedInstancesOfSubscription:(NSString*)productIdentifier
{
    NSMutableArray *instances = [NSMutableArray new];
    
    for (ABStoreKitItem *item in [self loadStoreKitItemArray])
    {
        if ([item.productIdentifier isEqualToString:productIdentifier])
        {
            [instances addObject:item];
        }
    }
    
    return (instances.count != 0) ? instances : nil;
}

-(BOOL) allProductsValidated
{
    //Loop through all productIdentifiers
    for (NSString *productIdentifier in _productIdentifiers)
    {
        //Return NO if one product with productIdentifier doesn't exist
        if (![self productValidated:productIdentifier])
        {
            return NO;
        }
    }
    //Return YES if all products in productIdentifiers array were found
    return YES;
}

-(BOOL) productValidated:(NSString*)productIdentifier
{
    //Loop through all validated productsr
    for (SKProduct *product in _validatedProducts)
    {
        //Return YES if product with productIdentifier exists
        if ([product.productIdentifier isEqualToString:productIdentifier])
        {
            return YES;
        }
    }
    //..Else return NO
    return NO;
}

-(ABStoreKitItem*) storeKitItemForProductIdentifier:(NSString*)productIdentifier
{
    for (ABStoreKitItem *item in self.storeKitItems)
    {
        if ([item.productIdentifier isEqualToString:productIdentifier])
        {
            return item;
        }
    }
    return nil;
}



#pragma mark - Purchase
-(void) purchaseProduct:(NSString*)productIdentifier block:(ABStoreKitBlock)block
{
    //Check if user is allowed to make payments (e.g. Parental Settings)
    if (![SKPaymentQueue canMakePayments])
    {
        //Execute block
        block(productIdentifier, NO, ABStoreKitErrorPurchaseNotAllowed);
        
        return;
    }
    
    //Make sure product about to be purchased has been validated
    if ([self productValidated:productIdentifier])
    {
        SKProduct *productToBuy;
        for (SKProduct *product in _validatedProducts)
        {
            if ([product.productIdentifier isEqualToString:productIdentifier])
            {
                productToBuy = product;
            }
        }
        
        //Add Block to block dictionary
        [_blockDictionary setObject:[block copy] forKey:productIdentifier];
        
        //Purchase request
        SKPayment *payment = [SKPayment paymentWithProduct:productToBuy];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
    else
    {
        //Execute block
        block(productIdentifier, NO, ABStoreKitErrorProductNotValidated);
    }
    
}



#pragma mark - Restore
-(void) restorePurchases:(ABStoreKitRestoreBlock)block
{
    //Add Block to block dictionary
    [_blockDictionary setObject:[block copy] forKey:@"ABStorekitHelper.restoreBlock"];
    
    //Start restore request
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}



#pragma mark - SKProductsRequestDelegate
-(void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    //Add returned SKProduct's to validatedProducts set
    for (SKProduct *product in response.products)
    {
        [_validatedProducts addObject:product];
    }
    
    //Log
    for (NSString *productIdentifier in _productIdentifiers)
    {
        if ([self productValidated:productIdentifier])
        {
            if(ABSKH_LOG) NSLog(@"ABStoreKitHelper: ProductIdentifier: %@ is Valid!", productIdentifier);
        }
        else
        {
            if(ABSKH_LOG) NSLog(@"ABStoreKitHelper: ProductIdentifier: %@ is NOT Valid!", productIdentifier);
        }
    }
}



#pragma mark SKPaymentTransactionObserver Methods
-(void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        NSString *transactionUpdate;
        
        switch (transaction.transactionState)
        {
                //FAILED
            case SKPaymentTransactionStateFailed:
            {
                transactionUpdate = @"FAILED.";
                [queue finishTransaction:transaction];
                //Execute block
                ABStoreKitBlock block = [_blockDictionary objectForKey:transaction.payment.productIdentifier];
                if (block)
                {
                    block(transaction.payment.productIdentifier, NO, ABStoreKitErrorGeneral);
                }
                //Remove from block dictionary
                [_blockDictionary removeObjectForKey:transaction.payment.productIdentifier];
                
                break;
            }
                
                //PURCHASED
            case SKPaymentTransactionStatePurchased:
            {
                transactionUpdate = @"PURCHASED.";
                [queue finishTransaction:transaction];
                
                //Retrieve purchased ABStoreKitItem and mark as purchased
                ABStoreKitItem *item = [self storeKitItemForProductIdentifier:transaction.payment.productIdentifier];
                item.transactionIdentifier = transaction.transactionIdentifier;
                item.transactionDate = transaction.transactionDate;
                [self saveStoreKitItem:item];
                
                //Execute block
                ABStoreKitBlock block = [_blockDictionary objectForKey:transaction.payment.productIdentifier];
                if (block)
                {
                    block(transaction.payment.productIdentifier, YES, ABStoreKitErrorNone);
                }
                //Remove from block dictionary
                [_blockDictionary removeObjectForKey:transaction.payment.productIdentifier];
                
                break;
            }
                
                //PURCHASING
            case SKPaymentTransactionStatePurchasing:
            {
                transactionUpdate = @"PURCHASING...";
                break;
            }
                
                //RESTORED
            case SKPaymentTransactionStateRestored:
            {
                transactionUpdate = @"RESTORING...";
                [queue finishTransaction:transaction];
                break;
            }
                
                //DEFAULT
            default:
            {
                break;
            }
        }
        
        if(ABSKH_LOG) NSLog(@"ABStoreKitHelper: TransactionState -> %@ (%@)", transaction.payment.productIdentifier, transactionUpdate);
    }
    
}

-(void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue*) queue
{
    //Retrieve restoreBlock
    ABStoreKitRestoreBlock block = [_blockDictionary objectForKey:@"ABStorekitHelper.restoreBlock"];
    
    //No products to restore
    if (!queue.transactions || [queue.transactions count] == 0)
    {
        //Execute block
        if (block)
        {
            block(nil, NO, ABStoreKitErrorNone);
        }
    }
    //Products
    else
    {
        for (SKPaymentTransaction *transaction in queue.transactions)
        {
            if (transaction.transactionState == SKPaymentTransactionStateRestored || transaction.transactionState == SKPaymentTransactionStatePurchased)
            {
                //Retrieve ABStoreKitItem from storeKitItems set
                ABStoreKitItem *item = [self storeKitItemForProductIdentifier:transaction.payment.productIdentifier];
                //Append Transaction Date / Id
                item.transactionIdentifier = transaction.transactionIdentifier;
                item.transactionDate = transaction.transactionDate;
                //Mark as purchased / restored by saving
                [self saveStoreKitItem:item];
                
                //NSData *transactionReciept = transaction.transactionReceipt;
                //NSString *recieptString = [[NSString alloc] initWithData:transactionReciept encoding:NSUTF8StringEncoding];
            }
        }
        
        //Execute block
        if (block)
        {
            block([self loadStoreKitItemArray], YES, ABStoreKitErrorNone);
        }
    }
    
    //Remove block from block dictionary
    [_blockDictionary removeObjectForKey:@"ABStorekitHelper.restoreBlock"];
    
    if(ABSKH_LOG) NSLog(@"ABStoreKitHelper: TransactionState -> RESTORE DONE.");
}

-(void) paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    //Execute block
    ABStoreKitRestoreBlock block = [_blockDictionary objectForKey:@"ABStorekitHelper.restoreBlock"];
    if (block)
    {
        block(nil, NO, ABStoreKitErrorGeneral);
    }
}

-(void) paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    //NSLog(@"ABStoreKitHelper: Removed Transactions from Payment Queue");
}



#pragma mark - Data Persistence
-(void) saveStoreKitItem:(ABStoreKitItem*)storeKitItem
{
    NSMutableArray *tempItemArray = [NSMutableArray arrayWithArray:[self loadStoreKitItemArray]];
    if (tempItemArray == nil) {
        tempItemArray = [NSMutableArray new];
    }
    
    //Determine whether ABStoreKitItem with the same transaction identifier was already saved
    BOOL itemAlreadySaved = NO;
    for (ABStoreKitItem *savedItem in tempItemArray)
    {
        if ([savedItem.transactionIdentifier isEqualToString:storeKitItem.transactionIdentifier])
        {
            itemAlreadySaved = YES;
        }
    }
    
    //Only save if ABStoreKitItem wasn't already saved
    if (!itemAlreadySaved)
    {
        [tempItemArray addObject:storeKitItem];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:tempItemArray];
        [ABSaveSystem saveData:data key:@"ABStorekitHelper.storeKitItemArray" encryption:YES];
    }
}

-(NSArray*) loadStoreKitItemArray
{
    NSData *data = [ABSaveSystem dataForKey:@"ABStorekitHelper.storeKitItemArray" encryption:YES];
    if (data != nil)
    {
        NSArray *tempItemArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        return tempItemArray;
    }
    return nil;
}



#pragma mark - Accessors
-(void) setStoreKitItems:(NSSet*) storeKitItems
{
    _storeKitItems = storeKitItems;
    
    //Populate productIdentifiers Set with product identifiers from items
    for (ABStoreKitItem *item in _storeKitItems)
    {
        if (![_productIdentifiers containsObject:item.productIdentifier])
        {
            [_productIdentifiers addObject:item.productIdentifier];
        }
        
    }
    
    //Request product data from appel servers
    if (_productIdentifiers.count != 0)
    {
        [self getNewProductData];
    }
}

@end
