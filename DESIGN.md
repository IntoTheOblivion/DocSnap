# DocSnap_PDF_Scanner - Design Document

## 1. Executive Summary
DocSnap_PDF_Scanner is a native Flutter application designed to scan physical documents using on-device Machine Learning (Google ML Kit), process them (crop, filter), and export them as multi-page PDF files. The goal is a production-ready, performant, and user-friendly mobile experience.

## 2. Core Requirements

### 2.1 Functional Requirements
- **Dashboard**:
    - List previously created PDF scans (persisted locally).
    - Floating Action Button (FAB) to initiate a new scan.
- **Scanning Interface**:
    - Utilize `google_mlkit_document_scanner` for edge detection and auto-cropping.
    - Support multi-page scanning (batch mode).
- **Preview & Edit**:
    - Display scanned pages.
    - Allow manual crop adjustments (if ML Kit confidence is low).
    - **Filters**:
        - Original
        - Black & White (Binarization)
        - Grayscale
- **PDF Generation**:
    - specific pages to single PDF file conversion.
    - Support A4 page formatting.
- **Export & Share**:
    - "Share" functionality to send PDF via system share sheet (Email, WhatsApp, Files).

### 2.2 Non-Functional Requirements
- **Performance**: Native ML processing for real-time edge detection.
- **Privacy**: All processing happens on-device; no cloud upload.
- **UX**: Material 3 Design adaptation, clean transitions.

## 3. Technical Architecture

### 3.1 Tech Stack
- **Framework**: Flutter (Dart) - Latest Stable
- **State Management**: Riverpod (with `riverpod_generator` preferred)
- **Navigation**: GoRouter
- **Platform**: iOS & Android

### 3.2 Key Dependencies
| Package | Purpose |
| :--- | :--- |
| `google_mlkit_document_scanner` | Core scanning logic, edge detection, cropping |
| `pdf` | PDF document construction |
| `printing` | Printing and sharing interface |
| `path_provider` | Local filesystem access |
| `shared_preferences` / `hive` | Metadata storage for scan history |
| `hooks_riverpod` | Simplified state lifecycle management |

### 3.3 Folder Structure
Adopting a Feature-First Architecture:

```text
lib/
├── core/
│   ├── constants/       # App-wide constants (colors, strings)
│   ├── theme/           # AppTheme definitions
│   └── utils/           # Helper functions (permissions, dates)
├── features/
│   ├── scanner/
│   │   ├── applications/ # Service layer (DocumentScannerService)
│   │   └── presentation/ # UI Screens (Camera, Preview)
│   ├── pdf_generator/
│   │   ├── application/  # PDF creation logic (PdfGeneratorService)
│   │   └── domain/       # PDF Models
│   └── home/
│       ├── presentation/ # Dashboard Screen, History List
│       └── data/         # Repositories for saved files
└── main.dart
```

## 4. Component Design

### 4.1 DocumentScannerService
- **Responsibility**: Interface with `google_mlkit_document_scanner`.
- **Methods**:
    - `Future<List<String>> scanDocument()`: Opens camera, handles user flow, returns list of file paths for scanned pages.
- **Error Handling**: Catch `PlatformException` (e.g., camera permission denied).

### 4.2 PdfGeneratorService
- **Responsibility**: Convert image lists to `.pdf` files.
- **Methods**:
    - `Future<File> createPdf(List<File> images)`:
        - Loads images.
        - Adds them as pages (A4 format).
        - Saves to `ApplicationDocumentsDirectory`.
        - Returns the generated File object.

### 4.3 State Management (Riverpod)
- `scanHistoryProvider`: Watches the local directory for created PDFs and provides a list to the Dashboard.
- `scannerControllerProvider`: Manages the state of the active scan session (current images, selected filter).

## 5. UI/UX Flow
1.  **Home**: Empty state -> Placeholder. Populated -> List of Cards (Thumbnail | Name | Date).
2.  **Scan**: Tap FAB -> ML Kit Scanner UI (System Native).
3.  **Post-Scan**: Return to app -> Show Review Screen (Grid of scanned pages).
    - Options: "Save as PDF", "Retake", "Discard".
4.  **Result**: PDF Preview -> "Share" button.

## 6. Constraints
- Use standard Flutter lints.
- Avoid custom OpenCV implementation; strictly use ML Kit.
- Ensure proper error handling for Camera permissions.
