/// Compare the lists [listA] and [listB], using [itemEqual] to compare
/// list elements.
bool listEqual<T>(
    List<T>? listA, List<T>? listB, bool Function(T a, T b) itemEqual) {
  if (listA == null) {
    return listB == null;
  }
  if (listB == null) {
    return false;
  }
  if (listA.length != listB.length) {
    return false;
  }
  for (var i = 0; i < listA.length; i++) {
    if (!itemEqual(listA[i], listB[i])) {
      return false;
    }
  }
  return true;
}

/// Compare the maps [mapA] and [mapB], using [valueEqual] to compare map
/// values.
bool mapEqual<K, V>(
    Map<K, V>? mapA, Map<K, V>? mapB, bool Function(V a, V b) valueEqual) {
  if (mapA == null) {
    return mapB == null;
  }
  if (mapB == null) {
    return false;
  }
  if (mapA.length != mapB.length) {
    return false;
  }
  for (var entryA in mapA.entries) {
    var key = entryA.key;
    var valueA = entryA.value;
    var valueB = mapB[key];
    if (valueB == null || !valueEqual(valueA, valueB)) {
      return false;
    }
  }
  return true;
}