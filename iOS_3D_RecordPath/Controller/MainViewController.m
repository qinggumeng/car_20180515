//
//  BaseMapViewController.m
//  SearchV3Demo
//
//  Created by songjian on 13-8-14.
//  Copyright (c) 2013年 songjian. All rights reserved.
//
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>

#import "MainViewController.h"
#import "StatusView.h"
#import "TipView.h"
#import "AMapRouteRecord.h"
#import "FileHelper.h"
#import "RecordViewController.h"
#import "SystemInfoView.h"
#import "AFNetworking.h"

#define kTempTraceLocationCount 20

@interface MainViewController()<AMapGeoFenceManagerDelegate,AMapLocationManagerDelegate,MAMapViewDelegate>

@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) MATraceManager *traceManager;

@property (nonatomic, strong) StatusView *statusView;
@property (nonatomic, strong) TipView *tipView;
@property (nonatomic, strong) UIButton *locationBtn;
@property (nonatomic, strong) UIImage *imageLocated;
@property (nonatomic, strong) UIImage *imageNotLocate;
@property (nonatomic, strong) SystemInfoView *systemInfoView;

@property (nonatomic, assign) BOOL isRecording;
@property (atomic, assign) BOOL isSaving;

@property (atomic, assign) BOOL isAnyInWeiLan;

@property (nonatomic, strong) MAPolyline *polyline;

@property (nonatomic, strong) NSMutableArray *locationsArray;

@property (nonatomic, strong) AMapRouteRecord *currentRecord;
@property (nonatomic, strong) AMapGeoFenceManager *geoFenceManager;

@property (nonatomic, strong) NSMutableArray *tracedPolylines;
@property (nonatomic, strong) NSMutableArray *tempTraceLocations;
@property (nonatomic, assign) double totalTraceLength;
@property (nonatomic, assign) NSInteger locateCount;


@end


@implementation MainViewController
NSString *now;
- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode
{
    NSLog(@"记录中2...%@",reGeocode);
    NSLog(@"location:{lat:%f; lon:%f; accuracy:%f}", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
    
    self.locateCount += 1;
    
    [self updateLabelTextWithLocation:location regeocode:reGeocode];
}


- (void)updateLabelTextWithLocation:(CLLocation *)location regeocode:(AMapLocationReGeocode *)regeocode
{
    NSMutableString *infoString = [NSMutableString stringWithFormat:@"连续定位完成:%d\n\n回调时间:%@\n经 度:%f\n纬 度:%f\n精 度:%f米\n海 拔:%f米\n速 度:%f\n角 度:%f\n", (int)self.locateCount, location.timestamp, location.coordinate.longitude, location.coordinate.latitude, location.horizontalAccuracy, location.altitude, location.speed, location.course];
    
    if (regeocode)
    {
        NSString *regeoString = [NSString stringWithFormat:@"国 家:%@\n省:%@\n市:%@\n城市编码:%@\n区:%@\n区域编码:%@\n地 址:%@\n兴趣点:%@\n", regeocode.country, regeocode.province, regeocode.city, regeocode.citycode, regeocode.district, regeocode.adcode, regeocode.formattedAddress, regeocode.POIName];
        [infoString appendString:regeoString];
    }
    
    NSLog(@"%@",infoString);
}

#pragma mark - MapView Delegate


- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    NSLog(@"记录中1...%@",userLocation);
    if (!updatingLocation)
    {
        return;
    }
    
    if (!self.isRecording)
    {
        return;
    }
    
    if (userLocation.location.horizontalAccuracy < 100 && userLocation.location.horizontalAccuracy > 0)
    {
        double lastDis = [userLocation.location distanceFromLocation:self.currentRecord.endLocation];
        
        if (lastDis < 0.0 || lastDis > 10)
        {
            
            [self.locationsArray addObject:userLocation.location];
    
            [self.tipView showTip:[NSString stringWithFormat:@"has got %ld locations",self.locationsArray.count]];
            
            [self.currentRecord addLocation:userLocation.location];
            
            if (self.polyline == nil)
            {
                self.polyline = [MAPolyline polylineWithCoordinates:NULL count:0];
                [self.mapView addOverlay:self.polyline];
            }

            NSUInteger count = 0;
            
            CLLocationCoordinate2D *coordinates = [self coordinatesFromLocationArray:self.locationsArray count:&count];
            if (coordinates != NULL)
            {
                [self.polyline setPolylineWithCoordinates:coordinates count:count];
                free(coordinates);
            }
            
            [self.mapView setCenterCoordinate:userLocation.location.coordinate animated:YES];
            
            // trace
            [self.tempTraceLocations addObject:userLocation.location];
            if (self.tempTraceLocations.count >= kTempTraceLocationCount)
            {
                [self queryTraceWithLocations:self.tempTraceLocations withSaving:NO];
                [self.tempTraceLocations removeAllObjects];
                
                // 把最后一个再add一遍，否则会有缝隙
                [self.tempTraceLocations addObject:userLocation.location];
            }
        }
    }
    
    [self.statusView showStatusWith:userLocation.location];
}


