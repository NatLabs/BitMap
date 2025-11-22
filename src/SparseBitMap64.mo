import SparseBitMap32 "SparseBitMap32";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Order "mo:base/Order";
import Nat "mo:base/Nat";
import Array "mo:base/Array";

import Itertools "mo:itertools/Iter";
import Map "mo:map/Map";

/// A sparse bitmap that implements a two-level roaring bitmap compression scheme.
/// This implementation supports 64-bit Nat values by using:
/// - High 32 bits: Map key to locate the appropriate SparseBitMap32
/// - Low 32 bits: Stored in SparseBitMap32 structure
///
/// This allows efficient storage of sparse 64-bit datasets.

module {
    type SparseBitMap32 = SparseBitMap32.SparseBitMap32;
    type Buffer<T> = Buffer.Buffer<T>;

    public type SparseBitMap64 = {
        store : Map.Map<Nat32, SparseBitMap32>;
        var cached_size : Nat;
    };

    func clone_container(container : SparseBitMap32) : SparseBitMap32 {
        SparseBitMap32.clone(container);
    };

    func containers_cmp(a : SparseBitMap32, b : SparseBitMap32) : Order.Order {
        Nat.compare(SparseBitMap32.size(a), SparseBitMap32.size(b));
    };

    public func empty() : SparseBitMap64 {
        {
            store = Map.new<Nat32, SparseBitMap32>();
            var cached_size = 0;
        };
    };

    public func new() : SparseBitMap64 = empty();

    public func fromIter(iter : Iter.Iter<Nat>) : SparseBitMap64 {
        let bitmap = new();

        // Batch insertions to avoid repeated size recalculations
        for (n in iter) {
            if (n >= capacity(bitmap)) {
                Debug.trap("SparseBitMap64.fromIter(): value " # debug_show (n) # " is too large. Maximum value is " # debug_show (capacity(bitmap)));
            };

            let n64 = Nat64.fromNat(n);
            let high_32_bits = Nat32.fromNat64(n64 >> 32);
            let low_32_bits = Nat64.toNat(n64 & 0xFFFFFFFF);

            let container = get_or_create_container(bitmap, high_32_bits);
            SparseBitMap32.add(container, low_32_bits);
        };

        // Recalculate size once at the end
        bitmap.cached_size := 0;
        for (container in Map.vals(bitmap.store)) {
            bitmap.cached_size += SparseBitMap32.size(container);
        };

        bitmap;
    };

    public func fromArray(arr : [Nat]) : SparseBitMap64 {
        fromIter(arr.vals());
    };

    public func size(bitmap : SparseBitMap64) : Nat = bitmap.cached_size;

    public func capacity(_bitmap : SparseBitMap64) : Nat = Nat64.toNat(Nat64.maximumValue);

    public func clone(bitmap : SparseBitMap64) : SparseBitMap64 {
        let new_bitmap = new();

        for ((key, container) in Map.entries(bitmap.store)) {
            Map.set(new_bitmap.store, Map.n32hash, key, clone_container(container));
        };

        new_bitmap.cached_size := bitmap.cached_size;
        new_bitmap;
    };

    public func clear(bitmap : SparseBitMap64) {
        // Clear all containers but keep the map structure
        for (container in Map.vals(bitmap.store)) {
            SparseBitMap32.clear(container);
        };
        bitmap.cached_size := 0;
    };

    public func get(bitmap : SparseBitMap64, i : Nat) : Bool {
        let n64 = Nat64.fromNat(i);
        let high_32_bits = Nat32.fromNat64(n64 >> 32);
        let low_32_bits = Nat64.toNat(n64 & 0xFFFFFFFF);

        switch (Map.get(bitmap.store, Map.n32hash, high_32_bits)) {
            case (?container) {
                SparseBitMap32.get(container, low_32_bits);
            };
            case (null) false;
        };
    };

    func get_or_create_container(bitmap : SparseBitMap64, key : Nat32) : SparseBitMap32 {
        switch (Map.get(bitmap.store, Map.n32hash, key)) {
            case (?container) { container };
            case (null) {
                let container = SparseBitMap32.new();
                Map.set(bitmap.store, Map.n32hash, key, container);
                container;
            };
        };
    };

    public func set(bitmap : SparseBitMap64, n : Nat, value : Bool) {
        if (n >= capacity(bitmap)) {
            Debug.trap("SparseBitMap64.set(): value " # debug_show (n) # " is too large. Maximum value is " # debug_show (capacity(bitmap)));
        };

        let n64 = Nat64.fromNat(n);
        let high_32_bits = Nat32.fromNat64(n64 >> 32);
        let low_32_bits = Nat64.toNat(n64 & 0xFFFFFFFF);

        if (value) {
            let container = get_or_create_container(bitmap, high_32_bits);
            let prev_size = SparseBitMap32.size(container);
            SparseBitMap32.set(container, low_32_bits, true);
            let new_size = SparseBitMap32.size(container);

            // Update cached size based on the change in container size
            if (new_size > prev_size) {
                bitmap.cached_size += (new_size - prev_size);
            };
        } else {
            // Remove bit if value is false
            switch (Map.get(bitmap.store, Map.n32hash, high_32_bits)) {
                case (?container) {
                    let prev_size = SparseBitMap32.size(container);
                    SparseBitMap32.set(container, low_32_bits, false);
                    let new_size = SparseBitMap32.size(container);

                    // Update cached size based on the change in container size
                    if (new_size < prev_size) {
                        bitmap.cached_size -= (prev_size - new_size);
                    };
                };
                case (null) {}; // Bit is already false, nothing to do
            };
        };
    };

    public func add(bitmap : SparseBitMap64, n : Nat) {
        set(bitmap, n, true);
    };

    public func remove(bitmap : SparseBitMap64, n : Nat) {
        set(bitmap, n, false);
    };

    public func addAll(bitmap : SparseBitMap64, iter : Iter.Iter<Nat>) {
        for (n in iter) {
            add(bitmap, n);
        };
    };

    public func intersectInPlace(bitmap1 : SparseBitMap64, bitmap2 : SparseBitMap64) {
        bitmap1.cached_size := 0;

        let keys_to_remove = Buffer.Buffer<Nat32>(Map.size(bitmap1.store));

        for ((key, container) in Map.entries(bitmap1.store)) {
            switch (Map.get(bitmap2.store, Map.n32hash, key)) {
                case (null) {
                    keys_to_remove.add(key);
                };
                case (?other_container) {
                    SparseBitMap32.intersectInPlace(container, other_container);
                    bitmap1.cached_size += SparseBitMap32.size(container);
                };
            };
        };

        // Remove keys after iteration to avoid concurrent modification
        for (key in keys_to_remove.vals()) {
            Map.delete(bitmap1.store, Map.n32hash, key);
        };
    };

    public func intersect(bitmap1 : SparseBitMap64, bitmap2 : SparseBitMap64) : SparseBitMap64 {
        let result = clone(bitmap1);
        intersectInPlace(result, bitmap2);
        result;
    };

    public func unionInPlace(bitmap1 : SparseBitMap64, bitmap2 : SparseBitMap64) {
        bitmap1.cached_size := 0;

        for ((key, other_container) in Map.entries(bitmap2.store)) {
            switch (Map.get(bitmap1.store, Map.n32hash, key)) {
                case (null) {
                    Map.set(bitmap1.store, Map.n32hash, key, clone_container(other_container));
                };
                case (?self_container) {
                    SparseBitMap32.unionInPlace(self_container, other_container);
                };
            };
        };

        // Recalculate size
        _update_size(bitmap1);
    };

    public func union(bitmap1 : SparseBitMap64, bitmap2 : SparseBitMap64) : SparseBitMap64 {
        let result = clone(bitmap1);
        unionInPlace(result, bitmap2);
        result;
    };

    /// Removes all bits from `bitmap1` that are set in `bitmap2`.
    /// This implements set difference (A - B), keeping only bits that are in `bitmap1` but not in `bitmap2`.
    /// Only `bitmap1` is modified in place.
    public func differenceInPlace(bitmap1 : SparseBitMap64, bitmap2 : SparseBitMap64) {
        bitmap1.cached_size := 0;

        let keys_to_remove = Buffer.Buffer<Nat32>(Map.size(bitmap1.store));

        for ((key, container) in Map.entries(bitmap1.store)) {
            switch (Map.get(bitmap2.store, Map.n32hash, key)) {
                case (null) {
                    // Keep container as-is, no bits to remove
                    bitmap1.cached_size += SparseBitMap32.size(container);
                };
                case (?other_container) {
                    SparseBitMap32.differenceInPlace(container, other_container);
                    let new_size = SparseBitMap32.size(container);
                    if (new_size == 0) {
                        keys_to_remove.add(key);
                    } else {
                        bitmap1.cached_size += new_size;
                    };
                };
            };
        };

        // Remove empty containers after iteration
        for (key in keys_to_remove.vals()) {
            Map.delete(bitmap1.store, Map.n32hash, key);
        };
    };

    /// Returns a new bitmap containing bits that are in `bitmap1` but not in `bitmap2`.
    /// This implements set difference (A - B).
    public func difference(bitmap1 : SparseBitMap64, bitmap2 : SparseBitMap64) : SparseBitMap64 {
        let result = clone(bitmap1);
        differenceInPlace(result, bitmap2);
        result;
    };

    /// Modifies `bitmap1` to contain only bits that are in either `bitmap1` or `bitmap2`, but not in both.
    /// This implements symmetric difference (A ⊕ B).
    /// Only `bitmap1` is modified in place.
    public func symmetricDifferenceInPlace(bitmap1 : SparseBitMap64, bitmap2 : SparseBitMap64) {
        bitmap1.cached_size := 0;

        let keys_to_remove = Buffer.Buffer<Nat32>(Map.size(bitmap1.store));

        // Process all containers in bitmap1
        for ((key, container) in Map.entries(bitmap1.store)) {
            switch (Map.get(bitmap2.store, Map.n32hash, key)) {
                case (null) {
                    // Keep container as-is, bits only in bitmap1
                    bitmap1.cached_size += SparseBitMap32.size(container);
                };
                case (?other_container) {
                    SparseBitMap32.symmetricDifferenceInPlace(container, other_container);
                    let new_size = SparseBitMap32.size(container);
                    if (new_size == 0) {
                        keys_to_remove.add(key);
                    } else {
                        bitmap1.cached_size += new_size;
                    };
                };
            };
        };

        // Remove empty containers
        for (key in keys_to_remove.vals()) {
            Map.delete(bitmap1.store, Map.n32hash, key);
        };

        // Add containers that are only in bitmap2
        for ((key, other_container) in Map.entries(bitmap2.store)) {
            switch (Map.get(bitmap1.store, Map.n32hash, key)) {
                case (null) {
                    // Container only in bitmap2, add it to bitmap1
                    let new_container = clone_container(other_container);
                    Map.set(bitmap1.store, Map.n32hash, key, new_container);
                    bitmap1.cached_size += SparseBitMap32.size(new_container);
                };
                case (?_) {
                    // Already processed in first loop
                };
            };
        };
    };

    /// Returns a new bitmap containing bits that are in either `bitmap1` or `bitmap2`, but not in both.
    /// This implements symmetric difference (A ⊕ B).
    public func symmetricDifference(bitmap1 : SparseBitMap64, bitmap2 : SparseBitMap64) : SparseBitMap64 {
        let result = clone(bitmap1);
        symmetricDifferenceInPlace(result, bitmap2);
        result;
    };

    public func vals(bitmap : SparseBitMap64) : Iter.Iter<Nat> {
        Itertools.flatten(
            Iter.map<(Nat32, SparseBitMap32), Iter.Iter<Nat>>(
                Map.entries(bitmap.store),
                func(high_32bit_key : Nat32, container : SparseBitMap32) : Iter.Iter<Nat> {
                    Iter.map<Nat, Nat>(
                        SparseBitMap32.vals(container),
                        func(low_32bit : Nat) : Nat {
                            let high = Nat64.fromNat32(high_32bit_key);
                            let low = Nat64.fromNat(low_32bit);
                            let n64 = (high << 32) | low;
                            Nat64.toNat(n64);
                        },
                    );
                },
            )
        );
    };

    public func toArray(bitmap : SparseBitMap64) : [Nat] {
        let iter = vals(bitmap);

        Array.tabulate(
            bitmap.cached_size,
            func(_ : Nat) : Nat {
                let ?val = iter.next() else Debug.trap("Unexpected end of iterator in toArray");
                val;
            },
        );
    };

    func multi_intersect_containers(containers : Iter.Iter<SparseBitMap32>) : ?SparseBitMap32 {
        let containers_buffer = Buffer.Buffer<SparseBitMap32>(10);
        for (container in containers) {
            containers_buffer.add(container);
        };

        if (containers_buffer.size() == 0) return null;

        containers_buffer.sort(containers_cmp);

        let smallest_container = clone_container(containers_buffer.get(0));

        for (container in Itertools.skip(containers_buffer.vals(), 1)) {
            SparseBitMap32.intersectInPlace(smallest_container, container);
        };

        if (SparseBitMap32.size(smallest_container) == 0) return null;

        ?smallest_container;
    };

    public func multiIntersect(bitmap_iter : Iter.Iter<SparseBitMap64>) : SparseBitMap64 {
        let bitmaps = Iter.toArray(bitmap_iter);

        if (bitmaps.size() == 0) return empty();

        var smallest_bitmap = bitmaps[0];

        for (bitmap in bitmaps.vals()) {
            if (size(bitmap) < size(smallest_bitmap)) {
                smallest_bitmap := bitmap;
            };
        };

        let new_bitmap = new();

        let containers = Buffer.Buffer<SparseBitMap32>(10);

        for ((key, container) in Map.entries(smallest_bitmap.store)) {

            for (bitmap in bitmaps.vals()) {
                switch (Map.get(bitmap.store, Map.n32hash, key)) {
                    case (?container) { containers.add(container) };
                    case (null) {};
                };
            };

            if (containers.size() == bitmaps.size()) {
                // all bitmaps must have this container
                // if any one is missing, it means the intersection is empty
                switch (multi_intersect_containers(containers.vals())) {
                    case (?intersect_container) {
                        Map.set(new_bitmap.store, Map.n32hash, key, intersect_container);
                        new_bitmap.cached_size += SparseBitMap32.size(intersect_container);
                    };
                    case (null) {};
                };
            };

            containers.clear();
        };

        new_bitmap;
    };

    func multi_union_containers(containers : Buffer<SparseBitMap32>) : ?SparseBitMap32 {
        let size = containers.size();
        if (size == 0) return null;
        if (size == 1) {
            let result = clone_container(containers.get(0));
            if (SparseBitMap32.size(result) == 0) return null;
            return ?result;
        };

        containers.sort(containers_cmp);

        // Start with the largest container (last after sorting)
        let result = clone_container(containers.get(size - 1));

        // Union with all other containers (all except the last one)
        var i = 0;
        while (i + 1 < size) {
            // i + 1 < size means i < size - 1
            SparseBitMap32.unionInPlace(result, containers.get(i));
            i += 1;
        };

        if (SparseBitMap32.size(result) == 0) return null;
        ?result;
    };

    public func multiUnion(bitmap_iter : Iter.Iter<SparseBitMap64>) : SparseBitMap64 {
        let bitmaps = Iter.toArray(bitmap_iter);

        if (bitmaps.size() == 0) return empty();

        let new_bitmap = new();
        let containers = Buffer.Buffer<SparseBitMap32>(10);

        // Collect all unique container keys
        let all_keys = Buffer.Buffer<Nat32>(10);
        for (bitmap in bitmaps.vals()) {
            for ((key, _) in Map.entries(bitmap.store)) {
                // Simple check to avoid duplicates
                var found = false;
                for (existing_key in all_keys.vals()) {
                    if (existing_key == key) {
                        found := true;
                    };
                };
                if (not found) {
                    all_keys.add(key);
                };
            };
        };

        // Process each unique key
        for (key in all_keys.vals()) {
            containers.clear();

            for (bitmap in bitmaps.vals()) {
                switch (Map.get(bitmap.store, Map.n32hash, key)) {
                    case (?container) { containers.add(container) };
                    case (null) {};
                };
            };

            if (containers.size() == 1) {
                let cloned = clone_container(containers.get(0));
                Map.set(new_bitmap.store, Map.n32hash, key, cloned);
                new_bitmap.cached_size += SparseBitMap32.size(cloned);
            } else if (containers.size() > 1) {
                switch (multi_union_containers(containers)) {
                    case (?union_container) {
                        Map.set(new_bitmap.store, Map.n32hash, key, union_container);
                        new_bitmap.cached_size += SparseBitMap32.size(union_container);
                    };
                    case (null) {};
                };
            };
        };

        new_bitmap;
    };

    public func _update_size(bitmap : SparseBitMap64) {
        bitmap.cached_size := 0;

        for ((key, container) in Map.entries(bitmap.store)) {
            bitmap.cached_size += SparseBitMap32.size(container);
        };
    };

};
