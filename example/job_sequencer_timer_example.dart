import 'dart:math';

import 'package:job_sequencer/job_sequencer.dart';

/// Example demonstrating the timer-based JobSequencer implementation.
///
/// This implementation eliminates race conditions by using a periodic timer
/// to check for jobs, ensuring strict sequential execution.
Future<void> main() async {
  // Create an instance of JobSequencerTimer with a 10ms delay
  final jobSequencer = JobSequencerTimer(
    delay: Duration(milliseconds: 10),
    checkInterval: Duration(milliseconds: 5),
  );

  print('=== Timer-based JobSequencer Example ===\n');

  // Define a simple job function
  Future<void> printJob(int jobNumber) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] Executing job $jobNumber');

    // Simulate variable work time
    var rand = Random();
    await Future.delayed(Duration(milliseconds: rand.nextInt(100)));

    print('[$timestamp] Completed job $jobNumber');
  }

  print('--- Test 1: Adding jobs rapidly ---');
  // Add jobs rapidly (simulating the audio player scenario)
  for (int i = 0; i < 5; i++) {
    jobSequencer.createAndAdd(() => printJob(i));
    // Small delay between additions (like your audio chunks)
    await Future.delayed(Duration(milliseconds: 30));
  }

  // Wait for all jobs to complete
  await jobSequencer.waitAndReset();

  print('\n--- Test 2: Adding all jobs at once ---');
  // Add multiple jobs at once
  for (int i = 0; i < 5; i++) {
    jobSequencer.createAndAdd(() => printJob(i));
  }

  // Wait and dispose when done
  await jobSequencer.waitAndDispose();

  print('\n=== Example completed ===');
}
