//
//  Magnetometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Magnetometer.h"
#import "EntityMagnetometer.h"
#import "ObjectModels/AWAREMagnetometerOM+CoreDataClass.h"

NSString* const AWARE_PREFERENCES_STATUS_MAGNETOMETER = @"status_magnetometer";
NSString* const AWARE_PREFERENCES_FREQUENCY_MAGNETOMETER = @"frequency_magnetometer";
NSString* const AWARE_PREFERENCES_FREQUENCY_HZ_MAGNETOMETER = @"frequency_hz_magnetometer";

@implementation Magnetometer{
    CMMotionManager* manager;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_MAGNETOMETER];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp",@"device_id", @"double_values_0", @"double_values_1",@"double_values_2", @"accuracy",@"label"];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeInteger),@(CSVTypeText)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_MAGNETOMETER headerLabels:header headerTypes:headerTypes];
    }else{
        SQLiteStorage * sqlite = [[SQLiteStorage alloc] initWithStudy:study
                                                           sensorName:SENSOR_MAGNETOMETER
                                                           entityName:NSStringFromClass([EntityMagnetometer class])
                                                       insertCallBack:nil];
        /// use the separated database if the existing database is empty
        NSError * error = nil;
        BOOL exist = [sqlite isExistUnsyncedDataWithError:error];
        if (!exist && error==nil) {
            storage = [[SQLiteSeparatedStorage alloc] initWithStudy:study sensorName:SENSOR_MAGNETOMETER
                                                    objectModelName:NSStringFromClass([AWAREMagnetometerOM class])
                                                      syncModelName:NSStringFromClass([AWAREBatchDataOM class])
                                                          dbHandler:AWAREMagnetometerCoreDataHandler.shared];
        }else{
            if (error!=nil) {
                NSLog(@"[%@] Error: %@", [self getSensorName], error.debugDescription);
            }
            storage = sqlite;
        }
    }
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_MAGNETOMETER
                             storage:storage];
    if (self) {
        manager = [[CMMotionManager alloc] init];
    }
    return self;
}


- (void) createTable{
    // Send a table craete query
    if ([self isDebug]) {
        NSLog(@"[%@] Create table", [self getSensorName]);
    }
    NSString *query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "double_values_0 real default 0,"
    "double_values_1 real default 0,"
    "double_values_2 real default 0,"
    "accuracy integer default 0,"
    "label text default ''";
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)setParameters:(NSArray *)parameters{
    // Get and set a sensng frequency to CMMotionManager
    if (parameters != nil) {
        double frequency = [self getSensorSetting:parameters withKey:@"frequency_magnetometer"];
        if(frequency != -1){
            [self setSensingIntervalWithSecond:[self convertMotionSensorFrequecyFromAndroid:frequency]];
        }
        
        double tempHz = [self getSensorSetting:parameters withKey:AWARE_PREFERENCES_FREQUENCY_HZ_MAGNETOMETER];
        if(tempHz > 0){
            [self setSensingIntervalWithSecond:1.0f/tempHz];
        }
    }
}

- (BOOL)startSensorWithSensingInterval:(double)sensingInterval savingInterval:(double)savingInterval{
    
    // Set and start a sensor
    if ([self isDebug]) {
        NSLog(@"[%@] Start Mag sensor", [self getSensorName]);
    }

    [self.storage setBufferSize:savingInterval/sensingInterval];
    
    manager.magnetometerUpdateInterval = sensingInterval;
    
    [manager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                 withHandler:^(CMMagnetometerData * _Nullable magnetometerData,
                                               NSError * _Nullable error) {
                                     if( error ) {
                                         NSLog(@"%@:%zd", [error domain], [error code] );
                                     } else {
                                         
                                         if (self.threshold > 0 && [self getLatestData] !=nil &&
                                             ![self isHigherThanThresholdWithTargetValue:magnetometerData.magneticField.x lastValueKey:@"double_values_0"] &&
                                             ![self isHigherThanThresholdWithTargetValue:magnetometerData.magneticField.y lastValueKey:@"double_values_1"] &&
                                             ![self isHigherThanThresholdWithTargetValue:magnetometerData.magneticField.z lastValueKey:@"double_values_2"]
                                             ) {
                                             return;
                                         }
                                         
                                         NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                         NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                         [dict setObject:unixtime forKey:@"timestamp"];
                                         [dict setObject:[self getDeviceId] forKey:@"device_id"];
                                         [dict setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.x] forKey:@"double_values_0"];
                                         [dict setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.y] forKey:@"double_values_1"];
                                         [dict setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.z] forKey:@"double_values_2"];
                                         [dict setObject:@3 forKey:@"accuracy"];
                                         [dict setObject:@"" forKey:@"label"];
                                         [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",magnetometerData.magneticField.x, magnetometerData.magneticField.y, magnetometerData.magneticField.z]];
                                         [self setLatestData:dict];
                                     
                                         NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                                              forKey:EXTRA_DATA];
                                         [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_MAGNETOMETER
                                                                                             object:nil
                                                                                           userInfo:userInfo];
                                         [self.storage saveDataWithDictionary:dict buffer:YES saveInMainThread:NO];
                                         
                                         SensorEventHandler handler = [self getSensorEventHandler];
                                         if (handler!=nil) {
                                             handler(self, dict);
                                         }
                                     }
                                 }];

    [self setSensingState:YES];
    return YES;
}


- (BOOL)stopSensor{
    // Stop a motion sensor
    [manager stopMagnetometerUpdates];
    manager = nil;
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    [self setSensingState:NO];
    return YES;
}

@end


static AWAREMagnetometerCoreDataHandler * shared;
@implementation AWAREMagnetometerCoreDataHandler
+ (AWAREMagnetometerCoreDataHandler * _Nonnull)shared {
    @synchronized(self){
        if (!shared){
            shared =  (AWAREMagnetometerCoreDataHandler *)[[BaseCoreDataHandler alloc] initWithDBName:@"AWARE_Magnetometer"];
        }
    }
    return shared;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (shared == nil) {
            shared= [super allocWithZone:zone];
            return shared;
        }
    }
    return nil;
}

@end
