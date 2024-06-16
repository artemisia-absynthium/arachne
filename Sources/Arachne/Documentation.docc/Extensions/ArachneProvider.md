# ``Arachne/ArachneProvider``

## Topics

### Init

- ``init(urlSession:)``
- ``with(requestModifier:)``
- ``with(plugins:)``

### Performing asynchronous requests

- ``bytes(_:session:)``
- ``data(_:session:)``
- ``data(_:timeoutInterval:session:)``
- ``download(_:session:)``
- ``download(_:timeoutInterval:session:)``
- ``upload(_:session:from:)``
- ``upload(_:session:fromFile:)``

### Performing resumable downloads

- ``download(_:sessionConfiguration:didWriteData:didCompleteTask:)``
- ``download(_:withResumeData:sessionConfiguration:didResumeDownload:didWriteData:didCompleteTask:)``

### Just build your URLRequest

- ``urlRequest(for:)``
- ``buildRequest(target:timeoutInterval:)``
- ``buildCompleteRequest(target:timeoutInterval:)``
