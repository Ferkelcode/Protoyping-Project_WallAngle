//
//  ContentView.swift
//  WallAngle
//
//  Created by yuening hong on 31.01.22.
//
import Foundation
import SwiftUI




struct Marker: Hashable {
    let degrees: Double
    let label: String

    init(degrees: Double, label: String = "") {
        self.degrees = degrees
        self.label = label
    }

    func degreeText() -> String {
        return String("Angle is :")
    }

    static func markers() -> [Marker] {
        return [
            /*
            Marker(degrees: 0, label: "Next wall"),
            
            Marker(degrees: 30),
            Marker(degrees: 60),
            Marker(degrees: 90, label: "E"),
            Marker(degrees: 120),
            Marker(degrees: 150),
            Marker(degrees: 180, label: "S"),
            Marker(degrees: 210),
            Marker(degrees: 240),
            Marker(degrees: 270, label: "W"),
            Marker(degrees: 300),
            Marker(degrees: 330)
            */
        ]
    }
}

struct CompassMarkerView: View {
    let marker: Marker
    let compassDegress: Double
    //VStack, arrange the interface
    var body: some View {
        VStack {
            Text(marker.degreeText())
                .fontWeight(.light)
                .rotationEffect(self.textAngle())
            
            Capsule()
                .frame(width: self.capsuleWidth(),
                       height: self.capsuleHeight())
                .foregroundColor(self.capsuleColor())
            
            Text(marker.label)
                .fontWeight(.bold)
                .rotationEffect(self.textAngle())
                .padding(.bottom, 180)
        }.rotationEffect(Angle(degrees: marker.degrees))
    }
    
    private func capsuleWidth() -> CGFloat {
        return self.marker.degrees == 0 ? 7 : 3
    }

    private func capsuleHeight() -> CGFloat {
        return self.marker.degrees == 0 ? 45 : 30
    }

    private func capsuleColor() -> Color {
        return self.marker.degrees == 0 ? .red : .gray
    }

    private func textAngle() -> Angle {
        return Angle(degrees: -self.compassDegress - self.marker.degrees)
    }
     
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

// A View wrapper to make the modifier easier to use
// UIDeviceOrientation
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct ContentView: View {
    @ObservedObject var compassHeading = CompassHeading()
    @State private var gotfirst = false
    @State private var gotsecond = false
    
    @State private var Wall1 = 0.0
    @State private var Wall2 = 0.0
    @State private var Angle = 0.0
    @State private var outerAngle = 0.0
    
    @State private var buttonText = "Start Measurement"
    @State private var showAlert = true
    @State private var orientation = UIDeviceOrientation.unknown
    
    var body: some View {
        //To make sure the phone is hold horitontally.
        Group {
                    if orientation.isPortrait {
                        Text("Please hold your phone horizontally.").foregroundColor(.red).fontWeight(.bold)
                    } else if orientation.isLandscape {
                        Text("Please hold your phone horizontally.").foregroundColor(.red).fontWeight(.bold)
                    } else if orientation.isFlat {
                        Text(" ").foregroundColor(.green)
                    } else {
                        Text(" ").foregroundColor(.red).fontWeight(.bold)
                    }
        }
        VStack {
            if self.orientation.isFlat{ //only when the orientation is Flat
                Button(self.buttonText) {
                    if(!gotfirst){
                        Wall1 = self.compassHeading.degrees
                        gotfirst = true
                        Angle = 0.0
                        self.buttonText = "Measure 2nd Wall"
                    }
                    else if(!gotsecond){
                        Wall2 = self.compassHeading.degrees
                        Angle = abs(Wall1 - Wall2)
                        outerAngle = abs (360 - Angle)
                        gotsecond = true
                        self.buttonText = "Reset"
                    }
                    else {
                        gotfirst = false
                        gotsecond = false
                        Angle = 0.0
                        self.buttonText = "Start Measurement"
                    }
                }
                .padding()
                .background(Color.blue)
                .cornerRadius(40)
                .foregroundColor(.white)
            }
            
            
            ZStack {
                           ForEach(Marker.markers(), id: \.self) { marker in
                               CompassMarkerView(marker: marker,
                                                 compassDegress: self.compassHeading.degrees)
                               //CompassMarkerView(marker: marker,
                                                 //compassDegress: 0)
                           }
                
                //*******should be after button click*********
                //turn the second line
                if (gotfirst && !gotsecond){
                    Capsule()
                        .frame(width: 5, height: 70)
                        .foregroundColor(.blue)
                        .rotationEffect(SwiftUI.Angle(degrees: self.compassHeading.degrees-Wall1), anchor: .bottom)
                }
                //fix the second line
                if (gotsecond){
                    Capsule()
                        .frame(width: 5, height: 70)
                        .foregroundColor(.blue)
                        .rotationEffect(SwiftUI.Angle(degrees: Wall2-Wall1), anchor: .bottom)
                }
                //********************+
                
                
                //the first line
                Capsule()
                    .frame(width: 5, height: 70)
                    .foregroundColor(.orange)
                    //.fill(Color.blue)
                    
            }
            .frame(width: 300, height: 200)
            //.rotationEffect(SwiftUI.Angle(degrees: self.compassHeading.degrees))
            .statusBar(hidden: true)
            
            if gotsecond {
                Text("The inner angle is: \(String(format: "%.2f", Angle))")
                    .font(.system(size: 30))
                Text("The outer angle is: \(String(format: "%.2f", outerAngle))")
                    .font(.system(size: 30))
                
            }
            
        }
        .onRotate { newOrientation in
            orientation = newOrientation
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Introduction"), message: Text("To calibrate: Hold your phone up and then tilt it horizontally. Keep it horizontally during the measurement"), dismissButton: .default(Text("Got it!")))
        }
   }
}
