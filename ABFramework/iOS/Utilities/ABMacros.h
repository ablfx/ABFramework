//
//  ABMacros.h
//  ABFramework
//
//  Created by Alexander Blunck on 1/12/13.
//  Copyright (c) 2013 Ablfx. All rights reserved.
//

/*
 * DEVICE
 */
//Returns YES on retina display
#define IS_RETINA_DISPLAY [[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0f
//Returns YES on 4 inch display
#define IS_4_INCH ([[UIScreen mainScreen] applicationFrame].size.height > 480)
//Returns YES on device running iOS 6.0+
#define IS_MIN_IOS6 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0f)
//Returns YES on iPad
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)



/*
 * LOGGING
 */
#define ABLogNSString(string) NSLog(@"ABLogNSString -> %s = \"%@\"", #string, string)
#define ABLogCGRect(rect) NSLog(@"ABLogCGRect -> %s = %@", #rect, NSStringFromCGRect(rect))
#define ABLogCGSize(size) NSLog(@"ABLogCGSize -> %s = %@", #size, NSStringFromCGSize(size))
#define ABLogBOOL(bool) NSLog(@"ABLogBOOL -> %s = %@", #bool, (bool) ? @"YES" : @"NO")
#define ABLogInteger(integer) NSLog(@"ABLogInteger -> %s = %i", #integer, integer)
#define ABLogDouble(double) NSLog(@"ABLogDouble -> %s = %f", #double, double)
#define ABLogFloat(float) NSLog(@"ABLogFloat -> %s = %f", #float, float)
#define ABLogLong(long) NSLog(@"ABLogFloat -> %s = %lu", #long, long)
#define ABLogLongLong(longLong) NSLog(@"ABLogFloat -> %s = %llu", #longLong, longLong)
#define ABLogMethod() NSLog(@"%s", __PRETTY_FUNCTION__)