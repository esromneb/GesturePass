//
//  ViewController.m
//  GesturePass
//
//  Created by Daniel Richards on 9/28/13.
//  Copyright (c) 2013 Daniel Richards. All rights reserved.
//

#import "ViewController.h"
#import "NSMutableArray+QueueAdditions.h"

@interface ViewController ()

@end

@implementation ViewController

NSMutableArray* xa;
NSMutableArray* ya;
NSMutableArray* za;


#define SAMPS_PER_SEC (10)
#define TIME_PER_SAMP (1.0/SAMPS_PER_SEC)

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) viewDidLoad {
//    // Request to turn on accelerometer and begin receiving accelerometer events
//    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    
    [super viewDidLoad];
    
    
    xa = [[NSMutableArray alloc] init];
    ya = [[NSMutableArray alloc] init];
    za = [[NSMutableArray alloc] init];
    
    
    // Do any additional setup after loading the view, typically from a nib.
    currentMaxAccelX = 0;
    currentMaxAccelY = 0;
    currentMaxAccelZ = 0;
    
    currentMaxRotX = 0;
    currentMaxRotY = 0;
    currentMaxRotZ = 0;
    
    NSLog(@"Sample every %f", TIME_PER_SAMP );
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = TIME_PER_SAMP;
    self.motionManager.gyroUpdateInterval = TIME_PER_SAMP;
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 [self queueData:accelerometerData.acceleration];
                                                 [self outputAccelertionData:accelerometerData.acceleration];
                                                 
                                                 [self parseData];
                                                 [self rollBuffer];
                                                 
                                                 if(error){
                                                     
                                                     NSLog(@"%@", error);
                                                 }
                                             }];
    
    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                                    withHandler:^(CMGyroData *gyroData, NSError *error) {
                                        [self outputRotationData:gyroData.rotationRate];
                                    }];
    

    
}

-(void) purgeArray:(NSMutableArray*)array
{
//    NSMutableArray *array = [[rows objectForKey:self.company.coaTypeCode] objectForKey:statementType];
    [[array copy] enumerateObjectsWithOptions: NSEnumerationReverse
                                   usingBlock:^(id coaItem, NSUInteger idx, BOOL *stop) {
                                           [array removeObjectAtIndex:idx];
                                   }];
}

- (void) purgeAll
{
    [self purgeArray:xa];
    [self purgeArray:ya];
    [self purgeArray:za];
}

- (void) rollBuffer
{
    
    // buffer for 1 second
    
    while( [xa count] > SAMPS_PER_SEC )
    {
        [xa dequeue];
        [ya dequeue];
        [za dequeue];
    }
}


-(void)queueData:(CMAcceleration)data
{
    [xa enqueue:[NSNumber numberWithDouble:data.x]];
    [ya enqueue:[NSNumber numberWithDouble:data.y]];
    [za enqueue:[NSNumber numberWithDouble:data.z]];
}

-(void) parseData
{
    [self isResting];
}

- (void) isResting
{
    //
    double tol = 0.06;
    
    bool flag = true;
    
    int samples = (SAMPS_PER_SEC/2);
    
    int end = ([xa count]-1);
    
    // loop for N samples but be careful not to underflow array
    for( int i = end; i >= 0 && (end - i) < samples ; i-- )
    {
        if( i == 0 ) continue;
        
        
        double x = [[xa objectAtIndex:i] doubleValue];
        double xprev = [[xa objectAtIndex:(i-1)] doubleValue];
        double y = [[ya objectAtIndex:i] doubleValue];
        double yprev = [[ya objectAtIndex:(i-1)] doubleValue];
        double z = [[za objectAtIndex:i] doubleValue];
        double zprev = [[za objectAtIndex:(i-1)] doubleValue];
        
        
//        NSLog(@"%d - %@\n", i, [xa objectAtIndex:i]);
        
        if( (fabs(x - xprev) > tol) || (fabs(y - yprev) > tol) || (fabs(z - zprev) > tol))
        {
            NSLog(@"not resting at sample %d\n", i);
            flag = false;
            break;
        }
    }
    
    if( flag )
        NSLog(@"resting");
}

- (IBAction)buttonOne:(id)sender
{
    
    NSLog(@"hi");
    NSEnumerator *arrenum = [xa objectEnumerator];
    id cobj;
    while ( cobj = [arrenum nextObject] ) {
        NSLog(@"%@", cobj);
    }
    
//    [self purgeArray:xa];
    [self purgeAll];
    
}



-(void)outputAccelertionData:(CMAcceleration)acceleration
{
    
    
    
    self.accX.text = [NSString stringWithFormat:@" %.2fg",acceleration.x];
    if(fabs(acceleration.x) > fabs(currentMaxAccelX))
    {
        currentMaxAccelX = acceleration.x;
    }
    self.accY.text = [NSString stringWithFormat:@" %.2fg",acceleration.y];
    if(fabs(acceleration.y) > fabs(currentMaxAccelY))
    {
        currentMaxAccelY = acceleration.y;
    }
    self.accZ.text = [NSString stringWithFormat:@" %.2fg",acceleration.z];
    if(fabs(acceleration.z) > fabs(currentMaxAccelZ))
    {
        currentMaxAccelZ = acceleration.z;
    }
    
    self.maxAccX.text = [NSString stringWithFormat:@" %.2f",currentMaxAccelX];
    self.maxAccY.text = [NSString stringWithFormat:@" %.2f",currentMaxAccelY];
    self.maxAccZ.text = [NSString stringWithFormat:@" %.2f",currentMaxAccelZ];
    
    
}
-(void)outputRotationData:(CMRotationRate)rotation
{
    
    self.rotX.text = [NSString stringWithFormat:@" %.2fr/s",rotation.x];
    if(fabs(rotation.x) > fabs(currentMaxRotX))
    {
        currentMaxRotX = rotation.x;
    }
    self.rotY.text = [NSString stringWithFormat:@" %.2fr/s",rotation.y];
    if(fabs(rotation.y) > fabs(currentMaxRotY))
    {
        currentMaxRotY = rotation.y;
    }
    self.rotZ.text = [NSString stringWithFormat:@" %.2fr/s",rotation.z];
    if(fabs(rotation.z) > fabs(currentMaxRotZ))
    {
        currentMaxRotZ = rotation.z;
    }
    
    self.maxRotX.text = [NSString stringWithFormat:@" %.2f",currentMaxRotX];
    self.maxRotY.text = [NSString stringWithFormat:@" %.2f",currentMaxRotY];
    self.maxRotZ.text = [NSString stringWithFormat:@" %.2f",currentMaxRotZ];
}





- (void)orientationChanged:(NSNotification *)notification {
    // Respond to changes in device orientation
}

-(void) viewDidDisappear {
    // Request to stop receiving accelerometer events and turn off accelerometer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

//For another example of responding to UIDevice orientation changes, see the AlternateViews sample code project.




// respond to motion

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake)
    {
        // User was shaking the device. Post a notification named "shake."
        [[NSNotificationCenter defaultCenter] postNotificationName:@"shake" object:self];
        
        NSLog(@"shake");
    }
}





@end
