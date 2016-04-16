//
//  AEObserverStack.h
//  TAAESample
//
//  Created by 32BT on 13/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

// IGNORE! sketch only

#import <Foundation/Foundation.h>

@protocol AEObserverStackDelegateProtocol
- (BOOL) observerStack:(id)stack willAddObserver:(id)observer;
- (void) observerStack:(id)stack didUpdateObserver:(id)observer;
@end

@interface AEObserverStack : NSObject
@property (nonatomic, weak) id delegate;
@property (nonatomic, assign) SEL updateSelector;
@end
