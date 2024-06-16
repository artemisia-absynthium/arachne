# ``Arachne``

Arachne is a lightweight, minimalistic, zero dependencies networking layer for apps using Swift Concurrency (async/await) developed in Swift, that provides an opinionated abstraction layer to remove boilerplate code.

## Overview

Arachne aims to backport async/await [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession) tasks to macOS 10.15, iOS 13, iPadOS 13, tvOS 13 and watchOS 7, while the availability of their native counterpart in the Foundation framework is iOS 15.0+, iPadOS 15.0+, macOS 12.0+, Mac Catalyst 15.0+, tvOS 15.0+, watchOS 8.0+.

## Topics

### Creating your service

- <doc:GettingStarted>
- ``ArachneService``
- ``HttpMethod``

### Making requests

- ``ArachneProvider``

### Extend requests behavior

- ``ArachnePlugin``

### Errors

- ``ARError``
