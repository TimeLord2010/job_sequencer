import 'dart:async';

import 'package:job_sequencer/src/data/job.dart';

/// A timer-based implementation that manages the execution of jobs sequentially.
///
/// This implementation uses a periodic timer to check for jobs, which eliminates
/// race conditions that can occur with async recursive approaches. Jobs are
/// executed strictly in sequence, with no concurrent execution.
class JobSequencerTimer {
  /// Delay between each job execution.
  final Duration delay;

  /// The index of the first job to run.
  final int initialIndex;

  /// How often to check for the next job (defaults to 5ms for responsiveness).
  final Duration checkInterval;

  JobSequencerTimer({
    this.delay = const Duration(milliseconds: 50),
    this.initialIndex = 0,
    this.checkInterval = const Duration(milliseconds: 5),
  }) : _currentIndex = initialIndex {
    _startTimer();
  }

  /// The current index of the job to be executed.
  int _currentIndex;

  /// The currently executing job's index, or null if no job is running.
  int? _executingIndex;

  /// Generation counter to invalidate jobs after reset.
  int _generation = 0;

  /// A map to hold jobs that are waiting to be executed.
  final Map<int, Job> _pendingJobs = {};

  /// The timer that periodically checks for jobs to execute.
  Timer? _timer;

  /// Whether the sequencer has been disposed.
  bool _disposed = false;

  /// Completer for the currently executing job.
  Completer<void>? _executionCompleter;

  bool get hasPendingJobs {
    return _pendingJobs.isNotEmpty || _executingIndex != null;
  }

  /// Returns the next index that will be used for job execution.
  int getNextIndex() {
    if (_pendingJobs.isEmpty && _executingIndex == null) {
      return initialIndex;
    }
    var last =
        _pendingJobs.keys.lastOrNull ?? _executingIndex ?? (initialIndex - 1);
    return last + 1;
  }

  /// Clears the pending jobs and resets the state.
  void reset() {
    _currentIndex = initialIndex;
    _executingIndex = null;
    _pendingJobs.clear();
    _generation++;
    _executionCompleter?.complete();
    _executionCompleter = null;
  }

  /// Waits for all jobs to finish and resets the state.
  Future<void> waitAndReset() async {
    while (hasPendingJobs) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    reset();
  }

  /// Adds a job to the manager.
  ///
  /// The job will be picked up by the timer when its turn comes.
  void addJob(Job job) {
    if (_disposed) {
      throw StateError('Cannot add job to disposed JobSequencerTimer');
    }

    // Check if index already exists
    if (_pendingJobs.containsKey(job.index) || _executingIndex == job.index) {
      throw Exception('Index for job already exists: ${job.index}');
    }

    // Add the job to the pending jobs map
    _pendingJobs[job.index] = job;
  }

  /// Creates a job with the given index and adds it.
  ///
  /// If no index is given, one is deduced based on the current state.
  Job createAndAdd(Future<void> Function() fn, [int? index]) {
    index ??= getNextIndex();
    var job = Job(fn: fn, index: index);
    addJob(job);

    return job;
  }

  /// Starts the periodic timer that checks for jobs to execute.
  void _startTimer() {
    _timer = Timer.periodic(checkInterval, (_) => _checkAndExecuteJob());
  }

  /// Checks if the next job in sequence is available and executes it.
  void _checkAndExecuteJob() {
    // Don't start a new job if one is already executing
    if (_executingIndex != null) {
      return;
    }

    // Check if the job at the current index exists
    final job = _pendingJobs.remove(_currentIndex);
    if (job == null) {
      return;
    }

    // Mark this index as executing
    _executingIndex = _currentIndex;
    final jobGeneration = _generation;
    _executionCompleter = Completer<void>();

    // Execute the job asynchronously
    _executeJob(job, jobGeneration);
  }

  /// Executes a job asynchronously.
  Future<void> _executeJob(Job job, int jobGeneration) async {
    try {
      // Execute the job function
      await job.fn();

      // Wait for the specified delay
      await Future.delayed(delay);
    } catch (e) {
      // Job failed, but we still need to move forward
      // You might want to add error handling/logging here
      // Not rethrowing to allow the sequence to continue
    } finally {
      // Only update state if this job hasn't been invalidated by reset
      if (jobGeneration == _generation && !_disposed) {
        _currentIndex++;
        _executingIndex = null;
        _executionCompleter?.complete();
        _executionCompleter = null;
      }
    }
  }

  /// Disposes the timer and cleans up resources.
  ///
  /// After calling dispose, this JobSequencerTimer cannot be used anymore.
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _pendingJobs.clear();
    _executionCompleter?.complete();
    _executionCompleter = null;
  }

  /// Waits for all pending jobs to complete, then disposes.
  Future<void> waitAndDispose() async {
    while (hasPendingJobs && !_disposed) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    dispose();
  }
}
