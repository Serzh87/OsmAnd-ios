//
//  UIViewController+OARootVC.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OARootViewController.h"

@interface UIViewController (OARootVC)

@property (nonatomic, weak, readonly) OARootViewController *rootViewController;

@end
