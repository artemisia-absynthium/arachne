# ``Arachne/ArachneProvider``

## Topics

### Init

- ``init(urlSession:)``
- ``with(requestModifier:)``
- ``with(plugins:)``

### Performing asynchronous requests

- ``data(_:session:)``
- ``data(_:timeoutInterval:session:)``
- ``download(_:session:)``
- ``download(_:timeoutInterval:session:)``

### Performing interruptible downloads

- ``download(_:sessionConfiguration:didWriteData:didCompleteTask:)``
- ``download(_:withResumeData:sessionConfiguration:didResumeDownload:didWriteData:didCompleteTask:)``

### Just build your URLRequest

- ``finalRequest(target:)``
- ``buildRequest(target:timeoutInterval:)``
- ``buildCompleteRequest(target:timeoutInterval:)``