- (void)mapView:(MAMapView *)mapView didChangeUserTrackingMode:(MAUserTrackingMode)mode animated:(BOOL)animated
{
    if (mode == MAUserTrackingModeNone)
    {
        [self.locationBtn setImage:self.imageNotLocate forState:UIControlStateNormal];
    }
    else
    {
        [self.locationBtn setImage:self.imageLocated forState:UIControlStateNormal];
    }
}



- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolygon class]]) {
        MAPolygonRenderer *polylineRenderer = [[MAPolygonRenderer alloc] initWithPolygon:overlay];
        polylineRenderer.lineWidth = 3.0f;
        polylineRenderer.strokeColor = [UIColor orangeColor];
        
        return polylineRenderer;
    } else if ([overlay isKindOfClass:[MACircle class]]) {
        MACircleRenderer *circleRenderer = [[MACircleRenderer alloc] initWithCircle:overlay];
        circleRenderer.lineWidth = 3.0f;
        circleRenderer.strokeColor = [UIColor purpleColor];
        
        return circleRenderer;
    }
    return nil;

}

- (MAAnnotationView*)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation {
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *pointReuseIndetifier = @"pointReuseIndetifier";
        MAPinAnnotationView *annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        if (annotationView == nil) {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndetifier];
        }
        
        annotationView.canShowCallout               = YES;
        annotationView.animatesDrop                 = YES;
        annotationView.draggable                    = NO;
        annotationView.rightCalloutAccessoryView    = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
        return annotationView;
    }
    
    return nil;
}


#pragma mark - Handle Action

- (void)actionRecordAndStop
{
    if (self.isSaving)
    {
        NSLog(@"保存结果中。。。");
        return;
    }
    
    
    
    self.isRecording = !self.isRecording;
    
    if (self.isRecording)
    {
        NSDateFormatter *objDateformat2 = [[NSDateFormatter alloc] init];
        [objDateformat2 setDateFormat:@"yyMMddHHmm"];
        NSDate *datenow = [NSDate date];
        now = [objDateformat2 stringFromDate:datenow];
        [self.tipView showTip:@"Start recording"];
        self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"icon_stop.png"];
        
        if (self.currentRecord == nil)
        {
            self.currentRecord = [[AMapRouteRecord alloc] init];
        }
        
        [self.mapView removeOverlays:self.tracedPolylines];
        [self setBackgroundModeEnable:YES];
    }
    else
    {
        self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"icon_play.png"];
        [self.tipView showTip:@"recording stoppod"];
        
        [self setBackgroundModeEnable:NO];
        
        [self actionSave];
    }
}

- (void)actionSave
{
    self.isRecording = NO;
    self.isSaving = YES;
    [self.locationsArray removeAllObjects];

    [self.mapView removeOverlay:self.polyline];
    self.polyline = nil;
    
    // 全程请求trace
    [self.mapView removeOverlays:self.tracedPolylines];
    [self queryTraceWithLocations:self.currentRecord.locations withSaving:YES];
}

- (void)actionLocation
{
    if (self.mapView.userTrackingMode == MAUserTrackingModeFollow)
    {
        [self.mapView setUserTrackingMode:MAUserTrackingModeNone];
    }
    else
    {
        [self.mapView setUserTrackingMode:MAUserTrackingModeFollow];
    }
}

- (void)actionShowList
{
    UIViewController *recordController = [[RecordViewController alloc] init];
    recordController.title = @"Records";
    
    [self.navigationController pushViewController:recordController animated:YES];
}

#pragma mark - Utility

- (CLLocationCoordinate2D *)coordinatesFromLocationArray:(NSArray *)locations count:(NSUInteger *)count
{
    if (locations.count == 0)
    {
        return NULL;
    }
    
    *count = locations.count;
    
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D) * *count);
    
    int i = 0;
    for (CLLocation *location in locations)
    {
        coordinates[i] = location.coordinate;
        ++i;
    }
    
    return coordinates;
}

