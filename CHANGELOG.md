## 0.0.4

Features:

  - The routing key is now sent to #work along with the message
  - Workers now log when they publish a message
  - Test guarantors can be used without blocks
  - Amount of worker/publisher threads can be set via env variables

## 0.0.3

Features:

  - Overhauled configuration (breaking change)
  - Queues now purged before first cucumber scenario

Code gardening:

  - Decoupling logic from concurrency for better testability
  - Added tests

## 0.0.2

Features:

  - Rake task added
