//
//  DisplayViewController.swift
//  MyRoute
//
//  Created by xiaoming han on 14-7-21.
//  Copyright (c) 2014 AutoNavi. All rights reserved.
//

import UIKit

class DisplayViewController: UIViewController, MAMapViewDelegate {

    var route: AMapRouteRecord?
    var mapView: MAMapView?
    var myLocation: MAAnimatedAnnotation?
    
    var isPlaying: Bool = false
    
    var traceCoordinates: Array<CLLocationCoordinate2D> = []
    var duration: TimeInterval = 0.0
    
    
    override func viewDidLoad() {
        
        self.view.backgroundColor = UIColor.gray
        
        initMapView()
        
        initToolBar()
        
        showRoute()
    }
    
    func initMapView() {
        
        mapView = MAMapView(frame: self.view.bounds)
        mapView!.delegate = self
        self.view.addSubview(mapView!)
        self.view.sendSubview(toBack: mapView!)
    }
    
    func initToolBar() {
        
        let playButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_play.png"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(DisplayViewController.actionPlayAndStop))
        
        navigationItem.rightBarButtonItem = playButtonItem
    }
    
    func showRoute() {
        
        if route == nil || route!.tracedLocations.count == 0 {
            print("Invalid route")
            return
        }
        
        // init the trace coordinates
        var coords: [CLLocationCoordinate2D] = Array()
        
        for point in route!.tracedLocations {
            coords.append(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
        }
        
        traceCoordinates = coords
        duration = route!.totalDuration() / 2.0;
        
        //show route
        let starPoint = MAPointAnnotation()
        starPoint.coordinate = traceCoordinates.first!
        starPoint.title = "Start"
        
        mapView!.addAnnotation(starPoint)
        
        
        let endPoint = MAPointAnnotation()
        endPoint.coordinate = traceCoordinates.last!
        endPoint.title = "End"
        
        mapView!.addAnnotation(endPoint)

        
        let polyline = MAPolyline(coordinates: &traceCoordinates, count: UInt(traceCoordinates.count))
        
        mapView!.add(polyline)
        
        mapView!.showOverlays(mapView!.overlays, animated: false)
    }
    
    //MARK:- Helpers
    
    func actionPlayAndStop() {
        print("actionPlayAndStop")
        
        if route == nil || traceCoordinates.count == 0 {
            return
        }
        
        isPlaying = !isPlaying
        
        if isPlaying {
            navigationItem.rightBarButtonItem!.image = UIImage(named: "icon_stop.png")
            
            if myLocation == nil {
                myLocation = MAAnimatedAnnotation()
                myLocation!.title = "AMap"
                myLocation!.coordinate = route!.startLocation()!.coordinate
                
                mapView!.addAnnotation(myLocation)
            }
            
            weak var weakSelf = self

            self.myLocation!.addMoveAnimation(withKeyCoordinates: &traceCoordinates, count: UInt(traceCoordinates.count), withDuration: CGFloat(duration), withName: "", completeCallback: { (isFinished) in
                
                if isFinished {
                    weakSelf?.actionPlayAndStop()
                }
            })
        }
        else {
            navigationItem.rightBarButtonItem!.image = UIImage(named: "icon_play.png")
            for animation: MAAnnotationMoveAnimation in (self.myLocation?.allMoveAnimations())! {
                animation.cancel()
            }
            myLocation?.coordinate = traceCoordinates[0]
            myLocation?.movingDirection = 0.0
        }
    }
    
    //MARK:- MAMapViewDelegate
    
    func mapView(_ mapView: MAMapView, viewFor annotation: MAAnnotation) -> MAAnnotationView? {
        
        if annotation.isEqual(myLocation) {
            
            let annotationIdentifier = "myLcoationIdentifier"
            
            var poiAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
            if poiAnnotationView == nil {
                poiAnnotationView = MAAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            }
            
            poiAnnotationView?.image = UIImage(named: "car1")
            poiAnnotationView!.canShowCallout = false
            
            return poiAnnotationView;
        }
        
        if annotation.isKind(of: MAPointAnnotation.self) {
            let annotationIdentifier = "lcoationIdentifier"
            
            var poiAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MAPinAnnotationView
            
            if poiAnnotationView == nil {
                poiAnnotationView = MAPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            }
            poiAnnotationView!.canShowCallout = true
            
            return poiAnnotationView;
        }
        
        return nil
    }

    func mapView(_ mapView: MAMapView, rendererFor overlay: MAOverlay) -> MAOverlayRenderer? {
        
        if overlay.isKind(of: MAPolyline.self) {
            let renderer: MAPolylineRenderer = MAPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 6.0
            
            return renderer
        }
        
        return nil
    }

}
