import 'package:job_sequencer/job_sequencer.dart';
import 'package:test/test.dart';

void main() {
  group('JobSequencerTimer', () {
    late JobSequencerTimer sequencer;

    setUp(() {
      sequencer = JobSequencerTimer(
        delay: Duration(milliseconds: 10),
        checkInterval: Duration(milliseconds: 5),
      );
    });

    tearDown(() {
      sequencer.dispose();
    });

    test('executes jobs in sequence', () async {
      final executionOrder = <int>[];

      for (int i = 0; i < 5; i++) {
        sequencer.createAndAdd(() async {
          executionOrder.add(i);
        });
      }

      await sequencer.waitAndReset();

      expect(executionOrder, [0, 1, 2, 3, 4]);
    });

    test('no jobs are skipped when added rapidly', () async {
      final executionOrder = <int>[];

      // Add jobs rapidly with small delays (simulating audio chunks)
      for (int i = 0; i < 10; i++) {
        sequencer.createAndAdd(() async {
          executionOrder.add(i);
        });
        await Future.delayed(Duration(milliseconds: 5));
      }

      await sequencer.waitAndReset();

      expect(executionOrder, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('executes jobs sequentially, not concurrently', () async {
      int concurrentExecutions = 0;
      int maxConcurrent = 0;

      for (int i = 0; i < 5; i++) {
        sequencer.createAndAdd(() async {
          concurrentExecutions++;
          maxConcurrent =
              concurrentExecutions > maxConcurrent
                  ? concurrentExecutions
                  : maxConcurrent;

          await Future.delayed(Duration(milliseconds: 20));

          concurrentExecutions--;
        });
      }

      await sequencer.waitAndReset();

      expect(maxConcurrent, 1, reason: 'Only one job should execute at a time');
    });

    test('getNextIndex returns correct value', () {
      expect(sequencer.getNextIndex(), 0);

      sequencer.createAndAdd(() async {});
      expect(sequencer.getNextIndex(), 1);

      sequencer.createAndAdd(() async {});
      expect(sequencer.getNextIndex(), 2);
    });

    test('hasPendingJobs returns correct state', () async {
      expect(sequencer.hasPendingJobs, false);

      sequencer.createAndAdd(() async {
        await Future.delayed(Duration(milliseconds: 20));
      });

      expect(sequencer.hasPendingJobs, true);

      await sequencer.waitAndReset();

      expect(sequencer.hasPendingJobs, false);
    });

    test('reset clears pending jobs', () async {
      for (int i = 0; i < 5; i++) {
        sequencer.createAndAdd(() async {
          await Future.delayed(Duration(milliseconds: 100));
        });
      }

      // Wait a bit for first job to start
      await Future.delayed(Duration(milliseconds: 20));

      sequencer.reset();

      expect(sequencer.hasPendingJobs, false);
      expect(sequencer.getNextIndex(), 0);
    });

    test('throws when adding job with duplicate index', () {
      sequencer.createAndAdd(() async {}, 0);

      expect(() => sequencer.createAndAdd(() async {}, 0), throwsException);
    });

    test('throws when adding job to disposed sequencer', () {
      sequencer.dispose();

      expect(
        () => sequencer.createAndAdd(() async {}),
        throwsA(isA<StateError>()),
      );
    });

    test('waitAndDispose waits for jobs to complete', () async {
      final executionOrder = <int>[];

      for (int i = 0; i < 3; i++) {
        sequencer.createAndAdd(() async {
          executionOrder.add(i);
          await Future.delayed(Duration(milliseconds: 20));
        });
      }

      await sequencer.waitAndDispose();

      expect(executionOrder, [0, 1, 2]);
      expect(sequencer.hasPendingJobs, false);
    });

    test('handles job execution errors gracefully', () async {
      final executionOrder = <int>[];

      sequencer.createAndAdd(() async {
        executionOrder.add(0);
      });

      sequencer.createAndAdd(() async {
        executionOrder.add(1);
        throw Exception('Test error');
      });

      sequencer.createAndAdd(() async {
        executionOrder.add(2);
      });

      // Wait for jobs to complete (second job will throw)
      // We expect the error to be thrown, but other jobs should continue
      await Future.delayed(Duration(milliseconds: 100));

      // Job 0 executes, job 1 throws (and is recorded), job 2 should execute
      expect(executionOrder.length, 3);
      expect(executionOrder, [0, 1, 2]);
    });

    test('maintains sequence with mixed job durations', () async {
      final executionOrder = <int>[];

      sequencer.createAndAdd(() async {
        await Future.delayed(Duration(milliseconds: 50));
        executionOrder.add(0);
      });

      sequencer.createAndAdd(() async {
        await Future.delayed(Duration(milliseconds: 5));
        executionOrder.add(1);
      });

      sequencer.createAndAdd(() async {
        await Future.delayed(Duration(milliseconds: 30));
        executionOrder.add(2);
      });

      await sequencer.waitAndReset();

      expect(
        executionOrder,
        [0, 1, 2],
        reason: 'Jobs should execute in order despite different durations',
      );
    });
  });
}
