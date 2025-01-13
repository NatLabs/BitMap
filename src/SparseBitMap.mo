// import BitMap "lib";
// import Map "mo:map/Map";
// import Set "mo:map/Set";
// import Nat16 "mo:base/Nat16";
// import Nat32 "mo:base/Nat32";
// import Iter "mo:base/Iter";
// import Debug "mo:base/Debug";
// import Buffer "mo:base/Buffer";
// import Array "mo:base/Array";
// import Order "mo:base/Order";
// import Nat "mo:base/Nat";

// import Itertools "mo:itertools/Iter";

// /// A sparse bitmap that implements the roaring bitmap compression scheme.
// /// It uses a combination of bitmaps and arrays to store the data.
// /// This implementation is limited to 32-bit Nat values.

// module SparseBitMap {
//     type BitMap = BitMap.BitMap;
//     type Buffer<T> = Buffer.Buffer<T>;
//     let { nhash } = Set;

//     type FixedSizedSet = [var Nat16]; // [...data, size]

//     // at 4096 elements (4096 * 16 bits = 64k bits) it becomes more memory efficient to use a bitmap
//     let ARRAY_THRESHOLD = 4096;

//     module FixedSizedSet = {

//         let SIZE_INDEX = ARRAY_THRESHOLD;

//         public func size(array : FixedSizedSet) : Nat {
//             Nat16.toNat(array[SIZE_INDEX]);
//         };

//         public func clone(array : FixedSizedSet) : FixedSizedSet {
//             Array.tabulateVar(
//                 array.size(),
//                 func(i : Nat) : Nat16 {
//                     array[i];
//                 },
//             );
//         };

//         public func new() : FixedSizedSet {
//             Array.init<Nat16>(ARRAY_THRESHOLD + 1, 0);
//         };

//         public func vals(array : FixedSizedSet) : Iter.Iter<Nat16> {
//             Iter.map(
//                 Itertools.range(0, size(array)),
//                 func(i : Nat) : Nat16 {
//                     array[i];
//                 },
//             )

//         };

//         public func binarySearch(element : Nat16, buffer : FixedSizedSet) : ?Nat {
//             var low = 0;
//             var high = FixedSizedSet.size(buffer);

//             while (low < high) {
//                 let mid = (low + high) / 2;
//                 let current = buffer.get(mid);
//                 switch (Nat16.compare(element, current)) {
//                     case (#equal) {
//                         return ?mid;
//                     };
//                     case (#less) {
//                         high := mid;
//                     };
//                     case (#greater) {
//                         low := mid + 1;
//                     };
//                 };
//             };

//             ?high;

//         };

//         public func insert(array : FixedSizedSet, index : Nat, elem : Nat16) {
//             let size = FixedSizedSet.size(array);
//             assert index < ARRAY_THRESHOLD and size < ARRAY_THRESHOLD;

//             var i = size;

//             while (i > index) {
//                 array[i] := array[i - 1];
//                 i -= 1;
//             };

//             array[index] := elem;
//             array[SIZE_INDEX] += 1;
//         };

//         public func add(array : FixedSizedSet, elem : Nat16) {
//             let cnt = size(array);
//             assert cnt < ARRAY_THRESHOLD;

//             array[cnt] := elem;
//             array[SIZE_INDEX] += 1;

//         };

//         public func add_dedupe(array : FixedSizedSet, elem : Nat16) {
//             let cnt = size(array);

//             assert cnt < ARRAY_THRESHOLD;

//             switch (binarySearch(elem, array)) {
//                 case (?index) {
//                     if (array[index] == elem) {
//                         return;
//                     };

//                     insert(array, index, elem);
//                 };
//                 case (null) {

//                     array[cnt] := elem;
//                     array[SIZE_INDEX] += 1;

//                 };
//             };

//         };

//         public func remove(array : FixedSizedSet, index : Nat) {
//             let cnt = size(array);
//             assert index < cnt;

//             switch (binarySearch(array[index], array)) {
//                 case (?found_index) {
//                     if (found_index != index) return;
//                 };
//                 case (null) return;
//             };

//             var i = index;

//             while (i < cnt - 1) {
//                 array[i] := array[i + 1];
//                 i += 1;
//             };

//             array[SIZE_INDEX] -= 1;
//         };

//         public module unsafe {
//             public func update_size(array : FixedSizedSet, size : Nat) {
//                 array[SIZE_INDEX] := Nat16.fromNat(size);
//             };

//         };

//     };

