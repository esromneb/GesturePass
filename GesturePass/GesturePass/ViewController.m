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

#define XDIR (0x1)
#define YDIR (0x2)
#define ZDIR (0x4)

#define SAMPS_PER_SEC (50)
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
//    
//    [self purgeAll];
//    
//    [self dloadFromString:@"[[-0.1491546630859375,0.0045166015625,-1.002761840820312],[-0.074981689453125,-0.031463623046875,-1.007522583007812],[-0.1234130859375,-0.0959930419921875,-0.996978759765625],[-0.0950927734375,-0.0718994140625,-1.06475830078125],[0.0121307373046875,-0.0360870361328125,-1.011520385742188],[0.0989837646484375,-0.011505126953125,-1.017120361328125],[0.0713958740234375,-0.0031890869140625,-0.9982147216796875],[0.1243896484375,-0.0173797607421875,-0.9828338623046875],[-0.009521484375,-0.0137786865234375,-0.99188232421875],[0.0247344970703125,0.0011138916015625,-0.994384765625],[0.0088043212890625,-0.037017822265625,-0.99774169921875],[0.007232666015625,-0.041595458984375,-0.9970245361328125],[0.0104827880859375,-0.0368194580078125,-0.996551513671875]]"];
//    
//    [self detectXWithStart:0 end:[xa count]];
////    [self dprintWithStart:0 end:[xa count]];
//    
//    
//    int wait = 999;
//    while(wait--)
//    {
//        int a = wait*2;
//    }
//
//    NSLog(@"aaa\n\n\n");
//    exit(0);
    
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
//    NSLog(@"x: %f", data.x);
}

#define POSNEG(x) (x>=0)?@"positive":@"negative"

-(int) windowWithStart:(int)start end:(int)end
{
    int xdetect, ydetect, zdetect;
    
    xdetect = [self detectWithStart:start end:end dir:XDIR];
    ydetect = [self detectWithStart:start end:end dir:YDIR];
    zdetect = [self detectWithStart:start end:end dir:ZDIR];
    
    if( xdetect != 0 )
    {
        NSLog(@"detect %@ x gesture\n", POSNEG(xdetect) );
        return XDIR;
    }
    
    if( ydetect != 0 )
    {
        NSLog(@"detect %@ y gesture\n", POSNEG(ydetect) );
        return YDIR;
    }
    
    if( zdetect != 0 )
    {
        NSLog(@"detect %@ z gesture\n", POSNEG(zdetect) );
        return ZDIR;
    }
    
    if( ((int)(xdetect != 0) + (int)(ydetect != 0) + (int)(zdetect != 0)) > 1 )
        NSLog(@"ZOMG multiple directions detected!!!!!");
    
    return ZDIR;
}

-(void) parseData
{
    bool gcopy = gestureHappening;
    
    [self isResting];
    
    // if we just started resting after a gesture
    if( gcopy != gestureHappening && gestureHappening == false)
    {
//        NSLog(@"END of gesture with lenght %d\n", [xa count] - gestureBegin );
//        self dprint:][xa count] - gestureBegin, [xa count]-1);
//        [self dprintWithStart:gestureBegin end:[xa count]-1];
        
        
        int end = ([xa count]-1);
        
        int num = end - gestureBegin;
        int start = 0;
        
        int windowSize = 12;
        
        int xcount, zcount, ycount;
        xcount = ycount = zcount = 0;
        
        for( int i = 0; (i+1)*windowSize  < num; i++ )
        {
            
            start = gestureBegin + i*windowSize;
            
            int result = [self windowWithStart:start end:start+windowSize];

            if( result == XDIR )
                xcount++;
            
            if( result == YDIR )
                ycount++;
            
            if( result == ZDIR )
                zcount++;
        }
        
        
        NSString* hash;
        
//        hash = [self sha1UTF8Encoding:true andDecima:true andString:@"x"];
        
        if( xcount > ycount && xcount > zcount )
        {
            NSLog(@"x");
            hash = @"x";
        }
        
        if( ycount > zcount && ycount > xcount )
        {
            NSLog(@"y");
            hash = @"y";
        }
        
        if( zcount > ycount && zcount > xcount )
        {
            NSLog(@"z");
            hash = @"z";
        }
        
        
        hash = [self sha1UTF8Encoding:YES andDecimal:NO andString:hash];
        NSLog(@"%@", hash);
        
        
        NSLog(@"entering rest with %d samples", num);
    }
    
    if( gcopy != gestureHappening && gcopy == false)
        NSLog(@"leaving rest");
}


