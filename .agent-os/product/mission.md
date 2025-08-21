# Product Mission

## Pitch

Arachne is a Swift networking library that helps developers building apps for older OS versions use async/await URLSession tasks without conditional code and provides an opinionated abstraction layer to reduce boilerplate for common networking flows.

## Users

### Primary Customers

- Swift developers: Building apps for Apple platforms that require networking capabilities, especially those supporting versions before iOS 15/macOS 12 and other OSes from the same year.

- Library maintainers: Seeking minimalistic, zero-dependency solutions for networking abstractions.

### User Personas

#### Mobile App Developer

- **Role:** Apple Developer

- **Context:** Developing apps that need to support older devices while using modern Swift features.
- **Pain Points:** Writing version-specific code for async/await, repetitive boilerplate for request handling and validation.
- **Goals:** Simplify networking code, ensure compatibility across OS versions, minimize dependencies.

- **Context:** Integrating API services in Swift apps with clean, maintainable code.
- **Pain Points:** Managing custom request modifications, error handling without standardized patterns.
- **Goals:** Use an abstraction that mimics Apple's API but allows extensions for custom needs.

## The Problem

### Conditional Code for OS Compatibility

Developers must write conditional code based on OS versions to use async/await features, leading to complex and error-prone codebases. This can increase development time by 20-30% for projects targeting older versions.

**Our Solution:** Arachne backports async/await URLSession tasks to older versions like iOS 13 and macOS 10.15.

### Boilerplate in Networking Code

Common networking tasks require repetitive code for request building, validation, and error handling, reducing productivity and increasing bugs.

**Our Solution:** Provides an opinionated abstraction layer that handles common flows automatically while allowing customization.

## Differentiators

### Zero Dependencies

Unlike other networking libraries that rely on third-party frameworks like Alamofire, Arachne uses only Apple's Foundation framework. This results in smaller bundle sizes and fewer compatibility issues.

### Backporting with Minimal Overhead

While native async/await is available from iOS 15+, Arachne backports these to iOS 13+ without performance penalties, unlike wrappers that add significant overhead.

### Extensible API Design

Arachne mimics Apple's API for familiarity but allows generating plain URLRequests for uncovered cases, providing flexibility not found in more rigid abstractions.

## Key Features

### Core Features

- **Bytes Task Support:** Asynchronous byte stream handling for efficient data processing.
- **Data Task Support:** Simple data fetching with validation.
- **Download Task Support:** File downloads with progress tracking.
- **Upload Task Support:** File and data uploads.
- **Resumable Downloads:** Pause and resume large file downloads.
- **Download Progress Updates:** Real-time progress monitoring.

### Advanced Features

- **Plugin System:** Extend behavior before and after requests.
- **Custom Request Modification:** Async modifiers for requests.
- **Error Handling:** Standardized error types for networking issues.
- **Decodable Mapping (Planned):** Automatic response decoding to custom types.