//     type FixedSizedMap = ([var ?Container], Set.Set<Nat>); // (containers, filled_positions)

//     module FixedSizedMap {
//         let KEY_SPACE = 65536;
//         let SIZE_INDEX = KEY_SPACE;

//         public func new() : FixedSizedMap {
//             (Array.init<?Container>(KEY_SPACE + 1, null), Set.new<Nat>());
//         };

//         public func size(map : FixedSizedMap) : Nat {
//             Set.size(map.1);
//         };

//         func set_position(map : FixedSizedMap, key : Nat, mark_as_present : Bool) {
//             if (mark_as_present) {
//                 Set.add(map.1, nhash, key);
//             } else {
//                 ignore Set.remove(map.1, nhash, key);
//             };
//         };

//         public func put(map : FixedSizedMap, key : Nat, container : Container) {
//             map.0 [key] := ?container;
//             set_position(map, key, true);
//         };

//         public func remove(map : FixedSizedMap, key : Nat) {
//             map.0 [key] := null;
//             set_position(map, key, false);
//         };

//         public func get(map : FixedSizedMap, key : Nat) : ?Container {
//             assert key < SIZE_INDEX;
//             map.0 [key];
//         };

//         func positions(map : FixedSizedMap) : Iter.Iter<Nat> {
//             Set.keys(map.1);
//         };

//         public func entries(map : FixedSizedMap) : Iter.Iter<(Nat, Container)> {

//             Iter.map<Nat, (Nat, Container)>(
//                 positions(map),
//                 func(key : Nat) : (Nat, Container) {
//                     let container = switch (map.0 [key]) {
//                         case (?container) { container };
//                         case (null) {
//                             Debug.trap("Container should exists in filled position");
//                         };
//                     };

//                     (key, container);
//                 },
//             );
//         };

//         public func clone(map : FixedSizedMap) : FixedSizedMap {
//             let new_map = FixedSizedMap.new();

//             for ((key, container) in entries(map)) {
//                 switch (map.0 [key]) {
//                     case (?container) {
//                         new_map.0 [key] := ?clone_container(container);
//                     };
//                     case (null) {};
//                 };
//             };

//             new_map;
//         };

//     };

//     type Container = {
//         #bitmap : BitMap;
//         #array : FixedSizedSet;
//     };

//     func clone_container(container : Container) : Container {
//         switch (container) {
//             case (#bitmap(bitmap)) {
//                 #bitmap(bitmap.clone());
//             };
//             case (#array(set)) {
//                 #array(FixedSizedSet.clone(set));
//             };
//         };
//     };

//     func convert_array_to_bitmap(array : FixedSizedSet) : BitMap {
//         // Debug.print("Converting array to bitmap");
//         // Debug.print("Array size: " # debug_show (FixedSizedSet.size(array)));
//         // Debug.print("Array: " # debug_show (array));
//         let bitmap = BitMap.BitMap(2 ** 16);

//         for (elem in FixedSizedSet.vals(array)) {
//             bitmap.set(Nat16.toNat(elem), true);
//         };

//         bitmap;

//     };

//     func convert_bitmap_to_array(bitmap : BitMap) : FixedSizedSet {
//         let array = FixedSizedSet.new();

//         for (n in bitmap.vals()) {
//             FixedSizedSet.add(array, Nat16.fromNat(n));
//         };

//         array;

//     };

//     func containers_cmp(a : Container, b : Container) : Order.Order {
//         switch (a, b) {
//             case ((#bitmap(bitmap_a), #bitmap(bitmap_b))) {
//                 Nat.compare(bitmap_a.size(), bitmap_b.size());
//             };
//             case ((#array(array_a), #array(array_b))) {
//                 Nat.compare(FixedSizedSet.size(array_a), FixedSizedSet.size(array_b));
//             };
//             case ((#bitmap(bitmap), #array(array))) { #greater };
//             case ((#array(array), #bitmap(bitmap))) { #less };
//         };
//     };

//     func multi_intersect_containers(containers : Iter.Iter<Container>) : ?Container {
//         let containers_buffer = Buffer.Buffer<Container>(10);
//         for (container in containers) {
//             containers_buffer.add(container);
//         };

//         containers_buffer.sort(containers_cmp);

//         let smallest_container = clone_container(containers_buffer.get(0));

