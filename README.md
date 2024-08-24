# BitMap

A data structure for fast set operations on a set of integers each represented by a bit.

## Install

```
mops add bit-map
```

## Usage

```motoko
    import BitMap "mo:bit-map";

    let bitmap = BitMap.BitMap(8); // 8 is the init capacity of the bitmap

    bitmap.set(1, true);
    assert bitmap.get(1) == true;
    assert bitmap.size() == 1;

    let bitmap2 = BitMap.BitMap(8);
    bitmap2.set(64, true);
    assert bitmap2.get(64) == true;
    assert bitmap2.size() == 1;

    bitmap.union(bitmap2); // in-place union, bitmap2 is not changed

    assert bitmap.get(1) == true;
    assert bitmap.get(64) == true;
    assert bitmap.size() == 2;

    bitmap.intersect(bitmap2); // in-place intersect

    assert bitmap.get(1) == false;
    assert bitmap.get(64) == true;
    assert bitmap.size() == 1;

```
