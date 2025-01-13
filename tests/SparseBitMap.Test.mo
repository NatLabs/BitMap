// import Debug "mo:base/Debug";
// import Iter "mo:base/Iter";
// import { test; suite; skip } "mo:test";
// import Fuzz "mo:fuzz";
// import Buffer "mo:base/Buffer";
// import Nat "mo:base/Nat";
// import Set "mo:map/Set";

// import SparseBitMap "../src/SparseBitMap";

// let fuzz = Fuzz.Fuzz();

// let limit = 10_000;

// let inputs = [
//     Buffer.Buffer<Nat>(limit),
//     Buffer.Buffer<Nat>(limit),
//     Buffer.Buffer<Nat>(limit),
// ];

// let sets = [
//     Set.new<Nat>(),
//     Set.new<Nat>(),
//     Set.new<Nat>(),
// ];

// let fullset = Set.new<Nat>();
// let intersect_set = Set.new<Nat>();
// let { nhash } = Set;

// for (i in Iter.range(0, limit)) {
//     let n1 = fuzz.nat.randomRange(0, 1_000_000);
//     let n2 = fuzz.nat.randomRange(0, 1_000_000);
//     let n3 = fuzz.nat.randomRange(0, 1_000_000);

//     inputs[0].add(n1);
//     inputs[1].add(n2);
//     inputs[2].add(n3);

//     Set.add(sets[0], nhash, n1);
//     Set.add(sets[1], nhash, n2);
//     Set.add(sets[2], nhash, n3);

//     Set.add(fullset, nhash, n1);
//     Set.add(fullset, nhash, n2);
//     Set.add(fullset, nhash, n3);

//     if (n1 == n2 and n2 == n3) {
//         Set.add(intersect_set, nhash, n1);
//     };

// };

// inputs[0].sort(Nat.compare);
// inputs[1].sort(Nat.compare);
// inputs[2].sort(Nat.compare);

// let sparse_bitmaps = Buffer.Buffer<SparseBitMap.SparseBitMap>(3);

// test(
//     "fromIter()",
//     func() {
//         let sparse_bitmap = SparseBitMap.fromIter(Set.keys(sets.get(0)));
//         assert sparse_bitmap.size() == Set.size(sets.get(0));

//         for (n in Set.keys(sets.get(0))) {
//             assert sparse_bitmap.get(n) == true;
//         };

//         sparse_bitmaps.add(sparse_bitmap);

//     },
// );

// test(
//     "add()",
//     func() {
//         let sparse_bitmap = SparseBitMap.SparseBitMap();

//         for (n in inputs[1].vals()) {
//             sparse_bitmap.add(n);
//         };

//         assert sparse_bitmap.size() == inputs[1].size();

//         for (n in inputs[1].vals()) {
//             assert sparse_bitmap.get(n) == true;
//         };

//         sparse_bitmaps.add(sparse_bitmap);

//     },
// );

// test(
//     "addAll()",
//     func() {
//         let sparse_bitmap = SparseBitMap.SparseBitMap();

//         sparse_bitmap.addAll(inputs[2].vals());

//         assert sparse_bitmap.size() == inputs[2].size();

//         for (n in inputs[2].vals()) {
//             assert sparse_bitmap.get(n) == true;
//         };

//         sparse_bitmaps.add(sparse_bitmap);

//     },
// );

// test(
//     "clone()",
//     func() {
//         let sparse_bitmap = sparse_bitmaps.get(0).clone();

//         assert sparse_bitmap.size() == inputs[0].size();

//         for (n in inputs[0].vals()) {
//             assert sparse_bitmap.get(n) == true;
//         };
//     },
// );

// test(
//     "vals()",
//     func() {
//         let sparse_bitmap = sparse_bitmaps.get(0).clone();

//         assert sparse_bitmap.size() == inputs[0].size();

//         let set = Set.new<Nat>();

//         for (n in sparse_bitmap.vals()) {
//             assert Set.has(set, nhash, n);
//         };
//     },
// );

// test(
//     "union()",
//     func() {
//         let sparse_bitmap1 = sparse_bitmaps.get(0).clone();
//         let sparse_bitmap2 = sparse_bitmaps.get(1);
//         let sparse_bitmap3 = sparse_bitmaps.get(2);

//         sparse_bitmap1.union(sparse_bitmap2);
//         sparse_bitmap1.union(sparse_bitmap3);

//         for (n in Set.keys(fullset)) {
//             assert sparse_bitmap1.get(n) == true;
//         };

//     },

// );

// test(
//     "multiUnion()",
//     func() {

//         let sparse_bitmap = SparseBitMap.multiUnion(sparse_bitmaps.vals());

//         for (n in Set.keys(fullset)) {
//             assert sparse_bitmap.get(n) == true;
//         };
//     },
// );

// test(
//     "intersect()",

//     func() {
//         let sparse_bitmap1 = sparse_bitmaps.get(0).clone();
//         let sparse_bitmap2 = sparse_bitmaps.get(1);
//         let sparse_bitmap3 = sparse_bitmaps.get(2);

//         sparse_bitmap1.intersect(sparse_bitmap2);
//         sparse_bitmap1.intersect(sparse_bitmap3);

//         for (n in Set.keys(intersect_set)) {
//             assert sparse_bitmap1.get(n) == true;
//         };

//     },
// );

// test(
//     "multiIntersect()",
//     func() {

//         let sparse_bitmap = SparseBitMap.multiIntersect(sparse_bitmaps.vals());

//         for (n in Set.keys(intersect_set)) {
//             assert sparse_bitmap.get(n) == true;
//         };
//     },
// );
