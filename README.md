# DocSnap PDF Scanner 📄✨

A powerful, production-ready Flutter application for scanning documents, editing them, and exporting high-quality PDFs. Built with modern architecture and performance in mind.

## 🚀 Features

-   **Smart Document Scanning**: Uses Google ML Kit to automatically detect document edges and correct perspective.
-   **Advanced PDF Editor**:
    -   **WYSIWYG Editing**: What you see is *exactly* what you get in the PDF.
    -   **Add Text**: Insert custom text with adjustable positioning and scaling.
    -   **Digital Signatures**: Sign documents directly on screen and place them anywhere.
    -   **Smart Resizing**: Text and signatures maintain their aspect ratio to prevent distortion.
-   **Performance Optimized**:
    -   **Zero-Lag Scrolling**: Custom caching engine for smooth page viewing even with large files.
    -   **Memory Efficient**: Handles high-resolution images without crashing, thanks to native image compression and smart streaming.
-   **Image Import**: Gallery support with automatic compression for large files.
-   **PDF Generation**: Exports standard, printable PDF files.
-   **Sharing**: Native share sheet integration to send PDFs via Email, WhatsApp, etc.

## 🛠️ Tech Stack

-   **Framework**: [Flutter](https://flutter.dev/) (SDK >=3.2.0)
-   **State Management**: [Riverpod](https://riverpod.dev/) (Code generation & Annotation)
-   **Routing**: [GoRouter](https://pub.dev/packages/go_router)
-   **Scanning**: `google_mlkit_document_scanner`
-   **PDF Core**: `pdf` & `printing`
-   **Utilities**: `flutter_image_compress`, `signature`, `path_provider`

## 📦 Getting Started

### Prerequisites
-   Flutter SDK installed
-   Android Studio / VS Code
-   Android Device (for scanning features) or Emulator

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/IntoTheOblivion/DocSnap.git
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the App**:
    ```bash
    flutter run
    ```

## 🏗️ Project Structure
The project follows a **Feature-First Architecture** for scalability:

```
lib/
├── core/            # Global utilities, services, and shared widgets
├── features/        # Feature modules
│   ├── scanner/     # Document scanning logic
│   ├── pdf_generator/ # PDF creation and editing logic
│   └── home/        # Main dashboard
└── main.dart        # Entry point
```

## 🔧 Key Implementation Details

-   **Aspect Ratio Lock**: The editor uses a custom `AspectRatio` wrapper to ensure the UI overlay matches the PDF coordinate system 1:1.
-   **Efficient Image Loading**: Instead of decoding full bitmaps on the UI thread, the app reads image metadata (dimensions) upfront and streams data only when needed.

## 🤝 Contributing

Contributions are welcome!
1.  Fork the project
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request
