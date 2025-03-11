/// Represents a job with an associated index.
class Job {
  /// The index of the job.
  final int index;

  /// The function representing the job.
  final Future<void> Function() fn;

  /// Creates a job with the specified index and function.
  Job({required this.index, required this.fn});
}
