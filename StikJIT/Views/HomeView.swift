//
//  ContentView.swift
//  StikJIT
//
//  Created by Stephen on 3/26/25.
//

import SwiftUI
import UniformTypeIdentifiers

extension UIDocumentPickerViewController {
    @objc func fix_init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) -> UIDocumentPickerViewController {
        return fix_init(forOpeningContentTypes: contentTypes, asCopy: true)
    }
}

struct HomeView: View {
    @AppStorage("username") private var username = "User"
    @AppStorage("customBackgroundColor") private var customBackgroundColorHex: String = Color.primaryBackground.toHex() ?? "#000000"
    @State private var selectedBackgroundColor: Color = Color(hex: UserDefaults.standard.string(forKey: "customBackgroundColor") ?? "#000000") ?? Color.primaryBackground
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @AppStorage("bundleID") private var bundleID: String = ""
    @State private var isProcessing = false
    @State private var isShowingInstalledApps = false
    @State private var isShowingPairingFilePicker = false
    @State private var pairingFileExists: Bool = false
    @State private var showPairingFileMessage = false
    @State private var pairingFileIsValid = false
    @State private var isImportingFile = false
    @State private var importProgress: Float = 0.0

    var body: some View {
        ZStack {
            selectedBackgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                Spacer()
                VStack(spacing: 5) {
                    Text("Welcome to StikJIT \(username)!")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text(pairingFileExists ? "Click enable JIT to get started" : "Pick pairing file to get started")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Main action button - changes based on whether we have a pairing file
                Button(action: {
                    if pairingFileExists {
                        // Got a pairing file, show apps
                        isShowingInstalledApps = true
                    } else {
                        // No pairing file yet, let's get one
                        isShowingPairingFilePicker = true
                    }
                }) {
                    HStack {
                        Image(systemName: pairingFileExists ? "bolt.fill" : "doc.badge.plus")
                            .font(.system(size: 20))
                        Text(pairingFileExists ? "Enable JIT" : "Select Pairing File")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                
                // Status message area - keeps layout consistent
                ZStack {
                    // Progress bar for importing file
                    if isImportingFile {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Processing pairing file...")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondaryText)
                                Spacer()
                                Text("\(Int(importProgress * 100))%")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondaryText)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.black.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.green)
                                        .frame(width: geometry.size.width * CGFloat(importProgress), height: 8)
                                        .animation(.linear(duration: 0.3), value: importProgress)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    // Success message
                    if showPairingFileMessage && pairingFileIsValid {
                        Text("✓ Pairing file successfully imported")
                            .font(.system(.callout, design: .rounded))
                            .foregroundColor(.green)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .transition(.opacity)
                    }
                    
                    // Invisible text to reserve space - no layout jumps
                    Text(" ").opacity(0)
                }
                .frame(height: isImportingFile ? 60 : 30)  // Adjust height based on what's showing
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            checkPairingFileExists()
        }
        .onReceive(timer) { _ in
            refreshBackground()
            checkPairingFileExists()
        }
        .fileImporter(isPresented: $isShowingPairingFilePicker, allowedContentTypes: [UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!, .propertyList]) {result in
            switch result {
            
            case .success(let url):
                let fileManager = FileManager.default
                let accessing = url.startAccessingSecurityScopedResource()
                
                if fileManager.fileExists(atPath: url.path) {
                    do {
                        if fileManager.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path) {
                            try fileManager.removeItem(at: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
                        }
                        
                        try fileManager.copyItem(at: url, to: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
                        print("File copied successfully!")
                        
                        // Show progress bar and initialize progress
                        DispatchQueue.main.async {
                            isImportingFile = true
                            importProgress = 0.0
                            pairingFileExists = true
                        }
                        
                        // Start heartbeat in background
                        startHeartbeatInBackground()
                        
                        // Create timer to update progress instead of sleeping
                        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                            DispatchQueue.main.async {
                                // Increment progress
                                if importProgress < 1.0 {
                                    importProgress += 0.05
                                } else {
                                    timer.invalidate()
                                    isImportingFile = false
                                    pairingFileIsValid = true
                                    
                                    // Show success message
                                    withAnimation {
                                        showPairingFileMessage = true
                                    }
                                    
                                    // Hide message after delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation {
                                            showPairingFileMessage = false
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Ensure timer keeps running
                        RunLoop.current.add(progressTimer, forMode: .common)
                        
                    } catch {
                        print("Error copying file: \(error)")
                    }
                } else {
                    print("Source file does not exist.")
                }
                
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                print("Failed to import file: \(error)")
            }
        }
        .sheet(isPresented: $isShowingInstalledApps) {
            InstalledAppsListView { selectedBundle in
                bundleID = selectedBundle
                isShowingInstalledApps = false
                HapticFeedbackHelper.trigger()
                startJITInBackground(with: selectedBundle)
            }
        }
    }
    
    private func checkPairingFileExists() {
        pairingFileExists = FileManager.default.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path)
    }
    
    private func refreshBackground() {
        selectedBackgroundColor = Color(hex: customBackgroundColorHex) ?? Color.primaryBackground
    }
    
    private func startJITInBackground(with bundleID: String) {
        isProcessing = true
        DispatchQueue.global(qos: .background).async {
            guard let cBundleID = strdup(bundleID) else {
                DispatchQueue.main.async { isProcessing = false }
                return
            }
            
            _ = debug_app(cBundleID)
            
            free(cBundleID)
            DispatchQueue.main.async {
                isProcessing = false
            }
        }
    }
}

class InstalledAppsViewModel: ObservableObject {
    @Published var apps: [String: String] = [:]
    
    init() {
        loadApps()
    }
    
    func loadApps() {
        guard let rawPointer = list_installed_apps() else {
            self.apps = [:]
            return
        }
        
        let output = String(cString: rawPointer)
        free(rawPointer)

        guard let jsonData = output.data(using: .utf8) else {
            print("Error: Failed to convert string to data")
            self.apps = [:]
            return
        }
        
        print(output)

        // Decode the JSON into a Swift dictionary
        do {
            let decoder = JSONDecoder()
            let apps = try decoder.decode([String: String].self, from: jsonData)
            if let app = apps.first, app.key == "error" {
                self.apps = [:]
            } else {
                self.apps = apps
            }
            return
        } catch {
            print("Error: Failed to decode JSON - \(error)")
            self.apps = [:]
            return
        }
        
    }
}



#Preview {
    HomeView()
}
