## 1.1.1

- Fixed `reset()` to properly clear running job indexes, preventing stale state from affecting subsequent job execution.
- Fixed bug where running jobs would increment the internal index after `reset()` was called, making the class execute jobs out of order in some cases.

## 1.1.0

- Added `getNextIndex()` method to retrieve the next job index without adding a job.

## 1.0.0

- Initial version.