//         for (container in Itertools.skip(containers_buffer.vals(), 1)) {
//             switch (smallest_container, container) {
//                 case ((#bitmap(smallest_bitmap), #bitmap(bitmap))) {
//                     smallest_bitmap.intersect(bitmap);
//                 };
//                 case ((#array(smallest_set), #array(set))) {
//                     array_set_in_place_union(smallest_set, set);
//                 };
//                 case ((#array(set), #bitmap(bitmap))) {
//                     bitmap_array_in_place_intersect(set, bitmap);
//                 };
//                 case (_) Debug.trap("multi_intersect_containers(): invalid container combination");
//             };
//         };

//         switch (smallest_container) {
//             case (#array(set)) {
//                 if (FixedSizedSet.size(set) == 0) return null;
//             };
//             case (#bitmap(bitmap)) {
//                 if (bitmap.size() == 0) return null;
//                 if (bitmap.size() <= ARRAY_THRESHOLD) {
//                     return ? #array(convert_bitmap_to_array(bitmap));
//                 };

//             };

//         };

//         ?smallest_container;

//     };

//     public func multiIntersect(rbitmap_iter : Iter.Iter<SparseBitMap>) : SparseBitMap {
//         let rbitmaps = Iter.toArray(rbitmap_iter);
//         var smallest_bitmap = rbitmaps[0];

//         for (rbitmap in rbitmaps.vals()) {
//             if (rbitmap.size() < smallest_bitmap.size()) {
//                 smallest_bitmap := rbitmap;
//             };
//         };

//         let new_rbitmap = SparseBitMap();

//         let containers = Buffer.Buffer<Container>(10);

//         for ((container_16bit_key, container) in FixedSizedMap.entries(smallest_bitmap.store)) {

//             for (rbitmap in rbitmaps.vals()) {
//                 switch (FixedSizedMap.get(rbitmap.store, container_16bit_key)) {
//                     case (?container) { containers.add(container) };
//                     case (null) {};
//                 };
//             };

//             if (containers.size() == rbitmaps.size()) {
//                 // all rbitmaps must have this container
//                 // if any one is missing, it means the intersection is empty
//                 switch (multi_intersect_containers(containers.vals())) {
//                     case (?container) {
//                         FixedSizedMap.put(new_rbitmap.store, container_16bit_key, container);
//                     };
//                     case (null) {};
//                 };
//             };

//             containers.clear();

//         };

//         new_rbitmap;

//     };

//     public func multi_union_containers(containers : Buffer<Container>) : ?Container {

//         containers.sort(containers_cmp);

//         let largest_container = containers.get(containers.size() - 1);

//         for (container in Itertools.take(containers.vals(), containers.size() - 1)) {
//             switch (container, largest_container) {
//                 case (#bitmap(bitmap), #bitmap(largest_bitmap)) {
//                     largest_bitmap.union(bitmap);
//                 };
//                 case (#array(set), #bitmap(bitmap)) {
//                     for (elem in FixedSizedSet.vals(set)) {
//                         bitmap.set(Nat16.toNat(elem), true);
//                     };
//                 };
//                 case (#array(set), #array(largest_set)) {
//                     array_set_in_place_union(largest_set, set);
//                 };
//                 case (_) Debug.trap("multi_union_containers(): invalid container combination");
//             };
//         };

//         switch (largest_container) {
//             case (#bitmap(bitmap)) {
//                 if (bitmap.size() == 0) return null;
//                 ? #bitmap(bitmap);
//             };
//             case (#array(set)) {
//                 if (FixedSizedSet.size(set) == 0) return null;
//                 if (FixedSizedSet.size(set) < ARRAY_THRESHOLD) {
//                     ? #array(set);
//                 } else {
//                     ? #bitmap(convert_array_to_bitmap(set));
//                 };
//             };
//         };

//     };

//     public func multiUnion(rbitmap_iter : Iter.Iter<SparseBitMap>) : SparseBitMap {
//         let rbitmaps = Iter.toArray(rbitmap_iter);
//         let smallest_bitmap = rbitmaps[0];

//         let new_rbitmap = SparseBitMap();

//         let containers = Buffer.Buffer<Container>(10);

//         for ((container_16bit_key, container) in FixedSizedMap.entries(smallest_bitmap.store)) {

//             for (rbitmap in rbitmaps.vals()) {
//                 switch (FixedSizedMap.get(rbitmap.store, container_16bit_key)) {
//                     case (?container) { containers.add(container) };
//                     case (null) {};
//                 };
//             };

