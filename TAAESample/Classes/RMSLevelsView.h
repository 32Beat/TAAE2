////////////////////////////////////////////////////////////////////////////////
/*
	RMSLevelsView.h
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

#if !TARGET_OS_IOS
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#define NSView 		UIView
#define NSColor 	UIColor
#define NSRect 		CGRect
#define NSRectFill 	UIRectFill
#endif

////////////////////////////////////////////////////////////////////////////////

// NOTE: this is not recommended!
#import "AERingBufferModule.h"


#import "rmslevels_t.h"

enum RMSViewDirection
{
	eRMSViewDirectionAuto = 0,
	eRMSViewDirectionE = 1,
	eRMSViewDirectionS = 2,
	eRMSViewDirectionW = 3,
	eRMSViewDirectionN = 4
};

@interface RMSLevelsView : NSView

@property (nonatomic) NSColor *bckColor;
@property (nonatomic) NSColor *avgColor;
@property (nonatomic) NSColor *maxColor;
@property (nonatomic) NSColor *hldColor;
@property (nonatomic) NSColor *clpColor;

@property (nonatomic, assign) NSUInteger direction;

- (void) setLevels:(rmsresult_t)result;

@end




