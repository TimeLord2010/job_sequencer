import 'package:job_sequencer/job_sequencer.dart';
import 'package:job_sequencer/src/data/job.dart';
import 'package:test/test.dart';

void main() {
  group('JobSequencer', () {
    test('should execute jobs in order', () async {
      final jobSequencer = JobSequencer(delay: Duration(milliseconds: 10));
      final executionOrder = <int>[];

      // Define some mock jobs
      final job1 = Job(fn: () async => executionOrder.add(1), index: 0);
      final job2 = Job(fn: () async => executionOrder.add(2), index: 1);
      final job3 = Job(fn: () async => executionOrder.add(3), index: 2);

      // Add jobs to the sequencer
      jobSequencer.addJob(job1);
      jobSequencer.addJob(job2);
      jobSequencer.addJob(job3);

      // Wait for all jobs to complete
      await Future.delayed(Duration(milliseconds: 200));

      // Verify the execution order
      expect(executionOrder, [1, 2, 3]);
    });

    test('should create and add jobs with deduced index', () async {
      final jobSequencer = JobSequencer();
      final executionOrder = <int>[];

      // Create and add jobs without specifying an index
      jobSequencer.createAndAdd(() async => executionOrder.add(1));
      jobSequencer.createAndAdd(() async => executionOrder.add(2));

      // Wait for all jobs to complete
      await Future.delayed(Duration(milliseconds: 200));

      // Verify the execution order
      expect(executionOrder, [1, 2]);
    });
  });
}