- (void)setBackgroundModeEnable:(BOOL)enable
{
    self.mapView.pausesLocationUpdatesAutomatically = !enable;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0)
    {
        self.mapView.allowsBackgroundLocationUpdates = enable;
    }
}

- (void)queryTraceWithLocations:(NSArray<CLLocation *> *)locations withSaving:(BOOL)saving
{
    if (locations.count < 2) {
        return;
    }
    
    NSMutableArray *mArr = [NSMutableArray array];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"token"];
    NSString *id2 = [defaults objectForKey:@"id"];
    
    NSString *sql = @"INSERT INTO `findmycar`.`locus` (`id`, `p_id`, `longitude`, `latitude`, `speed`, `positiontime`, `itemid`, `location`) VALUES ";
    
   
    
    for(CLLocation *loc in locations)
    {
        MATraceLocation *tLoc = [[MATraceLocation alloc] init];
        tLoc.loc = loc.coordinate;
        
        tLoc.speed = loc.speed * 3.6; //m/s  转 km/h
        tLoc.time = [loc.timestamp timeIntervalSince1970] * 1000;
        NSLog(@"%@",loc.timestamp);
        tLoc.angle = loc.course;
        [mArr addObject:tLoc];
        
       
        NSDateFormatter *objDateformat = [[NSDateFormatter alloc] init];
        [objDateformat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

        double speed = 0;
        
        if(loc.speed*3.6>0){
            speed = loc.speed*3.6;
        }
        sql = [sql stringByAppendingFormat:@"(NULL, '%@','%f','%f','%f', '%@','%@','%@'),",id2,
               loc.coordinate.longitude,loc.coordinate.latitude
               ,speed,[objDateformat stringFromDate: loc.timestamp],
               now,@""];

    }
    
    
    
    NSString * finalSql = [sql substringToIndex:sql.length-1];
    NSLog(@"%@",finalSql);
    
    
//    INSERT INTO `findmycar`.`locus` (`id`, `p_id`, `longitude`, `latitude`, `speed`, `positiontime`, `itemid`, `location`)
//    VALUES (NULL, '1',
//            '117.29824490017361', '31.84790798611111',
//            '0.00', '2018-03-14 20:46:19',
//            '127', '安徽省合肥市包河区 南一环路辅路/体育路(南59米)'),
//    (NULL, '1',
//     '117.29824490017361', '31.84790798611111',
//     '0.00', '2018-03-14 20:46:19',
//     '127', '安徽省合肥市包河区 南一环路辅路/体育路(南59米)')
    
    
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
    session.requestSerializer = [AFHTTPRequestSerializer serializer];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];

    params[@"token"] = token;
    params[@"sql"] = finalSql;


    [session POST:@"http://106.14.160.90:8082/findmycar/locus/addSqlFileUpload.do" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
       
       
        NSLog(@"%@",responseObject);

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
    
    
    __weak typeof(self) weakSelf = self;
    __unused NSOperation *op = [self.traceManager queryProcessedTraceWith:mArr type:-1 processingCallback:nil  finishCallback:^(NSArray<MATracePoint *> *points, double distance) {
        
        NSLog(@"trace query done!");
        
        if (saving) {
            weakSelf.totalTraceLength = 0.0;
            [weakSelf.currentRecord updateTracedLocations:points];
            weakSelf.isSaving = NO;
            
            if ([weakSelf saveRoute])
            {
                [weakSelf.tipView showTip:@"recording save succeeded"];
            }
            else
            {
                [weakSelf.tipView showTip:@"recording save failed"];
            }
        }
        
        [weakSelf updateUserlocationTitleWithDistance:distance];
        [weakSelf addFullTrace:points];
        
    } failedCallback:^(int errorCode, NSString *errorDesc) {
        
        NSLog(@"query trace point failed :%@", errorDesc);
        if (saving) {
            weakSelf.isSaving = NO;
        }
    }];

}

- (void)addFullTrace:(NSArray<MATracePoint*> *)tracePoints
{
    MAPolyline *polyline = [self makePolylineWith:tracePoints];
    if(!polyline)
    {
        return;
    }
    
    [self.tracedPolylines addObject:polyline];
    [self.mapView addOverlay:polyline];
}

