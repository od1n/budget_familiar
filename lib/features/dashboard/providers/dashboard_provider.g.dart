// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$monthlySummaryHash() => r'8131e069ba9215c7629bcb4f746e5857b810c9f7';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [monthlySummary].
@ProviderFor(monthlySummary)
const monthlySummaryProvider = MonthlySummaryFamily();

/// See also [monthlySummary].
class MonthlySummaryFamily extends Family<AsyncValue<MonthlySummary>> {
  /// See also [monthlySummary].
  const MonthlySummaryFamily();

  /// See also [monthlySummary].
  MonthlySummaryProvider call({
    required String groupId,
  }) {
    return MonthlySummaryProvider(
      groupId: groupId,
    );
  }

  @override
  MonthlySummaryProvider getProviderOverride(
    covariant MonthlySummaryProvider provider,
  ) {
    return call(
      groupId: provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'monthlySummaryProvider';
}

/// See also [monthlySummary].
class MonthlySummaryProvider extends AutoDisposeStreamProvider<MonthlySummary> {
  /// See also [monthlySummary].
  MonthlySummaryProvider({
    required String groupId,
  }) : this._internal(
          (ref) => monthlySummary(
            ref as MonthlySummaryRef,
            groupId: groupId,
          ),
          from: monthlySummaryProvider,
          name: r'monthlySummaryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$monthlySummaryHash,
          dependencies: MonthlySummaryFamily._dependencies,
          allTransitiveDependencies:
              MonthlySummaryFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  MonthlySummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    Stream<MonthlySummary> Function(MonthlySummaryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlySummaryProvider._internal(
        (ref) => create(ref as MonthlySummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<MonthlySummary> createElement() {
    return _MonthlySummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlySummaryProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MonthlySummaryRef on AutoDisposeStreamProviderRef<MonthlySummary> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _MonthlySummaryProviderElement
    extends AutoDisposeStreamProviderElement<MonthlySummary>
    with MonthlySummaryRef {
  _MonthlySummaryProviderElement(super.provider);

  @override
  String get groupId => (origin as MonthlySummaryProvider).groupId;
}

String _$expenseByCategoryHash() => r'945b470ec0477f964b2a9914f3e72e003332abd2';

/// See also [expenseByCategory].
@ProviderFor(expenseByCategory)
const expenseByCategoryProvider = ExpenseByCategoryFamily();

/// See also [expenseByCategory].
class ExpenseByCategoryFamily extends Family<AsyncValue<Map<String, double>>> {
  /// See also [expenseByCategory].
  const ExpenseByCategoryFamily();

  /// See also [expenseByCategory].
  ExpenseByCategoryProvider call({
    required String groupId,
  }) {
    return ExpenseByCategoryProvider(
      groupId: groupId,
    );
  }

  @override
  ExpenseByCategoryProvider getProviderOverride(
    covariant ExpenseByCategoryProvider provider,
  ) {
    return call(
      groupId: provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'expenseByCategoryProvider';
}

/// See also [expenseByCategory].
class ExpenseByCategoryProvider
    extends AutoDisposeStreamProvider<Map<String, double>> {
  /// See also [expenseByCategory].
  ExpenseByCategoryProvider({
    required String groupId,
  }) : this._internal(
          (ref) => expenseByCategory(
            ref as ExpenseByCategoryRef,
            groupId: groupId,
          ),
          from: expenseByCategoryProvider,
          name: r'expenseByCategoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$expenseByCategoryHash,
          dependencies: ExpenseByCategoryFamily._dependencies,
          allTransitiveDependencies:
              ExpenseByCategoryFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  ExpenseByCategoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    Stream<Map<String, double>> Function(ExpenseByCategoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExpenseByCategoryProvider._internal(
        (ref) => create(ref as ExpenseByCategoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<Map<String, double>> createElement() {
    return _ExpenseByCategoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpenseByCategoryProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ExpenseByCategoryRef
    on AutoDisposeStreamProviderRef<Map<String, double>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _ExpenseByCategoryProviderElement
    extends AutoDisposeStreamProviderElement<Map<String, double>>
    with ExpenseByCategoryRef {
  _ExpenseByCategoryProviderElement(super.provider);

  @override
  String get groupId => (origin as ExpenseByCategoryProvider).groupId;
}

String _$recentTransactionsHash() =>
    r'ab9ef30c109febdc27a5aebb8884ecbd186b8fed';

/// See also [recentTransactions].
@ProviderFor(recentTransactions)
const recentTransactionsProvider = RecentTransactionsFamily();

/// See also [recentTransactions].
class RecentTransactionsFamily
    extends Family<AsyncValue<List<TransactionsTableData>>> {
  /// See also [recentTransactions].
  const RecentTransactionsFamily();

  /// See also [recentTransactions].
  RecentTransactionsProvider call({
    required String groupId,
  }) {
    return RecentTransactionsProvider(
      groupId: groupId,
    );
  }

  @override
  RecentTransactionsProvider getProviderOverride(
    covariant RecentTransactionsProvider provider,
  ) {
    return call(
      groupId: provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'recentTransactionsProvider';
}

/// See also [recentTransactions].
class RecentTransactionsProvider
    extends AutoDisposeStreamProvider<List<TransactionsTableData>> {
  /// See also [recentTransactions].
  RecentTransactionsProvider({
    required String groupId,
  }) : this._internal(
          (ref) => recentTransactions(
            ref as RecentTransactionsRef,
            groupId: groupId,
          ),
          from: recentTransactionsProvider,
          name: r'recentTransactionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recentTransactionsHash,
          dependencies: RecentTransactionsFamily._dependencies,
          allTransitiveDependencies:
              RecentTransactionsFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  RecentTransactionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    Stream<List<TransactionsTableData>> Function(RecentTransactionsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecentTransactionsProvider._internal(
        (ref) => create(ref as RecentTransactionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<TransactionsTableData>>
      createElement() {
    return _RecentTransactionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecentTransactionsProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RecentTransactionsRef
    on AutoDisposeStreamProviderRef<List<TransactionsTableData>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _RecentTransactionsProviderElement
    extends AutoDisposeStreamProviderElement<List<TransactionsTableData>>
    with RecentTransactionsRef {
  _RecentTransactionsProviderElement(super.provider);

  @override
  String get groupId => (origin as RecentTransactionsProvider).groupId;
}

String _$monthlyTrendHash() => r'1ffff45ade5725bbdc0d1f4e60333a0a658f7c15';

/// See also [monthlyTrend].
@ProviderFor(monthlyTrend)
const monthlyTrendProvider = MonthlyTrendFamily();

/// See also [monthlyTrend].
class MonthlyTrendFamily extends Family<AsyncValue<List<MonthlyTrendPoint>>> {
  /// See also [monthlyTrend].
  const MonthlyTrendFamily();

  /// See also [monthlyTrend].
  MonthlyTrendProvider call({
    required String groupId,
  }) {
    return MonthlyTrendProvider(
      groupId: groupId,
    );
  }

  @override
  MonthlyTrendProvider getProviderOverride(
    covariant MonthlyTrendProvider provider,
  ) {
    return call(
      groupId: provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'monthlyTrendProvider';
}

/// See also [monthlyTrend].
class MonthlyTrendProvider
    extends AutoDisposeFutureProvider<List<MonthlyTrendPoint>> {
  /// See also [monthlyTrend].
  MonthlyTrendProvider({
    required String groupId,
  }) : this._internal(
          (ref) => monthlyTrend(
            ref as MonthlyTrendRef,
            groupId: groupId,
          ),
          from: monthlyTrendProvider,
          name: r'monthlyTrendProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$monthlyTrendHash,
          dependencies: MonthlyTrendFamily._dependencies,
          allTransitiveDependencies:
              MonthlyTrendFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  MonthlyTrendProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    FutureOr<List<MonthlyTrendPoint>> Function(MonthlyTrendRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyTrendProvider._internal(
        (ref) => create(ref as MonthlyTrendRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<MonthlyTrendPoint>> createElement() {
    return _MonthlyTrendProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyTrendProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MonthlyTrendRef on AutoDisposeFutureProviderRef<List<MonthlyTrendPoint>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _MonthlyTrendProviderElement
    extends AutoDisposeFutureProviderElement<List<MonthlyTrendPoint>>
    with MonthlyTrendRef {
  _MonthlyTrendProviderElement(super.provider);

  @override
  String get groupId => (origin as MonthlyTrendProvider).groupId;
}

String _$activeMonthHash() => r'ceaa0da3cb7f85950498d36d8cafac8cc575f5f5';

/// See also [ActiveMonth].
@ProviderFor(ActiveMonth)
final activeMonthProvider =
    AutoDisposeNotifierProvider<ActiveMonth, DateTime>.internal(
  ActiveMonth.new,
  name: r'activeMonthProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$activeMonthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveMonth = AutoDisposeNotifier<DateTime>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
