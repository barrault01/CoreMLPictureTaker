//
//  ContentView.swift
//  CoreMLPictureTaker
//
//  Created by Antoine Barrault on 7/15/19.
//  Copyright © 2019 Antoine Barrault. All rights reserved.
//

import SwiftUI
import GridStack

struct ImageFile: FileRepresention {
    func fileData() -> Data {
        return image
    }

    func name() -> String {
        return internalName
    }

    var internalName: String
    var image: Data

}

struct ContentView : View {


    @ObservedObject var listOfCategory: MLDataSet<ImageFile> = MLDataSet()
    @State var showingAlert = false
    @State var newCategory = ""
    var body: some View {
        NavigationView {
            VStack {
                if listOfCategory.isLoaded {
                    List {
                        ForEach(listOfCategory.data!, id: \.name) { (category: DataSet<ImageFile>) in
                            CategoryRow(category: category)
                                .padding()
                        }
                        .onDelete(perform: delete)
                    }
                    Button("New Category", action: {self.showingAlert = true})
                } else {
                    Text("Loading")
                }
            }
                
                .navigationBarTitle(Text("Categories"))
                .sheet(isPresented: self.$showingAlert, content: { CategoryTextField(newCategory: "", dismissView: self.dissmisView) })


        }
    }

    func delete(at offsets: IndexSet) {
        if let indx = offsets.first {
            if let obj = listOfCategory.data?[indx] {
                listOfCategory.diskLoader.deleteFolder(at: obj.name)
            }

        }
    }

    func dissmisView(_ string: String?) {
        if let string = string, string.count > 0 {
            listOfCategory.diskLoader.createNewData(DataSet.init(name: string))
            newCategory = ""
        }
        self.showingAlert = false
    }


}

struct CategoryTextField: View {

    @State var newCategory = ""
    var dismissView: (String?) -> ()
    var body: some View {
        TextField("Category name", text: $newCategory, onCommit: { self.finished() })
        .padding(16)
    }

    func finished() {
        if newCategory.count > 0 {
            self.dismissView(newCategory)
            newCategory = ""
        }
    }
}

struct CategoryRow<D>: View {
    var category: DataSet<D>

    var body: some View {
        NavigationLink(destination: GridView(category: category)) {
            Text(category.name)
        }
    }
}



struct GridView<D>: View {

    var category: DataSet<D>
    @State var showTakePicture: Bool = false
    var body: some View {
        NavigationView {
            VStack {
            GridStack(minCellWidth: 100, spacing: 2, numItems: category.data?.count ?? 0) { index, cellWidth in
                Text("\(index)")
                    .foregroundColor(.white)
                    .frame(width: cellWidth, height: cellWidth)
                    .background(Color.blue)
            }
                Button("Take Picture", action: {
                    self.showTakePicture = true

//                        self.pictures.append("\(self.category.bla()!.count + 1)")
                })
            }
        }
//        .presentation(showTakePicture ? Modal(PictureTaker() { data in
//            print(data)
//            self.showTakePicture = false
//
//        }) { self.showTakePicture = false} : nil)

        .navigationBarTitle(Text(category.name + "-" + "\(self.category.bla()!.count)"))

    }

}

struct PictureTaker: View {
    init(dismissView: @escaping (Data?) -> ()) {
        self.dismissView = dismissView

        delegate = CapturePhotoDelegate()
        delegate.block = { image in
            dismissView(image?.pngData())
        }
    }
    var delegate: CapturePhotoDelegate
    var dismissView: (Data?) -> ()
    var body: some View {
        VStack {
        CameraView(delegate: delegate)
            .frame(width: 300, height: 300, alignment: .center)
        Button("Click") {
            self.delegate.takePicture()
        }
        }
    }

}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif


struct PictureTakerView: UIViewRepresentable {

    let delegate: PictureTakerDelegate
    let imagePicker: UIImagePickerController

    init(dismissView: @escaping (Data?) -> ()) {
        let delegate = PictureTakerDelegate(dismissView: dismissView)
        let picker =  UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = delegate
        self.imagePicker = picker
        self.delegate = delegate
    }


    func makeUIView(context: UIViewRepresentableContext<PictureTakerView>) -> UIView {
        return imagePicker.view
    }

    func updateUIView(_ uiView: PictureTakerView.UIViewType, context: UIViewRepresentableContext<PictureTakerView>) {

    }

}

class PictureTakerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var dismissView: (Data?) -> ()

    init(dismissView: @escaping (Data?) -> ()) {
        self.dismissView = dismissView
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismissView(nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as? UIImage
        dismissView(image?.pngData())

    }

}

import AVFoundation

struct CameraView: UIViewRepresentable {

    var session: AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var previewView: UIImageView
    init(delegate: CapturePhotoDelegate) {
        session = AVCaptureSession()
        session!.sessionPreset = .photo
        self.previewView = UIImageView()
        let backCamera =  AVCaptureDevice.default(for: .video)
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput.init(device: backCamera!)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            stillImageOutput = AVCapturePhotoOutput()

            if session!.canAddOutput(stillImageOutput!) {
                session!.addOutput(stillImageOutput!)
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
                videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspect
                videoPreviewLayer!.connection?.videoOrientation =   .portrait
                previewView.layer.addSublayer(videoPreviewLayer!)
                session!.startRunning()
                delegate.imageOutput = stillImageOutput
            }
        }

    }
    func makeUIView(context: UIViewRepresentableContext<CameraView>) -> UIImageView {


        return self.previewView
    }

    func updateUIView(_ uiView: CameraView.UIViewType, context: UIViewRepresentableContext<CameraView>) {
        videoPreviewLayer!.frame = previewView.bounds

    }



}

class CapturePhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {

    var imageOutput: AVCapturePhotoOutput?
    var block: ((UIImage?) -> Void)?

    func takePicture() {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                imageOutput?.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {

        guard let imageData = photo.fileDataRepresentation()
            else { return }

        let image = UIImage(data: imageData)
        block?(image)
    }

}