- (MAPolyline *)makePolylineWith:(NSArray<MATracePoint*> *)tracePoints
{
    if(tracePoints.count < 2)
    {
        return nil;
    }
    
    CLLocationCoordinate2D *pCoords = malloc(sizeof(CLLocationCoordinate2D) * tracePoints.count);
    if(!pCoords) {
        return nil;
    }
    
    for(int i = 0; i < tracePoints.count; ++i) {
        MATracePoint *p = [tracePoints objectAtIndex:i];
        CLLocationCoordinate2D *pCur = pCoords + i;
        pCur->latitude = p.latitude;
        pCur->longitude = p.longitude;
    }
    
    MAPolyline *polyline = [MAPolyline polylineWithCoordinates:pCoords count:tracePoints.count];
    
    if(pCoords)
    {
        free(pCoords);
    }
    
    return polyline;
}

- (void)updateUserlocationTitleWithDistance:(double)distance
{
    self.totalTraceLength += distance;
    self.mapView.userLocation.title = [NSString stringWithFormat:@"距离：%.0f 米", self.totalTraceLength];
}

- (BOOL)saveRoute
{
    if (self.currentRecord == nil || self.currentRecord.numOfLocations < 2)
    {
        return NO;
    }
    
    
    
    NSString *name = self.currentRecord.title;
    NSString *path = [FileHelper filePathWithName:name];
    
    BOOL result = [NSKeyedArchiver archiveRootObject:self.currentRecord toFile:path];
    
    self.currentRecord = nil;
    
    return result;
}

#pragma mark - Initialization

- (void)initStatusView
{
    self.statusView = [[StatusView alloc] initWithFrame:CGRectMake(5, 35, 150, 150)];
    
    [self.view addSubview:self.statusView];
}

- (void)initTipView
{
    self.locationsArray = [[NSMutableArray alloc] init];
    
    self.tipView = [[TipView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height*0.95, self.view.bounds.size.width, self.view.bounds.size.height*0.05)];
    
    [self.view addSubview:self.tipView];
}

