import 'dart:async';
import 'dart:developer' as dev;

enum EventPriority { lowes, low, normal, high, highest }

abstract class Event {
  Event({DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();

  final DateTime timestamp;

  String get type => '$runtimeType';

  bool get isCancellable => false;

  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (isCancellable) _cancelled = true;
  }

  @override
  String toString() => '$type @ $timestamp';
}

class EventSubscription<T extends Event> {
  EventSubscription({
    required this.handler,
    required this.priority,
    required this.id,
    this.filter,
  });

  final void Function(T) handler;
  final EventPriority priority;
  final String id;
  final bool Function(T)? filter;

  bool isActive = true;

  void cancel() {
    isActive = false;
  }

  void execute(T event) {
    if (!isActive) return;
    if (filter != null && !filter!(event)) return;
    handler(event);
  }
}

class EventBus {
  EventBus({this.enableLogging = false});

  final bool enableLogging;

  final Map<Type, List<EventSubscription>> _subscriptions = {};

  int _subscriptionIdCounter = 0;

  final Map<Type, int> _eventCounts = {};
  final Map<Type, int> _handlerExecutionCounts = {};

  final StreamController<Event> _eventStreamController =
      StreamController<Event>.broadcast();

  Stream<Event> get eventStream => _eventStreamController.stream;

  EventSubscription<T> subscribe<T extends Event>(
    void Function(T) handler, {
    EventPriority priority = EventPriority.normal,
    bool Function(T)? filter,
  }) {
    final subscription = EventSubscription<T>(
      handler: handler,
      priority: priority,
      id: 'sub_${_subscriptionIdCounter++}',
      filter: filter,
    );

    _subscriptions.putIfAbsent(T, () => []);
    _subscriptions[T]!.add(subscription);

    _subscriptions[T]!.sort(
      (a, b) => b.priority.index.compareTo(a.priority.index),
    );

    if (enableLogging) {
      dev.log(
        'EventBus: Subscribed ${subscription.id} to $T with priority ${priority.name}',
      );
    }

    return subscription;
  }

  List<EventSubscription> subscribeMultiple(
    List<Type> eventTypes,
    void Function(Event) handler, {
    EventPriority priority = EventPriority.normal,
  }) => eventTypes
      .map((type) => subscribe<Event>(handler, priority: priority))
      .toList();

  void unsubscribe<T extends Event>(EventSubscription<T> subscription) {
    subscription.cancel();
    _subscriptions[T]?.removeWhere((sub) => sub.id == subscription.id);

    if (enableLogging) {
      dev.log('EventBus: Unsubscribed ${subscription.id} from $T');
    }
  }

  void unsubscribeAll<T extends Event>() {
    final subs = _subscriptions[T];
    if (subs != null) {
      for (final sub in subs) {
        sub.cancel();
      }
      _subscriptions.remove(T);

      if (enableLogging) {
        dev.log('EventBus: Unsubscribed all handlers from $T');
      }
    }
  }

  void dispatch<T extends Event>(T event) {
    _eventCounts[T] = (_eventCounts[T] ?? 0) + 1;

    if (enableLogging) {
      dev.log('EventBus: Dispatching $event');
    }

    final subscriptions = _subscriptions[T];
    if (subscriptions != null && subscriptions.isNotEmpty) {
      final activeSubscriptions = subscriptions
          .where((s) => s.isActive)
          .toList();

      for (final subscription in activeSubscriptions) {
        if (event.isCancellable && event.isCancelled) {
          if (enableLogging) {
            dev.log('EventBus: Event cancelled, stopping propagation');
          }
          break;
        }

        try {
          subscription.execute(event);
          _handlerExecutionCounts[T] = (_handlerExecutionCounts[T] ?? 0) + 1;
        } on Exception catch (e, stackTrace) {
          dev.log('EventBus: Error in event handler for $T: $e');
          dev.log('$stackTrace');
        }
      }
    }

    if (T != Event) {
      final genericSubscriptions = _subscriptions[Event];
      if (genericSubscriptions != null && genericSubscriptions.isNotEmpty) {
        final activeSubscriptions = genericSubscriptions
            .where((s) => s.isActive)
            .toList();

        for (final subscription in activeSubscriptions) {
          if (event.isCancellable && event.isCancelled) break;

          try {
            subscription.execute(event);
          } on Exception catch (e, stackTrace) {
            dev.log('EventBus: Error in generic event handler: $e');
            dev.log('$stackTrace');
          }
        }
      }
    }

    if (!_eventStreamController.isClosed) {
      _eventStreamController.add(event);
    }
  }

  void dispatchAll(List<Event> events) => events.forEach(dispatch);

  Map<String, dynamic> getStatistics() => {
    'totalEventTypes': _eventCounts.length,
    'totalEventsDispatched': _eventCounts.values.fold<int>(
      0,
      (a, b) => a + b,
    ),
    'totalHandlerExecutions': _handlerExecutionCounts.values.fold<int>(
      0,
      (a, b) => a + b,
    ),
    'eventCounts': Map.fromEntries(
      _eventCounts.entries.map((e) => MapEntry('${e.key}', e.value)),
    ),
    'activeSubscriptions': Map.fromEntries(
      _subscriptions.entries.map((e) => MapEntry('${e.key}', e.value.length)),
    ),
  };

  void clearStatistics() {
    _eventCounts.clear();
    _handlerExecutionCounts.clear();
  }

  void reset() {
    for (final subs in _subscriptions.values) {
      for (final sub in subs) {
        sub.cancel();
      }
    }

    _subscriptions.clear();
    clearStatistics();

    if (enableLogging) dev.log('EventBus: Reset complete');
  }

  Future<void> dispose() async {
    reset();

    await _eventStreamController.close();
  }

  int getSubscriptionCount<T extends Event>() =>
      _subscriptions[T]?.where((s) => s.isActive).length ?? 0;

  bool hasSubscriptions<T extends Event>() => getSubscriptionCount<T>() > 0;
}

class ScopedEventBus {
  ScopedEventBus(this.eventBus);

  final EventBus eventBus;
  final List<EventSubscription> _subscriptions = [];

  EventSubscription<T> subscribe<T extends Event>(
    void Function(T) handler, {
    EventPriority priority = EventPriority.normal,
    bool Function(T)? filter,
  }) {
    final subscription = eventBus.subscribe<T>(
      handler,
      priority: priority,
      filter: filter,
    );
    _subscriptions.add(subscription);

    return subscription;
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }

    _subscriptions.clear();
  }
}