//             if (containers.size() == 1) {
//                 FixedSizedMap.put(new_rbitmap.store, container_16bit_key, clone_container(containers.get(0)));
//             } else if (containers.size() > 1) {
//                 switch (multi_union_containers(containers)) {
//                     case (?union_container) {
//                         FixedSizedMap.put(new_rbitmap.store, container_16bit_key, union_container);
//                     };
//                     case (null) {};
//                 };
//             };

//             containers.clear();

//         };

//         new_rbitmap;

//     };

//     public func fromIter(iter : Iter.Iter<Nat>) : SparseBitMap {
//         let rbitmap = SparseBitMap();

//         for (n in iter) {
//             rbitmap.add(n);
//         };

//         // rbitmap.addAll(iter);

//         rbitmap;

//     };

//     // returns iter in reverse order because we might need to remove those
//     func array_set_intersect(set_a : Buffer<Nat16>, set_b : Buffer<Nat16>) : Buffer<Nat16> {

//         let iter_a = Itertools.peekable(set_a.vals());
//         let iter_b = Itertools.peekable(set_b.vals());

//         let new_set = Buffer.Buffer<Nat16>(ARRAY_THRESHOLD);

//         label calculating_array_intersect loop switch (iter_a.peek(), iter_b.peek()) {
//             case ((?a, ?b)) {
//                 switch (Nat16.compare(a, b)) {
//                     case (#greater) {
//                         ignore iter_a.next();
//                     };
//                     case (#less) {
//                         ignore iter_b.next();
//                     };
//                     case (#equal) {
//                         ignore iter_a.next();
//                         ignore iter_b.next();
//                         new_set.add(a);
//                     };
//                 };
//             };
//             case (_) break calculating_array_intersect;
//         };

//         new_set;
//     };

//     func array_set_in_place_intersect(set_a : FixedSizedSet, set_b : FixedSizedSet) {
//         var i = 0;
//         var j = 0;
//         var k = 0;

//         while (i < FixedSizedSet.size(set_a) and j < FixedSizedSet.size(set_b)) {
//             let a = set_a.get(i);
//             let b = set_b.get(j);

//             switch (Nat16.compare(a, b)) {
//                 case (#greater) {
//                     j += 1;
//                 };
//                 case (#less) {
//                     i += 1;
//                 };
//                 case (#equal) {
//                     set_a.put(k, a);
//                     k += 1;
//                     i += 1;
//                     j += 1;
//                 };
//             };
//         };

//         FixedSizedSet.unsafe.update_size(set_a, k);

//     };

//     func bitmap_array_in_place_intersect(array : FixedSizedSet, bitmap : BitMap) {

//         var i = 0;
//         var k = 0;

//         while (i < FixedSizedSet.size(array)) {
//             let elem = array.get(i);

//             if (bitmap.get(Nat16.toNat(elem))) {
//                 array.put(k, elem);
//                 k += 1;
//             };

//             i += 1;
//         };

//         FixedSizedSet.unsafe.update_size(array, k);

//     };

//     func bitmap_array_in_place_union(bitmap : BitMap, array : FixedSizedSet) {
//         for (elem in FixedSizedSet.vals(array)) {
//             bitmap.set(Nat16.toNat(elem), true);
//         };
//     };

//     public func array_set_in_place_union(set_a : FixedSizedSet, set_b : FixedSizedSet) {
//         var i = FixedSizedSet.size(set_a);
//         var j = FixedSizedSet.size(set_b);

//         // during this scan if the left is greater than the right element, we keep iterating the left
//         // because there is still a chance we might find the right element in the left set
//         // if the left is less than the right element, we insert the right element in the left set
//         label in_place_union while (i > 0 and j < 0) {
//             var a = set_a.get(i - 1);
//             var b = set_b.get(j - 1);

//             switch (Nat16.compare(a, b)) {
//                 case (#greater) {
//                     while (Nat16.compare(a, b) == #greater) {
//                         i -= 1;

//                         if (i == 0) break in_place_union;

//                         a := set_a.get(i - 1);
//                     };
//                 };
//                 case (#less) {
//                     while (Nat16.compare(a, b) == #less) {
//                         FixedSizedSet.insert(set_a, i, b);

//                         if (j == 0) break in_place_union;
//                         j -= 1;
//                     };
//                 };
//                 case (#equal) {
//                     i -= 1;
//                     j -= 1;
//                 };
//             };
//         };

//     };

//     public class SparseBitMap() = self {

//         public let store : FixedSizedMap = FixedSizedMap.new();

//         public func size() : Nat {
//             var cnt = 0;