- (void)initMapView
{
    self.mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.zoomLevel = 16.0;
    self.mapView.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    
    self.mapView.showsIndoorMap = NO;
    self.mapView.delegate = self;
    
    [self.view addSubview:self.mapView];
    
    self.traceManager = [[MATraceManager alloc] init];
    self.geoFenceManager = [[AMapGeoFenceManager alloc] init];
    
    self.geoFenceManager.delegate = self;
    self.geoFenceManager.activeAction = AMapGeoFenceActiveActionInside | AMapGeoFenceActiveActionOutside | AMapGeoFenceActiveActionStayed;
   
    self.geoFenceManager.allowsBackgroundLocationUpdates = YES;  //允许后台定位
    
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"token"];
    
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
    session.requestSerializer = [AFHTTPRequestSerializer serializer];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    params[@"token"] = token;
    NSLog(@"token:%@",token);
    
    [session POST:@"http://106.14.160.90:8082/findmycar/power/findByAllPower.do" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        
        NSLog(@"%@----------",responseObject);
        
        NSArray *dict = [responseObject valueForKeyPath:@"list"];
        NSLog(@"-------%lu",dict.count);
        for (int i = 0; i<dict.count; i++) {
            NSString *s_type = [dict[i] valueForKeyPath:@"s_type"];
            NSString *e_type = [dict[i] valueForKeyPath:@"e_type"];
            
            
            NSString *st = [NSString stringWithFormat:@"%@",s_type];
            NSString *et = [NSString stringWithFormat:@"%@",e_type];
            if([st isEqualToString:@"1"]){
                NSLog(@"%@-------",s_type);
                NSString *s_latitude = [dict[i] valueForKeyPath:@"s_latitude"];
                NSString *s_longitude = [dict[i] valueForKeyPath:@"s_longitude"];
                NSString *s_radius = [dict[i] valueForKeyPath:@"s_radius"];
                NSString *startpoint = [dict[i] valueForKeyPath:@"startpoint"];
                
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(
                                    [s_latitude doubleValue],[s_longitude doubleValue]);
               
                NSString *string = @"circle_";
                string = [string stringByAppendingString:startpoint];
                string = [string stringByAppendingString:@"_起点"];
               
                [self.geoFenceManager addCircleRegionForMonitoringWithCenter:coordinate radius:[s_radius intValue] customID:string];
            }
            else{
                NSString *startpoint = [dict[i] valueForKeyPath:@"startpoint"];
                NSArray *slist = [dict[i] valueForKeyPath:@"slist"];
                NSInteger count = 4;
                CLLocationCoordinate2D *coorArr = malloc(sizeof(CLLocationCoordinate2D) * count);


                for(int j=0;j<4;j++){
                    NSString *latitude1 = [slist[j] valueForKeyPath:@"latitude"];
                    NSString *longitude1 = [slist[j] valueForKeyPath:@"longitude"];
                    coorArr[i] = CLLocationCoordinate2DMake([latitude1 doubleValue],[longitude1 doubleValue]);
                }

                NSString *string = @"rect_";
                string = [string stringByAppendingString:startpoint];
                string = [string stringByAppendingString:@"_起点"];

                [self.geoFenceManager addPolygonRegionForMonitoringWithCoordinates:coorArr count:count customID:string];
            }
           // NSLog(@"%@",e_type);


            if([et isEqualToString:@"1"]){
                // NSLog(@"%@",s_type);
                NSString *s_latitude = [dict[i] valueForKeyPath:@"e_latitude"];
                NSString *s_longitude = [dict[i] valueForKeyPath:@"e_longitude"];
                NSString *s_radius = [dict[i] valueForKeyPath:@"e_radius"];
                NSString *startpoint = [dict[i] valueForKeyPath:@"endpoint"];

                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(
                                                                               [s_latitude doubleValue],[s_longitude doubleValue]);

                NSString *string = @"circle_";
                string = [string stringByAppendingString:startpoint];
                string = [string stringByAppendingString:@"_终点"];

                [self.geoFenceManager addCircleRegionForMonitoringWithCenter:coordinate radius:[s_radius intValue] customID:string];
            }else{
                NSString *startpoint = [dict[i] valueForKeyPath:@"endpoint"];
                NSArray *slist = [dict[i] valueForKeyPath:@"elist"];
                NSInteger count = 4;
                CLLocationCoordinate2D *coorArr = malloc(sizeof(CLLocationCoordinate2D) * count);


                for(int j=0;j<4;j++){
                    NSString *latitude1 = [slist[j] valueForKeyPath:@"latitude"];
                    NSString *longitude1 = [slist[j] valueForKeyPath:@"longitude"];
                    coorArr[i] = CLLocationCoordinate2DMake([latitude1 doubleValue],[longitude1 doubleValue]);
                }

                NSString *string = @"rect_";
                string = [string stringByAppendingString:startpoint];
                string = [string stringByAppendingString:@"_终点"];

                [self.geoFenceManager addPolygonRegionForMonitoringWithCoordinates:coorArr count:count customID:string];
            }
            
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
    
//    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(31.8479100000,117.2975160000);
//    [self.geoFenceManager addCircleRegionForMonitoringWithCenter:coordinate radius:300 customID:@"circle_1"];
//
//
//    CLLocationCoordinate2D coordinate2 = CLLocationCoordinate2DMake(31.7420770000,117.2416360000);
//    [self.geoFenceManager addCircleRegionForMonitoringWithCenter:coordinate2 radius:300 customID:@"circle_2"];
    
    self.locationManager = [[AMapLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    //设置不允许系统暂停定位
    [self.locationManager setPausesLocationUpdatesAutomatically:NO];
    //设置允许在后台定位
    [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    //开启带逆地理连续定位
    [self.locationManager setLocatingWithReGeocode:YES];
}

- (MACircle *)showCircleInMap:(CLLocationCoordinate2D )coordinate radius:(NSInteger)radius {
    MACircle *circleOverlay = [MACircle circleWithCenterCoordinate:coordinate radius:radius];
    
    [self.mapView addOverlay:circleOverlay];
    return circleOverlay;
}


- (void)amapGeoFenceManager:(AMapGeoFenceManager *)manager didAddRegionForMonitoringFinished:(NSArray<AMapGeoFenceRegion *> *)regions customID:(NSString *)customID error:(NSError *)error {
    if (error) {
        NSLog(@"创建失败 %@",error);
    } else {
        NSLog(@"创建成功");
    }
    NSLog(customID);
    if ([customID hasPrefix:@"circle"]) {
        if (error) {
            NSLog(@"======= circle error %@",error);
        } else {  //围栏添加后，在地图上的显示，只是为了更方便的演示，并不是必须的.
          //  NSLog(customID);
            AMapGeoFenceCircleRegion *circleRegion = (AMapGeoFenceCircleRegion *)regions.firstObject;  //一次添加一个圆形围栏，只会返回一个
            MACircle *circleOverlay = [self showCircleInMap:circleRegion.center radius:circleRegion.radius];
            [self.mapView setVisibleMapRect:circleOverlay.boundingMapRect edgePadding:UIEdgeInsetsMake(20, 20, 20, 20) animated:NO];   //设置地图的可见范围，让地图缩放和平移到合适的位置
            
        }
    }
}



- (void)amapGeoFenceManager:(AMapGeoFenceManager *)manager didGeoFencesStatusChangedForRegion:(AMapGeoFenceRegion *)region customID:(NSString *)customID error:(NSError *)error {
    
//    AMapGeoFenceRegionStatusUnknown
//    未知
//
//    AMapGeoFenceRegionStatusInside
//    在范围内
//
//    AMapGeoFenceRegionStatusOutside
//    在范围外
//
//    AMapGeoFenceRegionStatusStayed
//    停留(在范围内超过10分钟)
    if (error) {
        NSLog(@"status changed error %@",error);
    }else{
         //0 1 2 3
        NSLog(@"status changed success %@ %@",[region description],region.customID);
        
       // region.customID
        
        if(region.fenceStatus==1&&[region.customID  hasSuffix:@"起点"]){
            //开始记录
            _isAnyInWeiLan = true;
            
        }
        
        if(region.fenceStatus==2&&[region.customID  hasSuffix:@"起点"]&&_isAnyInWeiLan){
            //开始记录
            NSLog(@"开始记录");
            
            if (!self.isRecording)
            {
                [self actionRecordAndStop];
            }
            
        }
        
        if(region.fenceStatus==1&&[region.customID  hasSuffix:@"终点"]){
            //开始记录
            NSLog(@"结束记录");
            
            if (self.isRecording)
            {
                [self actionRecordAndStop];
            }
            
        }
        
    }
}

- (void)initNavigationBar
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_play"] style:UIBarButtonItemStylePlain target:self action:@selector(actionRecordAndStop)];
    
    UIBarButtonItem *listButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_list"] style:UIBarButtonItemStylePlain target:self action:@selector(actionShowList)];
    
    NSArray *array = [[NSArray alloc] initWithObjects:listButton, nil];
    self.navigationItem.rightBarButtonItems = array;
    
    
   
    
    self.isRecording = NO;
    
    self.isSaving = NO;
}

- (void)initLocationButton
{
    self.imageLocated = [UIImage imageNamed:@"location_yes.png"];
    self.imageNotLocate = [UIImage imageNamed:@"location_no.png"];
    
    self.locationBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, CGRectGetHeight(self.view.bounds) - 90, 40, 40)];
    self.locationBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    self.locationBtn.backgroundColor = [UIColor whiteColor];
    self.locationBtn.layer.cornerRadius = 3;
    [self.locationBtn addTarget:self action:@selector(actionLocation) forControlEvents:UIControlEventTouchUpInside];
    [self.locationBtn setImage:self.imageNotLocate forState:UIControlStateNormal];
    
    [self.view addSubview:self.locationBtn];
}

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:@"在途监控"];
    
    [self initNavigationBar];
     [self.navigationItem setHidesBackButton:TRUE animated:NO];
    [self initMapView];
    
    [self initStatusView];
    
    [self initTipView];
    
    [self initLocationButton];
    
    self.tracedPolylines = [NSMutableArray array];
    self.tempTraceLocations = [NSMutableArray array];
    self.totalTraceLength = 0.0;
    
    
    //保证timer在后台运行
    
               [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    
             //创建并执行新的线程
    
              NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(newThread) object:nil];
    
    [thread start];
}


//开一个新线程

- (void)newThread

  {
    
                 @autoreleasepool
    
      {
        
        //在当前Run Loop中添加timer，模式是默认的NSDefaultRunLoopMode
        
                       [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(timer_callback) userInfo:nil repeats:YES];
        
                       //开始执行新线程的Run Loop
        
                    [[NSRunLoop currentRunLoop] run];
        
             }
    
}

//定时器

- (void)timer_callback

{
    
                    NSLog(@"根本停不下来");
    
    //http://106.14.160.90:8082/findmycar/pilot/updateLasttime.do
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"token"];
    NSString *id2 = [defaults objectForKey:@"id"];
    
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
    session.requestSerializer = [AFHTTPRequestSerializer serializer];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    params[@"token"] = token;
    params[@"id"] = id2;
    
     NSLog(@"%@",id2);
    [session POST:@"http://106.14.160.90:8082/findmycar/pilot/updateLasttime.do" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        
        NSLog(@"%@",responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
    
}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.mapView.userTrackingMode = MAUserTrackingModeFollow;
}

#pragma mark - MAMapViewDelegate



@end
