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
bool gestureHappening;
int gestureBegin;


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
    gestureHappening = false;
    gestureBegin = -1;
    
    
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
    
    [self purgeAll];
    
    [self dloadFromString:@"[[-0.1491546630859375,0.0045166015625,-1.002761840820312],[-0.074981689453125,-0.031463623046875,-1.007522583007812],[-0.1234130859375,-0.0959930419921875,-0.996978759765625],[-0.0950927734375,-0.0718994140625,-1.06475830078125],[0.0121307373046875,-0.0360870361328125,-1.011520385742188],[0.0989837646484375,-0.011505126953125,-1.017120361328125],[0.0713958740234375,-0.0031890869140625,-0.9982147216796875],[0.1243896484375,-0.0173797607421875,-0.9828338623046875],[-0.009521484375,-0.0137786865234375,-0.99188232421875],[0.0247344970703125,0.0011138916015625,-0.994384765625],[0.0088043212890625,-0.037017822265625,-0.99774169921875],[0.007232666015625,-0.041595458984375,-0.9970245361328125],[0.0104827880859375,-0.0368194580078125,-0.996551513671875]]"];
    
    
    
    [self dprintWithStart:0 end:[xa count]];
    
    
    exit(0);
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 [self queueData:accelerometerData.acceleration];
                                                 [self outputAccelertionData:accelerometerData.acceleration];
                                                 
                                                 [self parseData];
                                                 
                                                 // only roll buffer if not gesturing, this allows us to index correctly
                                                 if( !gestureHappening )
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
    // buffer for 30 second
    
    while( [xa count] > SAMPS_PER_SEC*30 )
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
    bool gcopy = gestureHappening;
    
    [self isResting];
    
    if( gcopy != gestureHappening && gestureHappening == false)
    {
        NSLog(@"END of gesture with lenght %d\n", [xa count] - gestureBegin );
//        self dprint:][xa count] - gestureBegin, [xa count]-1);
        [self dprintWithStart:gestureBegin end:[xa count]-1];
    }
}

- (void) dprintWithStart:(int)start end:(int)end
{
    
    NSMutableArray* print = [[NSMutableArray alloc] init];
    
    
    for( int i = start; i < end; i++ )
    {
        double x = [[xa objectAtIndex:i] doubleValue];
        double y = [[ya objectAtIndex:i] doubleValue];
        double z = [[za objectAtIndex:i] doubleValue];
        
        NSLog(@"%f %f %f\n", x, y, z);
        
        NSMutableArray* row = [[NSMutableArray alloc] init];
        
        [row enqueue:[xa objectAtIndex:i]];
                [row enqueue:[ya objectAtIndex:i]];
                [row enqueue:[za objectAtIndex:i]];
        
        
        [print enqueue:row];
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:print options:NSJSONWritingPrettyPrinted error:NULL];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@", jsonString );
}

- (void) dloadFromString:(NSString*)s
{
    NSArray *loaded =  [NSJSONSerialization
                                      JSONObjectWithData:[s dataUsingEncoding:NSUTF8StringEncoding]
                                      options:kNilOptions
                                      error:NULL];
    
    for( int i = 0; i < [loaded count]; i++ )
    {
        NSArray* row = [loaded objectAtIndex:i];
        [xa enqueue:[row objectAtIndex:0]];
        [ya enqueue:[row objectAtIndex:1]];
        [za enqueue:[row objectAtIndex:2]];
//        [ya enqueue:[NSNumber numberWithDouble:[row objectAtIndex:1]]];
//        [za enqueue:[NSNumber numberWithDouble:[row objectAtIndex:2]] ];
    }
    
    NSLog(@"load?");
}

- (void) detectX
{
    
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
//            NSLog(@"not resting at sample %d\n", i);
            
            // only set this variable if we aren't already in a gesture
            
            if( !gestureHappening )
                gestureBegin = i;
            
            flag = false;
            break;
        }
    }
    
//    if( flag )
//        NSLog(@"resting");
    
    gestureHappening = !flag;
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
