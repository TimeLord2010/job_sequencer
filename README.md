The JobSequencer class is designed to manage and execute a sequence of jobs in a specific order.
It ensures that each job is executed only after the previous one has finished, maintaining a controlled flow of operations.
This is particularly useful in scenarios where tasks must be performed sequentially without overlap, but you don't have all the data to start the processing immediately.

This can happen, for example, while streaming, where the data may not be received in the right order.

A job is a function without paramters that returns `Future<void>`.

Jobs are executed based on their indices. If a job with a higher index is added before the required preceding jobs, it remains idle until all prior jobs have been executed. For instance, if the initial index is 0 and only job 5 is added, it will not execute until jobs 0 through 4 have been added and completed.

# Simple example

```dart
final jobSequencer = JobSequencer(
    initialIndex: 0,
);

Job create(int index) async {
    return Job(
        fn: () async => print('Executing job $index'),
        index: index,
    );
}

// Add job 5 first - this will remain idle initially
jobSequencer.addJob(create(5));

// Add job 0 - this will start execution immediately
jobSequencer.addJob(create(0));

// Add job 2 - this will remain idle until job 1 is added and completed
jobSequencer.addJob(create(2));

// Add job 1 - this will execute after job 0
jobSequencer.addJob(create(1));

// Add job 3 - this will execute after job 2
jobSequencer.addJob(create(3));

// Add job 4 - this will execute after job 3
jobSequencer.addJob(create(4));
```