//- (NSString*) hashIt:(NSString*)it
//{
//    // Create an SHA1 instance, update it with a string and do final.
//    SHA1 sha1 = [SHA1 sha1WithString:it];
//    
//    // Get the pointer of the internal buffer that holds the message digest value.
//    // The life of the internal buffer ends when the SHA1 instance is discarded.
//    // Copy the buffer as necessary. The size of the buffer can be obtained by
//    // 'bufferSize' method.
//    unsigned char *digestAsBytes = [sha1 buffer];
//    
//    // Get the string expression of the message digest value.
//    NSString *digestAsString = [sha1 description];
//}


#define CC_SHA1_DIGEST_LENGTH (20)

- (NSString*) sha1UTF8Encoding:(BOOL)utf8 andDecimal:(BOOL)decimal andString:(NSString*)s
{
    const char *cstr;
    if (utf8) {
        cstr = [s cStringUsingEncoding:NSUTF8StringEncoding];
    }else{
        cstr = [s cStringUsingEncoding:NSUnicodeStringEncoding];
    }
    NSData *data = [NSData dataWithBytes:cstr length:s.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++){
        if (decimal) {
            [output appendFormat:@"%i", digest[i]];
        }else{
            [output appendFormat:@"%02x", digest[i]];
        }
    }
    
    return output;
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

// function for normalizing gravity
// http://stackoverflow.com/questions/3377288/how-to-remove-gravity-factor-from-accelerometer-readings-in-android-3-axis-accel
#define UPDATE_G(g,v) g = 0.9 * g + 0.1 * v;

- (int) detectWithStart:(int)start end:(int)end dir:(int)dir
{
    double signalTol = 0;
    double tolRadio = 1.01;
    
    // cumulitive
    double cx,cy,cz;
    
    // direction
    double posneg = 0;
    
    cx = cy = cz = 0;
    
    bool detect = false;
    
    
    double xprev, yprev, zprev;
    
    for( int i = start; i < end; i++ )
    {
        double x = [[xa objectAtIndex:i] doubleValue];
        double y = [[ya objectAtIndex:i] doubleValue];
        double z = [[za objectAtIndex:i] doubleValue];
        
        if( i != start )
        {
            switch( dir )
            {
                case XDIR:
                    posneg += (x - xprev);
                    break;
                case YDIR:
                    posneg += (y - yprev);
                    break;
                default:
                case ZDIR:
                    posneg += (z - zprev);
                    break;
            }
            
            cx += fabs(x - xprev);
            cy += fabs(y - yprev);
            cz += fabs(z - zprev);
            
//            NSLog(@"sum: %f %f %f\n", cx, cy, cz);
//            NSLog(@"rat: %f %f %f\n", cx/cy, cx/cz, 0.0);
        }
        
        xprev = x;
        yprev = y;
        zprev = z;
    }
//    if( dir == XDIR )
//    {
//
//    NSLog(@"\nr1: %d \nr2: %d \ncx: %d",(cx/cy > tolRadio),(cx/cz > tolRadio), (cx > signalTol));
//        
//    }
    
    
    switch( dir )
    {
        case XDIR:
            detect = (cx/cy > tolRadio && cx/cz > tolRadio && cx > signalTol);
            break;
        case YDIR:
            detect = (cy/cx > tolRadio && cy/cz > tolRadio && cy > signalTol);
            break;
        default:
        case ZDIR:
            detect = (cz/cx > tolRadio && cz/cy > tolRadio && cz > signalTol);
            break;
    }
    
    if( detect && posneg >= 0.0 )
        return 1;
    
    if( detect && posneg < 0.0 )
        return -1;
    
    return 0;
}

- (void) isResting
{
    //
    double tol = 0.04;
    
    // is resting
    bool flag = true;
    
    int samples = (SAMPS_PER_SEC*2.0/3);
    
    int restSamples = SAMPS_PER_SEC/2;
    
    int end = ([xa count]-1);
    
    int restCount = 0;
    
    // loop for N samples but be careful not to underflow array
    for( int i = end; i >= 0 && (end - i) < samples ; i-- )
    {
        if( i == end ) continue;
        if( (i - 1) < 0 ) continue; // edge condition on boot
        
        

        
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
                gestureBegin = abs(i);
            
            flag = false;
            gestureHappening = !flag;
            break;
        }
        else
        {
            restCount += 2;
        }
        
        if( restCount > restSamples )
        {
            gestureHappening = false;
            break;
        }
        
        
        
        
        
        restCount--;
    }
    
//    if( flag )
//        NSLog(@"resting");
    
    // set into resting
//    gestureHappening = false;
    
//    gestureHappening = !flag;
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
