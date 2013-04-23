//
//  ABNavigationController.h
//  ABFramework
//
//  Created by Alexander Blunck on 9/7/12.
//  Copyright (c) 2012 Ablfx. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ABNavigationController : UINavigationController

@property (nonatomic, weak) ABTabBarItem *abTabBarItem;
@property (nonatomic, weak) ABTabBarController *abTabBarController;

@end
