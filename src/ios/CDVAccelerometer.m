/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVAccelerometer.h"
#import <CoreMotion/CoreMotion.h>
@interface CDVAccelerometer () {}
@property (readwrite, assign) BOOL isRunning;
@property (readwrite, assign) BOOL haveReturnedResult;
@property (readwrite, assign) double x;
@property (readwrite, assign) double y;
@property (readwrite, assign) double z;
@property (readwrite, assign) int pas;
@property (readwrite, assign) NSTimeInterval timestamp;
@end

@implementation CDVAccelerometer

@synthesize callbackId, isRunning,x,y,z,timestamp;

// defaults to 10 msec
#define kAccelerometerInterval 10
// g constant: -9.81 m/s^2
#define kGravitationalConstant -9.81
NSMutableArray *accelerations;
NSTimer *timer;
- (CDVAccelerometer*)init
{
    self = [super init];
    if (self) {
        self.x = 0;
        self.y = 0;
        self.z = 0;
        self.pas=0;
        self.timestamp = 0;
        self.callbackId = nil;
        self.isRunning = NO;
        self.haveReturnedResult = YES;
    }
    return self;
}



int pas = 0;
CMMotionManager* motionManager;

- (void)dealloc
{
    [self stop:nil];
    [timer invalidate];
    timer=nil;
    pas=0;
}

- (void)start:(CDVInvokedUrlCommand*)command
{
    pas=0;
    motionManager = [[CMMotionManager alloc] init];
    [motionManager setAccelerometerUpdateInterval:0.011f];
    [motionManager startAccelerometerUpdates];
    accelerations = [NSMutableArray arrayWithObjects: @"0",  nil];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.011f target:self selector:@selector(timerCalled) userInfo:nil repeats:YES];
    self.haveReturnedResult = NO;
    self.callbackId = command.callbackId;
}

- (void)onReset
{
    [self stop:nil];
    [timer invalidate];
    timer=nil;
    pas=0;
}

-(void)timerCalled
{
    pas+=10;
    if (pas <= 5180)
    {
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970]*1000;
        CMAccelerometerData* data = [motionManager accelerometerData];
        // Create an acceleration object
        NSMutableDictionary* accelProps = [NSMutableDictionary dictionaryWithCapacity:4];
        
        [accelProps setValue:[NSNumber numberWithDouble:fabs(data.acceleration.x * kGravitationalConstant)] forKey:@"x"];
        [accelProps setValue:[NSNumber numberWithDouble:fabs( data.acceleration.y * kGravitationalConstant)] forKey:@"y"];
        [accelProps setValue:[NSNumber numberWithDouble:fabs(data.acceleration.z * kGravitationalConstant)] forKey:@"z"];
        [accelProps setValue:[NSNumber numberWithInt:pas] forKey:@"pas"];
        [accelProps setValue:[NSNumber numberWithDouble:timestamp] forKey:@"timestamp"];
        [accelerations addObject: [NSNumber numberWithFloat:data.acceleration.z]];
        
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:accelerations];
        [result setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
        self.haveReturnedResult = YES;
    }
    if (pas > 5180)
    {
        [timer invalidate];
        timer=nil;
    }
        
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    //self.testAccel.delegate=nil;
    self.isRunning = NO;
}



// TODO: Consider using filtering to isolate instantaneous data vs. gravity data -jm

/*
 #define kFilteringFactor 0.1
 
 // Use a basic low-pass filter to keep only the gravity component of each axis.
 grav_accelX = (acceleration.x * kFilteringFactor) + ( grav_accelX * (1.0 - kFilteringFactor));
 grav_accelY = (acceleration.y * kFilteringFactor) + ( grav_accelY * (1.0 - kFilteringFactor));
 grav_accelZ = (acceleration.z * kFilteringFactor) + ( grav_accelZ * (1.0 - kFilteringFactor));
 
 // Subtract the low-pass value from the current value to get a simplified high-pass filter
 instant_accelX = acceleration.x - ( (acceleration.x * kFilteringFactor) + (instant_accelX * (1.0 - kFilteringFactor)) );
 instant_accelY = acceleration.y - ( (acceleration.y * kFilteringFactor) + (instant_accelY * (1.0 - kFilteringFactor)) );
 instant_accelZ = acceleration.z - ( (acceleration.z * kFilteringFactor) + (instant_accelZ * (1.0 - kFilteringFactor)) );
 
 
 */
@end
