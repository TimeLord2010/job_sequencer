import 'dart:async';

import 'package:job_sequencer/src/data/job.dart';

/// Manages the execution of jobs based on their index. A job can only begin
/// if the previous one has finished.
///
/// For this class to work, you need to have a sequencial list of
/// jobs/functions, without gaps.
class JobSequencer {
  /// Delay between each job.
  final Duration delay;

  /// The index of the first job to run.
  ///
  /// If you don't set the correct value to this variable, your jobs will never
  /// run. In other words, you have to have a job with this index.
  final int initialIndex;

  JobSequencer({
    this.delay = const Duration(milliseconds: 50),
    this.initialIndex = 0,
  }) : _currentIndex = initialIndex;

  /// The current index of the job to be executed.
  int _currentIndex;

  final Set<int> _runningIndexes = {};

  /// Generation counter to invalidate running jobs after reset.
  int _generation = 0;

  /// A map to hold jobs that are waiting to be executed.
  final Map<int, Job> _pendingJobs = {};

  bool get hasPendingJobs {
    return _pendingJobs.isNotEmpty || _runningIndexes.isNotEmpty;
  }

  /// Returns the next index that will be used for job execution.
  ///
  /// This is useful for understanding what the next job index will be
  /// without actually adding a job.
  int getNextIndex() {
    if (_pendingJobs.isEmpty && _runningIndexes.isEmpty) {
      return initialIndex;
    }
    var last =
        _pendingJobs.keys.lastOrNull ??
        _runningIndexes.lastOrNull ??
        (initialIndex - 1);
    return last + 1;
  }

  /// Clears the pending jobs.
  ///
  /// Already running jobs will still execute normally, but won't affect
  /// the sequence state after completion.
  void reset() {
    _currentIndex = initialIndex;
    _runningIndexes.clear();
    _pendingJobs.clear();
    _generation++;
  }

  /// Waits for all jobs to finish and resets the state.
  Future<void> waitAndReset() async {
    while (hasPendingJobs) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    reset();
  }

  /// Adds a job to the manager and attempts to execute it if possible.
  void addJob(Job job) {
    // Checking if index already exists
    var indexes = _pendingJobs.keys.toSet();
    if (indexes.contains(job.index) || _runningIndexes.contains(job.index)) {
      throw Exception('Index for job already exists.');
    }

    // Add the job to the pending jobs map.
    _pendingJobs[job.index] = job;

    // Attempt to execute jobs starting from the current index.
    _tryExecuteJobs();
  }

  /// Creates a job with the given index and adds it to the sequencer.
  ///
  /// If no index is given, one is automatically calculated:
  /// - If there are no pending jobs, the index will be [initialIndex].
  /// - Otherwise, pick the last pending index + 1.
  ///
  /// **Warning:** When calling this method rapidly in parallel without providing
  /// an explicit index, there is a race condition where multiple calls may
  /// calculate the same index simultaneously. This can cause jobs to be skipped
  /// or exceptions to be thrown due to duplicate indices.
  ///
  /// To avoid this issue in concurrent scenarios:
  /// - Provide an explicit index parameter, or
  /// - Use the [addJob] method with pre-created [Job] instances
  Job createAndAdd(Future<void> Function() fn, [int? index]) {
    index ??= getNextIndex();
    var job = Job(fn: fn, index: index);
    addJob(job);
    return job;
  }

  /// Attempts to execute jobs in order starting from the current index.
  Future<void> _tryExecuteJobs() async {
    var index = _currentIndex;
    final job = _pendingJobs.remove(index);

    // Aborting if the current index is already running or non existant
    if (job == null) {
      return;
    }

    // Prevending duplicated jobs.
    if (_runningIndexes.contains(index)) {
      throw Exception(
        'Tried to execute job with index already in execution ($index)',
      );
    }

    _runningIndexes.add(index);
    final jobGeneration = _generation;

    // Execute the job function.
    try {
      await job.fn();

      // Wait for the specified delay before executing the next job.
      await Future.delayed(delay);
    } finally {
      _runningIndexes.remove(index);
    }

    // Only increment and continue if this job hasn't been invalidated by reset
    if (jobGeneration == _generation) {
      // Increment the current index after the job is executed.
      _currentIndex++;

      // Try executing the next job in the sequence.
      await _tryExecuteJobs();
    }
  }
}
