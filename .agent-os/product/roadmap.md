# Product Roadmap

## Phase 0: Already Completed

**Goal:** Establish core networking functionalities with backporting to older OS versions.
**Success Criteria:** All listed features implemented and tested, with code coverage above 80%.

### Features

- [x] Bytes task support - Asynchronous byte stream handling `[M]`
- [x] Data task support - Simple data fetching with validation `[M]`
- [x] Download task support - File downloads `[M]`
- [x] Upload task support - File and data uploads `[M]`
- [x] Resumable downloads - Pause and resume large files `[L]`
- [x] Download progress updates - Real-time monitoring `[S]`

### Dependencies

- Foundation framework

## Phase 1: Enhancements and Testing

**Goal:** Add upload capabilities and improve testing.
**Success Criteria:** New features implemented, unit tests passing, documentation updated.

### Features

- [ ] Resumable upload support - Pause and resume uploads `[L]`
- [ ] Upload progress updates - Real-time monitoring `[S]`
- [ ] Unit tests for resumable download - Comprehensive testing `[M]`

### Dependencies

- Existing core features

## Phase 2: Advanced Features

**Goal:** Expand to more networking use cases and conveniences.
**Success Criteria:** Features integrated, examples provided in docs.

### Features

- [ ] Web sockets support - Real-time bidirectional communication `[XL]`
- [ ] Decodable mapping functions - Automatic response to custom types `[M]`
- [ ] Niche use cases (e.g., multipart form data, streaming uploads) - Based on community feedback `[L]`

### Dependencies

- Phase 1 completions