//             for ((key, container) in FixedSizedMap.entries(self.store)) switch (container) {
//                 case (#bitmap(bitmap)) cnt += bitmap.size();
//                 case (#array(set)) cnt += FixedSizedSet.size(set);
//             };

//             cnt;

//         };

//         public func capacity() : Nat = Nat32.toNat(Nat32.maximumValue);

//         public func clone() : SparseBitMap {
//             let new_rbitmap = SparseBitMap();

//             for ((key, container) in FixedSizedMap.entries(self.store)) {
//                 FixedSizedMap.put(new_rbitmap.store, key, clone_container(container));
//             };

//             new_rbitmap;

//         };

//         public func get(i : Nat) : Bool {
//             let high_bits = Nat16.fromNat32(Nat32.fromNat(i) >> 16);
//             let low_bits = Nat16.fromNat32(Nat32.fromNat(i) & 0xFFFF);

//             switch (FixedSizedMap.get(self.store, Nat16.toNat(high_bits))) {
//                 case (?container) {
//                     switch (container) {
//                         case (#bitmap(bitmap)) {
//                             // Debug.print("get(): high_bits: " # debug_show (high_bits) # " low_bits: " # debug_show (low_bits) # " bitmap size: " # debug_show (bitmap.size()));
//                             bitmap.get(Nat16.toNat(low_bits));
//                         };
//                         case (#array(set)) {
//                             // Debug.print("get(): high_bits: " # debug_show (high_bits) # " low_bits: " # debug_show (low_bits) # " array: " # debug_show (Iter.toArray(Itertools.take(FixedSizedSet.vals(set), FixedSizedSet.size(set)))));

//                             switch (FixedSizedSet.binarySearch(low_bits, set)) {
//                                 case (?index) {
//                                     set.get(index) == low_bits;
//                                 };
//                                 case (null) false;
//                             };
//                         };
//                     };
//                 };
//                 case (null) false;
//             };

//         };

//         func get_or_create_container(key : Nat) : Container {
//             switch (FixedSizedMap.get(self.store, key)) {
//                 case (?container) { container };
//                 case (null) {
//                     let container = #bitmap(BitMap.BitMap(2 ** 16));
//                     FixedSizedMap.put(self.store, key, container);

//                     container;
//                 };
//             };
//         };

//         public func addAll(iter : Iter.Iter<Nat>) {
//             let first = switch (iter.next()) {
//                 case (?first) { first };
//                 case (null) { return };
//             };

//             let n32 = Nat32.fromNat(first);
//             var high_16_bits = Nat32.toNat(n32 >> 16);
//             let low_16_bits : Nat16 = Nat16.fromNat32(n32 & 0xFFFF);

//             var container = get_or_create_container(high_16_bits);

//             container := add_to_container(container, Nat16.fromNat(high_16_bits), low_16_bits);

//             label adding_numbers_from_iter loop switch (iter.next()) {
//                 case (?n) {
//                     let n32 = Nat32.fromNat(n);

//                     let new_high_bits = Nat32.toNat(n32 >> 16);
//                     let low_16_bits = Nat16.fromNat32(n32 & 0xFFFF);

//                     if (high_16_bits != new_high_bits) {
//                         high_16_bits := new_high_bits;

//                         container := get_or_create_container(high_16_bits);
//                     };

//                     container := add_to_container(container, Nat16.fromNat(high_16_bits), low_16_bits);
//                 };
//                 case (null) break adding_numbers_from_iter;
//             };

//         };

//         /// returns the new container after adding the element
//         /// in case the container is converted to a bitmap and the reference passed to this function needs to be updated,
//         func add_to_container(container : Container, high_16_bits : Nat16, low_16_bits : Nat16) : Container {
//             switch (container) {
//                 case (#bitmap(bitmap)) {
//                     bitmap.set(Nat16.toNat(low_16_bits), true);
//                 };
//                 case (#array(set)) {
//                     if (FixedSizedSet.size(set) < ARRAY_THRESHOLD) {

//                         switch (FixedSizedSet.binarySearch(low_16_bits, set)) {
//                             case (?index) {
//                                 if (set.get(index) != low_16_bits) {
//                                     FixedSizedSet.insert(set, index, low_16_bits);
//                                 };
//                             };
//                             case (null) {
//                                 FixedSizedSet.add(set, low_16_bits);
//                             };
//                         };
//                     } else {

//                         let bitmap = convert_array_to_bitmap(set);
//                         bitmap.set(Nat16.toNat(low_16_bits), true);

