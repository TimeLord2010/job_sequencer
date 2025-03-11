import 'dart:math';

import 'package:job_sequencer/job_sequencer.dart';
import 'package:job_sequencer/src/data/job.dart';

Future<void> main() async {
  // Create an instance of JobSequencer
  final jobSequencer = JobSequencer();

  // Define a simple job function
  Future<void> printJob(int jobNumber) async {
    print('Executing job $jobNumber');
    var rand = Random();
    await Future.delayed(Duration(milliseconds: rand.nextInt(1000)));
    print('Executed job $jobNumber');
  }

  Job createJob(int i) {
    return Job(fn: () async => printJob(i), index: i);
  }

  // Create and add jobs to the sequencer
  jobSequencer.addJob(createJob(0));
  jobSequencer.addJob(createJob(1));
  jobSequencer.addJob(createJob(2));
  jobSequencer.addJob(createJob(3));

  await jobSequencer.waitAndReset();

  jobSequencer.createAndAdd(() async => await printJob(0));
  jobSequencer.createAndAdd(() async => await printJob(1));
  jobSequencer.createAndAdd(() async => await printJob(2));
  jobSequencer.createAndAdd(() async => await printJob(3));
}
