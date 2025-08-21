# ``Arachne/ArachneProvider``

## Topics

### Init

- ``init(urlSession:)``
- ``with(requestModifier:)``
- ``with(plugins:)``

### Performing asynchronous requests

- ``bytes(_:session:)``
- ``data(_:session:)``
- ``download(_:session:)``
- ``upload(_:session:from:)``
- ``upload(_:session:fromFile:)``

### Performing resumable downloads

- ``download(_:withResumeData:sessionConfiguration:didResumeDownload:didWriteData:didCompleteTask:)``

### Just build your URLRequest

- ``urlRequest(for:)``
