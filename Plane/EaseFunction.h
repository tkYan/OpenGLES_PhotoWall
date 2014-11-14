//
//  EaseFunction.h
//  Plane
//
//  Created by Peng, Yan on 4/17/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import <Foundation/Foundation.h>

#define Linear  @"Linear"
#define Bounce  @"Bounce"
#define Elastic @"Elastic"
#define Expo    @"Expo"

#define SELECTED_MOVE_Z 0.5

@interface EaseFunction : NSObject

@property (nonatomic) NSString *tag;
@property (nonatomic) GLfloat totalTime;

- (GLfloat)getOffsetFromEaseFunctionWithCurrentTIme:(GLfloat)currentTime
                                         startValue:(GLfloat)startValue
                                           endValue:(GLfloat)endValue;

@end
