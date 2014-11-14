//
//  EaseFunction.m
//  Plane
//
//  Created by Peng, Yan on 4/17/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import "EaseFunction.h"


@implementation EaseFunction{
    NSString *tag;
    GLfloat  totalTime;
}

@synthesize tag = _tag;
@synthesize totalTime;

- (GLfloat)getOffsetFromEaseFunctionWithCurrentTIme:(GLfloat)currentTime
                                         startValue:(GLfloat)startValue
                                           endValue:(GLfloat)endValue
{
    if ([_tag  isEqual: Linear]) {
        return easeInOutLinear(currentTime,startValue,endValue,totalTime);
    }else if ([_tag  isEqual: Bounce]) {
        return easeInOutBounce(currentTime,startValue,endValue,totalTime);
    }else if ([_tag  isEqual: Elastic]) {
        return easeInOutElastic(currentTime,startValue,endValue,totalTime);
    }else if ([_tag  isEqual: Expo]) {
        return easeInOutExpo(currentTime,startValue,endValue,totalTime);
    }
    
    NSLog(@"tag can not be recongnized!");
    assert(0);
    return 0;
}

#pragma mark - ease function

//Linear
float easeInOutLinear(float t,float b , float c, float d) {
	return c*t/d + b;
}

//Bounce
float easeInBounce(float t,float b , float c, float d) {
	return c - easeOutBounce(d-t, 0, c, d) + b;
}
float easeOutBounce(float t,float b , float c, float d) {
	if ((t/=d) < (1/2.75f)) {
		return c*(7.5625f*t*t) + b;
	} else if (t < (2/2.75f)) {
		float postFix = t-=(1.5f/2.75f);
		return c*(7.5625f*(postFix)*t + .75f) + b;
	} else if (t < (2.5/2.75)) {
        float postFix = t-=(2.25f/2.75f);
		return c*(7.5625f*(postFix)*t + .9375f) + b;
	} else {
		float postFix = t-=(2.625f/2.75f);
		return c*(7.5625f*(postFix)*t + .984375f) + b;
	}
}

float easeInOutBounce(float t,float b , float c, float d) {
	if (t < d/2) return easeInBounce (t*2, 0, c, d) * .5f + b;
	else return easeOutBounce (t*2-d, 0, c, d) * .5f + c*.5f + b;
}

//Elastic
float easeInOutElastic(float t,float b , float c, float d) {
	if (t==0) return b;  if ((t/=d/2)==2) return b+c;
	float p=d*(.3f*1.5f);
	float a=c;
	float s=p/4;
    
	if (t < 1) {
		float postFix =a*pow(2,10*(t-=1)); // postIncrement is evil
		return -.5f*(postFix* sin( (t*d-s)*(2*M_PI)/p )) + b;
	}
	float postFix =  a*pow(2,-10*(t-=1)); // postIncrement is evil
	return postFix * sin( (t*d-s)*(2*M_PI)/p )*.5f + c + b;
}

//Expo
float easeInOutExpo(float t,float b , float c, float d) {
	if (t==0) return b;
	if (t==d) return b+c;
	if ((t/=d/2) < 1) return c/2 * pow(2, 10 * (t - 1)) + b;
	return c/2 * (-pow(2, -10 * --t) + 2) + b;
}

@end