//                         let new_container = #bitmap(bitmap);
//                         FixedSizedMap.put(self.store, Nat16.toNat(high_16_bits), new_container);

//                         return new_container;
//                     };
//                 };

//             };

//             container;

//         };

//         public func add(n : Nat) {
//             if (n >= capacity()) {
//                 Debug.trap("SparseBitMap.add(): value " # debug_show (n) # " is too large. Maximum value is " # debug_show (capacity()));
//             };

//             let n32 = Nat32.fromNat(n);

//             let high_16_bits : Nat16 = Nat16.fromNat32(n32 >> 16);
//             let low_16_bits : Nat16 = Nat16.fromNat32(n32 & 0xFFFF);

//             let container = get_or_create_container(Nat16.toNat(high_16_bits));

//             ignore add_to_container(container, high_16_bits, low_16_bits);

//         };

//         public func intersect(other : SparseBitMap) {
//             for ((container_16bit_key, container) in FixedSizedMap.entries(self.store)) {
//                 switch (FixedSizedMap.get(other.store, container_16bit_key)) {
//                     case (null) {
//                         FixedSizedMap.remove(self.store, container_16bit_key);
//                     };
//                     case (?other_container) {
//                         switch (container, other_container) {
//                             case ((#bitmap(bitmap), #bitmap(other_bitmap))) {
//                                 bitmap.intersect(other_bitmap);
//                             };
//                             case ((#array(set), #array(other_set))) {
//                                 array_set_in_place_intersect(set, other_set);
//                             };
//                             case ((#bitmap(bitmap), #array(array)) or (#array(array), #bitmap(bitmap))) {
//                                 // in a valid implementation, array conainers should always be smaller than bitmaps
//                                 assert FixedSizedSet.size(array) < bitmap.size();

//                                 bitmap_array_in_place_intersect(array, bitmap);

//                                 FixedSizedMap.put(self.store, container_16bit_key, #array(array));
//                             };
//                         };
//                     };
//                 };
//             };
//         };

//         public func union(other : SparseBitMap) {

//             for ((container_16bit_key, other_container) in FixedSizedMap.entries(other.store)) {
//                 switch (FixedSizedMap.get(self.store, container_16bit_key)) {
//                     case (null) {
//                         FixedSizedMap.put(self.store, container_16bit_key, clone_container(other_container));
//                     };
//                     case (?self_container) {
//                         switch (self_container, other_container) {
//                             case ((#bitmap(bitmap), #bitmap(other_bitmap))) {
//                                 bitmap.union(other_bitmap);
//                             };
//                             case ((#array(set), #array(other_set))) {
//                                 // updates set in place
//                                 array_set_in_place_union(set, other_set);

//                                 if (FixedSizedSet.size(set) >= ARRAY_THRESHOLD) {
//                                     let bitmap = convert_array_to_bitmap(set);
//                                     FixedSizedMap.put(self.store, container_16bit_key, #bitmap(bitmap));
//                                 };
//                             };
//                             case ((#bitmap(bitmap), #array(set)) or (#array(set), #bitmap(bitmap))) {
//                                 // in a valid implementation, array conainers should always be smaller than bitmaps
//                                 assert FixedSizedSet.size(set) < bitmap.size();

//                                 for (elem in FixedSizedSet.vals(set)) {
//                                     bitmap.set(Nat16.toNat(elem), true);
//                                 };

//                                 FixedSizedMap.put(self.store, container_16bit_key, #bitmap(bitmap));

//                             };
//                         };
//                     };
//                 };
//             };
//         };

//         public func vals() : Iter.Iter<Nat> {
//             Itertools.flatten(
//                 Iter.map<(Nat, Container), Iter.Iter<Nat>>(
//                     FixedSizedMap.entries(self.store),
//                     func(high_16bit_key : Nat, container : Container) : Iter.Iter<Nat> {
//                         let container_iter = switch (container) {
//                             case (#bitmap(bitmap)) {
//                                 Iter.map(bitmap.vals(), Nat16.fromNat);
//                             };
//                             case (#array(set)) {
//                                 set.vals();
//                             };

//                         };

//                         Iter.map<Nat16, Nat>(
//                             container_iter,
//                             func(low_16bit : Nat16) : Nat {
//                                 let n32 = Nat32.fromNat(high_16bit_key) << 16 | Nat32.fromNat16(low_16bit);
//                                 Nat32.toNat(n32);
//                             },
//                         );
//                     },
//                 )
//             );
//         };

//     };

// };
