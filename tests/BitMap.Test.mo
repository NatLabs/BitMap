import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import { test; suite; skip } "mo:test";

import BitMap "../src";

test(
    "init()",
    func() {
        let bitmap = BitMap.BitMap(8);

        bitmap.set(64, true);

        assert bitmap.get(64) == true;

    },
);

test(
    "union",
    func() {
        let bitmap1 = BitMap.BitMap(8);
        let bitmap2 = BitMap.BitMap(8);

        bitmap1.set(1, true);
        bitmap2.set(64, true);

        assert bitmap1.get(1) == true;
        assert bitmap2.get(64) == true;

        bitmap1.union(bitmap2);

        assert bitmap1.get(1) == true;
        assert bitmap1.get(64) == true;

        for (i in Iter.range(0, bitmap1.capacity() - 1)) {
            if (i != 1 and i != 64) {
                assert bitmap1.get(i) == false;
            };
        };

    },

);

test(
    "intersect",
    func() {
        let bitmap1 = BitMap.BitMap(8);
        let bitmap2 = BitMap.BitMap(8);

        bitmap1.set(1, true);
        assert bitmap1.get(1) == true;
        bitmap1.set(64, true);
        assert bitmap1.get(64) == true;

        bitmap2.set(64, true);
        assert bitmap2.get(64) == true;

        bitmap1.intersect(bitmap2);

        assert bitmap1.get(1) == false;
        assert bitmap1.get(64) == true;

        for (i in Iter.range(0, bitmap1.capacity() - 1)) {
            if (i != 64) {
                assert bitmap1.get(i) == false;
            };
        };

    },
);

test(
    "vals()",
    func() {
        let bitmap = BitMap.BitMap(8);

        bitmap.set(1, true);
        bitmap.set(64, true);

        let vals = bitmap.vals();

        assert vals.next() == ?1;
        assert vals.next() == ?64;
        assert vals.next() == null;

        bitmap.set(2, true);
        bitmap.set(324, true);

        assert bitmap.toArray() == [1, 2, 64, 324];
    },
);

test(
    "fromArray()",
    func() {
        let bitmap = BitMap.fromArray([1, 2, 64, 324]);

        assert bitmap.get(1) == true;
        assert bitmap.get(2) == true;
        assert bitmap.get(64) == true;
        assert bitmap.get(324) == true;
    },
);
