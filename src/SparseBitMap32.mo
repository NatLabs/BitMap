import BitMap "lib";
import Nat16 "mo:base@0.16.0/Nat16";
import Nat32 "mo:base@0.16.0/Nat32";
import Iter "mo:base@0.16.0/Iter";
import Debug "mo:base@0.16.0/Debug";
import Buffer "mo:base@0.16.0/Buffer";
import Order "mo:base@0.16.0/Order";
import Nat "mo:base@0.16.0/Nat";
import Array "mo:base@0.16.0/Array";

import Itertools "mo:itertools@0.2.2/Iter";
import Map "mo:map@9.0.1/Map";

/// A sparse bitmap that implements the roaring bitmap compression scheme.
/// This implementation is limited to 32-bit Nat values and uses a stable structure.

module {
    type BitMap = BitMap.BitMap;
    type Buffer<T> = Buffer.Buffer<T>;

    type Container = BitMap;

    public type SparseBitMap32 = {
        store : Map.Map<Nat, Container>;
        var cached_size : Nat;
    };

    func clone_container(container : Container) : Container {
        BitMap.clone(container);
    };

    func containers_cmp(a : Container, b : Container) : Order.Order {
        Nat.compare(BitMap.size(a), BitMap.size(b));
    };

    public func empty() : SparseBitMap32 {
        {
            store = Map.new<Nat, Container>();
            var cached_size = 0;
        };
    };

    public func new() : SparseBitMap32 = empty();

    public func fromIter(iter : Iter.Iter<Nat>) : SparseBitMap32 {
        let rbitmap = new();

        // Batch insertions to avoid repeated size recalculations
        for (n in iter) {
            if (n > maximumValue) {
                Debug.trap("SparseBitMap32.fromIter(): value " # debug_show (n) # " is too large. Maximum value is " # debug_show (maximumValue));
            };

            let n32 = Nat32.fromNat(n);
            let high_16_bits = Nat32.toNat(n32 >> 16);
            let low_bits = Nat32.toNat(n32 & 0xFFFF);

            let container = get_or_create_container(rbitmap, high_16_bits);
            BitMap.set(container, low_bits, true);
        };

        // Recalculate size once at the end
        rbitmap.cached_size := 0;
        for (container in Map.vals(rbitmap.store)) {
            rbitmap.cached_size += BitMap.size(container);
        };

        rbitmap;
    };

    public func fromArray(arr : [Nat]) : SparseBitMap32 {
        fromIter(arr.vals());
    };

    public func size(bitmap : SparseBitMap32) : Nat = bitmap.cached_size;

    public let maximumValue : Nat = 4294967295;
    public func capacity(_bitmap : SparseBitMap32) : Nat = maximumValue + 1;

    public func clone(bitmap : SparseBitMap32) : SparseBitMap32 {
        let new_rbitmap = new();

        for ((key, container) in Map.entries(bitmap.store)) {
            Map.set(new_rbitmap.store, Map.nhash, key, clone_container(container));
        };

        new_rbitmap.cached_size := bitmap.cached_size;
        new_rbitmap;
    };

    public func clear(bitmap : SparseBitMap32) {
        // Clear all containers but keep the map structure
        for (container in Map.vals(bitmap.store)) {
            BitMap.clear(container);
        };
        bitmap.cached_size := 0;
    };

    public func get(bitmap : SparseBitMap32, i : Nat) : Bool {
        let high_bits = Nat16.fromNat32(Nat32.fromNat(i) >> 16);
        let low_bits = Nat16.fromNat32(Nat32.fromNat(i) & 0xFFFF);

        switch (Map.get(bitmap.store, Map.nhash, Nat16.toNat(high_bits))) {
            case (?container) {
                BitMap.get(container, Nat16.toNat(low_bits));
            };
            case (null) false;
        };
    };

    func get_or_create_container(bitmap : SparseBitMap32, key : Nat) : Container {
        switch (Map.get(bitmap.store, Map.nhash, key)) {
            case (?container) { container };
            case (null) {
                let container = BitMap.new(2 ** 16);
                Map.set(bitmap.store, Map.nhash, key, container);
                container;
            };
        };
    };

    public func set(bitmap : SparseBitMap32, n : Nat, value : Bool) {
        if (n > maximumValue) {
            Debug.trap("SparseBitMap32.set(): value " # debug_show (n) # " is too large. Maximum value is " # debug_show (maximumValue));
        };

        let n32 = Nat32.fromNat(n);
        let high_16_bits = Nat32.toNat(n32 >> 16);
        let low_bits = Nat32.toNat(n32 & 0xFFFF);

        if (value) {
            let container = get_or_create_container(bitmap, high_16_bits);
            let prev_size = BitMap.size(container);
            BitMap.set(container, low_bits, true);
            let new_size = BitMap.size(container);

            // Update cached size based on the change in container size
            if (new_size > prev_size) {
                bitmap.cached_size += (new_size - prev_size);
            };
        } else {
            // Remove bit if value is false
            switch (Map.get(bitmap.store, Map.nhash, high_16_bits)) {
                case (?container) {
                    let prev_size = BitMap.size(container);
                    BitMap.set(container, low_bits, false);
                    let new_size = BitMap.size(container);

                    // Update cached size based on the change in container size
                    if (new_size < prev_size) {
                        bitmap.cached_size -= (prev_size - new_size);
                    };
                };
                case (null) {}; // Bit is already false, nothing to do
            };
        };
    };

    public func add(bitmap : SparseBitMap32, n : Nat) {
        set(bitmap, n, true);
    };

    public func remove(bitmap : SparseBitMap32, n : Nat) {
        set(bitmap, n, false);
    };

    public func addAll(bitmap : SparseBitMap32, iter : Iter.Iter<Nat>) {
        for (n in iter) {
            add(bitmap, n);
        };
    };

    public func intersectInPlace(bitmap1 : SparseBitMap32, bitmap2 : SparseBitMap32) {
        bitmap1.cached_size := 0;

        let keys_to_remove = Buffer.Buffer<Nat>(Map.size(bitmap1.store));

        for ((container_16bit_key, container) in Map.entries(bitmap1.store)) {
            switch (Map.get(bitmap2.store, Map.nhash, container_16bit_key)) {
                case (null) {
                    keys_to_remove.add(container_16bit_key);
                };
                case (?other_container) {
                    BitMap.intersectInPlace(container, other_container);
                    bitmap1.cached_size += BitMap.size(container);
                };
            };
        };

        // Remove keys after iteration to avoid concurrent modification
        for (key in keys_to_remove.vals()) {
            Map.delete(bitmap1.store, Map.nhash, key);
        };
    };

    public func intersect(bitmap1 : SparseBitMap32, bitmap2 : SparseBitMap32) : SparseBitMap32 {
        let result = clone(bitmap1);
        intersectInPlace(result, bitmap2);
        result;
    };

    public func unionInPlace(bitmap1 : SparseBitMap32, bitmap2 : SparseBitMap32) {
        bitmap1.cached_size := 0;

        for ((container_16bit_key, other_container) in Map.entries(bitmap2.store)) {
            switch (Map.get(bitmap1.store, Map.nhash, container_16bit_key)) {
                case (null) {
                    Map.set(bitmap1.store, Map.nhash, container_16bit_key, clone_container(other_container));
                };
                case (?self_container) {
                    BitMap.unionInPlace(self_container, other_container);
                };
            };
        };

        // Recalculate size
        _update_size(bitmap1);
    };

    public func union(bitmap1 : SparseBitMap32, bitmap2 : SparseBitMap32) : SparseBitMap32 {
        let result = clone(bitmap1);
        unionInPlace(result, bitmap2);
        result;
    };

    /// Removes all bits from `bitmap1` that are set in `bitmap2`.
    /// This implements set difference (A - B), keeping only bits that are in `bitmap1` but not in `bitmap2`.
    /// Only `bitmap1` is modified in place.
    public func differenceInPlace(bitmap1 : SparseBitMap32, bitmap2 : SparseBitMap32) {
        bitmap1.cached_size := 0;

        let keys_to_remove = Buffer.Buffer<Nat>(Map.size(bitmap1.store));

        for ((container_16bit_key, container) in Map.entries(bitmap1.store)) {
            switch (Map.get(bitmap2.store, Map.nhash, container_16bit_key)) {
                case (null) {
                    // Keep container as-is, no bits to remove
                    bitmap1.cached_size += BitMap.size(container);
                };
                case (?other_container) {
                    BitMap.differenceInPlace(container, other_container);
                    let new_size = BitMap.size(container);
                    if (new_size == 0) {
                        keys_to_remove.add(container_16bit_key);
                    } else {
                        bitmap1.cached_size += new_size;
                    };
                };
            };
        };

        // Remove empty containers after iteration
        for (key in keys_to_remove.vals()) {
            Map.delete(bitmap1.store, Map.nhash, key);
        };
    };

    /// Returns a new bitmap containing bits that are in `bitmap1` but not in `bitmap2`.
    /// This implements set difference (A - B).
    public func difference(bitmap1 : SparseBitMap32, bitmap2 : SparseBitMap32) : SparseBitMap32 {
        let result = clone(bitmap1);
        differenceInPlace(result, bitmap2);
        result;
    };

    /// Modifies `bitmap1` to contain only bits that are in either `bitmap1` or `bitmap2`, but not in both.
    /// This implements symmetric difference (A ⊕ B).
    /// Only `bitmap1` is modified in place.
    public func symmetricDifferenceInPlace(bitmap1 : SparseBitMap32, bitmap2 : SparseBitMap32) {
        bitmap1.cached_size := 0;

        let keys_to_remove = Buffer.Buffer<Nat>(Map.size(bitmap1.store));

        // Process all containers in bitmap1
        for ((container_16bit_key, container) in Map.entries(bitmap1.store)) {
            switch (Map.get(bitmap2.store, Map.nhash, container_16bit_key)) {
                case (null) {
                    // Keep container as-is, bits only in bitmap1
                    bitmap1.cached_size += BitMap.size(container);
                };
                case (?other_container) {
                    BitMap.symmetricDifferenceInPlace(container, other_container);
                    let new_size = BitMap.size(container);
                    if (new_size == 0) {
                        keys_to_remove.add(container_16bit_key);
                    } else {
                        bitmap1.cached_size += new_size;
                    };
                };
            };
        };

        // Remove empty containers
        for (key in keys_to_remove.vals()) {
            Map.delete(bitmap1.store, Map.nhash, key);
        };

        // Add containers that are only in bitmap2
        for ((container_16bit_key, other_container) in Map.entries(bitmap2.store)) {
            switch (Map.get(bitmap1.store, Map.nhash, container_16bit_key)) {
                case (null) {
                    // Container only in bitmap2, add it to bitmap1
                    let new_container = BitMap.clone(other_container);
                    Map.set(bitmap1.store, Map.nhash, container_16bit_key, new_container);
                    bitmap1.cached_size += BitMap.size(new_container);
                };
                case (?_) {
                    // Already processed in first loop
                };
            };
        };
    };

    /// Returns a new bitmap containing bits that are in either `bitmap1` or `bitmap2`, but not in both.
    /// This implements symmetric difference (A ⊕ B).
    public func symmetricDifference(bitmap1 : SparseBitMap32, bitmap2 : SparseBitMap32) : SparseBitMap32 {
        let result = clone(bitmap1);
        symmetricDifferenceInPlace(result, bitmap2);
        result;
    };

    public func vals(bitmap : SparseBitMap32) : Iter.Iter<Nat> {
        Itertools.flatten(
            Iter.map<(Nat, Container), Iter.Iter<Nat>>(
                Map.entries(bitmap.store),
                func(high_16bit_key : Nat, container : Container) : Iter.Iter<Nat> {
                    Iter.map<Nat16, Nat>(
                        Iter.map(BitMap.vals(container), Nat16.fromNat),
                        func(low_16bit : Nat16) : Nat {
                            let n32 = Nat32.fromNat(high_16bit_key) << 16 | Nat32.fromNat16(low_16bit);
                            Nat32.toNat(n32);
                        },
                    );
                },
            )
        );
    };

    public func toArray(bitmap : SparseBitMap32) : [Nat] {
        let iter = vals(bitmap);

        Array.tabulate(
            bitmap.cached_size,
            func(_ : Nat) : Nat {
                let ?val = iter.next() else Debug.trap("Unexpected end of iterator in toArray");
                val;
            },
        );
    };

    func multi_intersect_containers(containers : Iter.Iter<Container>) : ?Container {
        let containers_buffer = Buffer.Buffer<Container>(10);
        for (container in containers) {
            containers_buffer.add(container);
        };

        if (containers_buffer.size() == 0) return null;

        containers_buffer.sort(containers_cmp);

        let smallest_container = clone_container(containers_buffer.get(0));

        for (container in Itertools.skip(containers_buffer.vals(), 1)) {
            BitMap.intersectInPlace(smallest_container, container);
        };

        if (BitMap.size(smallest_container) == 0) return null;

        ?smallest_container;
    };

    public func multiIntersect(rbitmap_iter : Iter.Iter<SparseBitMap32>) : SparseBitMap32 {
        let rbitmaps = Iter.toArray(rbitmap_iter);

        if (rbitmaps.size() == 0) return empty();

        var smallest_bitmap = rbitmaps[0];

        for (rbitmap in rbitmaps.vals()) {
            if (size(rbitmap) < size(smallest_bitmap)) {
                smallest_bitmap := rbitmap;
            };
        };

        let new_rbitmap = new();

        let containers = Buffer.Buffer<Container>(10);

        for ((container_16bit_key, container) in Map.entries(smallest_bitmap.store)) {

            for (rbitmap in rbitmaps.vals()) {
                switch (Map.get(rbitmap.store, Map.nhash, container_16bit_key)) {
                    case (?container) { containers.add(container) };
                    case (null) {};
                };
            };

            if (containers.size() == rbitmaps.size()) {
                // all rbitmaps must have this container
                // if any one is missing, it means the intersection is empty
                switch (multi_intersect_containers(containers.vals())) {
                    case (?intersect_container) {
                        Map.set(new_rbitmap.store, Map.nhash, container_16bit_key, intersect_container);
                        new_rbitmap.cached_size += BitMap.size(intersect_container);
                    };
                    case (null) {};
                };
            };

            containers.clear();
        };

        new_rbitmap;
    };

    func multi_union_containers(containers : Buffer<Container>) : ?Container {
        let size = containers.size();
        if (size == 0) return null;
        if (size == 1) {
            let result = clone_container(containers.get(0));
            if (BitMap.size(result) == 0) return null;
            return ?result;
        };

        containers.sort(containers_cmp);

        // Start with the largest container (last after sorting)
        let result = clone_container(containers.get(size - 1));

        // Union with all other containers (all except the last one)
        var i = 0;
        while (i + 1 < size) {
            // i + 1 < size means i < size - 1
            BitMap.unionInPlace(result, containers.get(i));
            i += 1;
        };

        if (BitMap.size(result) == 0) return null;
        ?result;
    };

    public func multiUnion(rbitmap_iter : Iter.Iter<SparseBitMap32>) : SparseBitMap32 {
        let rbitmaps = Iter.toArray(rbitmap_iter);

        if (rbitmaps.size() == 0) return empty();

        let new_rbitmap = new();
        let containers = Buffer.Buffer<Container>(10);

        // Collect all unique container keys
        let all_keys = Buffer.Buffer<Nat>(10);
        for (rbitmap in rbitmaps.vals()) {
            for ((key, _) in Map.entries(rbitmap.store)) {
                // Simple check to avoid duplicates (not the most efficient but works)
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
        for (container_16bit_key in all_keys.vals()) {
            containers.clear();

            for (rbitmap in rbitmaps.vals()) {
                switch (Map.get(rbitmap.store, Map.nhash, container_16bit_key)) {
                    case (?container) { containers.add(container) };
                    case (null) {};
                };
            };

            if (containers.size() == 1) {
                let cloned = clone_container(containers.get(0));
                Map.set(new_rbitmap.store, Map.nhash, container_16bit_key, cloned);
                new_rbitmap.cached_size += BitMap.size(cloned);
            } else if (containers.size() > 1) {
                switch (multi_union_containers(containers)) {
                    case (?union_container) {
                        Map.set(new_rbitmap.store, Map.nhash, container_16bit_key, union_container);
                        new_rbitmap.cached_size += BitMap.size(union_container);
                    };
                    case (null) {};
                };
            };
        };

        new_rbitmap;
    };

    public func _update_size(bitmap : SparseBitMap32) {
        bitmap.cached_size := 0;

        for ((key, container) in Map.entries(bitmap.store)) {
            bitmap.cached_size += BitMap.size(container);
        };
    };

};
