/*
 A Swift Playground Demo to display an Apple II Double Hi-Res color image.
 Written in Swift 3.x
 XCode: 8.x
*/
import Cocoa
import PlaygroundSupport

let testURL =
    Bundle.main.url(forResource: "COLORBARS",
                    withExtension: "A2FC")
var dataContents: Data?
do {
    dataContents = try Data(contentsOf: testURL!)
    let converter = DHGRConverter(data: dataContents!)
    let cgImage = converter.cgImage
    let size = NSSize(width: 280, height: 192)
    let nsImage = NSImage(cgImage: cgImage!, size: size)
    let frameRect = CGRect(x: 0, y: 0, width: 280, height: 192)
    let view = NSImageView(frame: frameRect)
    view.image = nsImage
    PlaygroundPage.current.liveView = view
}
catch let error {
    Swift.print("Error code:", error)
}
