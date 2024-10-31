//
//  ContentView.swift
//  swift-ios-classify-image
//
//  Created by Stevan Sehn on 31/10/24.
//

import SwiftUI
import PhotosUI
import CoreML
import Vision

struct ContentView: View {
    @State private var isPickerPresented = false
    @State private var selectedImage: UIImage?
    @State var classification: String = ""
    
    var body: some View {
        VStack {
            if let image = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .padding()
                    
                    Button(action: {
                        selectedImage = nil
                        classification = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            } else {
                Text("No image selected")
                    .foregroundColor(.gray)
                    .padding()
            }
            
            Button {
                isPickerPresented = true
            } label: {
                Image(systemName: "camera.fill")
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 25.0)
            }
            .padding(5.0)
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $isPickerPresented) {
                PhotoPicker(selectedImage: $selectedImage)
                    .onChange(of: selectedImage) { newImage in
                        if let newImage = newImage {
                            classifyImage(newImage) // Classify image on selection
                        }
                    }
            }

            Text(classification)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color.black)
                .multilineTextAlignment(.leading)
            
        }
    }
    
    // Classifies the selected image using SqueezeNet model
    func classifyImage(_ image: UIImage) {
        guard let model = try? VNCoreMLModel(for: SqueezeNet().model) else {
            print("Failed to load model")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let results = request.results as? [VNClassificationObservation] {
                if let topResult = results.first {
                    classification = "Classification: \(topResult.identifier) with  \(String(format: "%.2f", 100 * topResult.confidence))% confidence."
                    print(classification)
                }
            } else {
                print("No results")
            }
        }
        
        guard let ciImage = CIImage(image: image) else {
            print("Failed to create CIImage from UIImage")
            return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            classification = "Failed to perform image classification: \(error.localizedDescription)"
            print(classification)
        }
    }
}

// UIViewControllerRepresentable wrapper for PHPickerViewController
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selectedImage: $selectedImage)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        @Binding var selectedImage: UIImage?
        
        init(selectedImage: Binding<UIImage?>) {
            _selectedImage = selectedImage
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true, completion: nil)
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
