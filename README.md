# BitMap

A data structure for fast set operations on a set of integers, each represented by a bit. Supports multiple implementations optimized for different use cases:

- **BitMap** - Stable array bitmap optimized for dense datasets below 2^32 bits
- **SparseBitMap32** - Sparse bitmap for 32-bit values - more memory and compute efficient as each bit does not need to be stored explicitly
- **SparseBitMap64** - Two-level sparse bitmap for 64-bit values

## Install

```
mops add bit-map
```

## Usage


```motoko
import BitMap "mo:bit-map";
import SparseBitMap32 "mo:bit-map/SparseBitMap32";
import SparseBitMap64 "mo:bit-map/SparseBitMap64";

let bitmap1 = BitMap.new(8); // 8 is the initial capacity

BitMap.add(bitmap1, 1);
assert BitMap.get(bitmap1, 1) == true;
assert BitMap.size(bitmap1) == 1;

let bitmap2 = BitMap.new(8);
BitMap.set(bitmap2, 64, true);
assert BitMap.get(bitmap2, 64) == true;
assert BitMap.size(bitmap2) == 1;

// Non-mutating operations (return new bitmaps)
let unionBitmap = BitMap.union(bitmap1, bitmap2);
assert BitMap.get(unionBitmap, 1) == true;
assert BitMap.get(unionBitmap, 64) == true;
assert BitMap.size(unionBitmap) == 2;

let intersectBitmap = BitMap.intersect(bitmap1, bitmap2);
assert BitMap.get(intersectBitmap, 1) == false;
assert BitMap.get(intersectBitmap, 64) == false;

// In-place operations (mutate first argument)
BitMap.unionInPlace(bitmap1, bitmap2);
assert BitMap.get(bitmap1, 1) == true;
assert BitMap.get(bitmap1, 64) == true;
assert BitMap.size(bitmap1) == 2;

BitMap.intersectInPlace(bitmap1, bitmap2);
assert BitMap.get(bitmap1, 1) == false;
assert BitMap.get(bitmap1, 64) == true;
assert BitMap.size(bitmap1) == 1;

// Other operations
let differenceBitmap = BitMap.difference(bitmap1, bitmap2);
BitMap.differenceInPlace(bitmap1, bitmap2);
BitMap.clear(bitmap1); // Reset to empty while maintaining capacity
let clone = BitMap.clone(bitmap1);
let array = BitMap.toArray(bitmap1);
```

### Set Operations

- **Non-mutating** (return new bitmaps):
  - `union(bitmap1, bitmap2)` - Union of two bitmaps
  - `intersect(bitmap1, bitmap2)` - Intersection of two bitmaps
  - `difference(bitmap1, bitmap2)` - Difference of two bitmaps

- **In-place** (mutate first argument):
  - `unionInPlace(bitmap1, bitmap2)` - Add bits from bitmap2 to bitmap1
  - `intersectInPlace(bitmap1, bitmap2)` - Keep only common bits in bitmap1
  - `differenceInPlace(bitmap1, bitmap2)` - Remove bits of bitmap2 from bitmap1

- **Multi-way operations**:
  - `multiUnion(iter)` - Union of multiple bitmaps
  - `multiIntersect(iter)` - Intersection of multiple bitmaps

