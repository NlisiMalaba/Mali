// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(categoriesForType)
final categoriesForTypeProvider = CategoriesForTypeFamily._();

final class CategoriesForTypeProvider
    extends $FunctionalProvider<List<Category>, List<Category>, List<Category>>
    with $Provider<List<Category>> {
  CategoriesForTypeProvider._({
    required CategoriesForTypeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'categoriesForTypeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoriesForTypeHash();

  @override
  String toString() {
    return r'categoriesForTypeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Category>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Category> create(Ref ref) {
    final argument = this.argument as String;
    return categoriesForType(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Category> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Category>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CategoriesForTypeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoriesForTypeHash() => r'4c8bb8ed082a4d96b278bfecf48687dfe2db2e32';

final class CategoriesForTypeFamily extends $Family
    with $FunctionalFamilyOverride<List<Category>, String> {
  CategoriesForTypeFamily._()
    : super(
        retry: null,
        name: r'categoriesForTypeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CategoriesForTypeProvider call(String type) =>
      CategoriesForTypeProvider._(argument: type, from: this);

  @override
  String toString() => r'categoriesForTypeProvider';
}

@ProviderFor(categoryById)
final categoryByIdProvider = CategoryByIdFamily._();

final class CategoryByIdProvider
    extends $FunctionalProvider<Category?, Category?, Category?>
    with $Provider<Category?> {
  CategoryByIdProvider._({
    required CategoryByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'categoryByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoryByIdHash();

  @override
  String toString() {
    return r'categoryByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Category?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Category? create(Ref ref) {
    final argument = this.argument as String;
    return categoryById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Category? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Category?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryByIdHash() => r'f85313b6ea29eae05d712fbc99f42a59a6631b85';

final class CategoryByIdFamily extends $Family
    with $FunctionalFamilyOverride<Category?, String> {
  CategoryByIdFamily._()
    : super(
        retry: null,
        name: r'categoryByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CategoryByIdProvider call(String categoryId) =>
      CategoryByIdProvider._(argument: categoryId, from: this);

  @override
  String toString() => r'categoryByIdProvider';
}
