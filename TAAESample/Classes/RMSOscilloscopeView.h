//
//  RMSOscilloscopeView.h
//  TAAESample
//
//  Created by 32BT on 17/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_IOS
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#define NSView 		UIView
#define NSColor 	UIColor
#define NSBezierPath UIBezierPath
#define NSRect 		CGRect
#define NSRectFill 	UIRectFill
#define NSFrameRect UIRectFrame
#endif

// define number of points on samplePath
#define kRMSOscilloscopeCount 256


@interface RMSOscilloscopeView : NSView

@property (nonatomic, assign) int gain;

@property (nonatomic) NSData *pathL;
@property (nonatomic) NSData *pathR;

@end
