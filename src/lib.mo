import Vector "mo:vector@0.4.2";
import Array "mo:base@0.16.0/Array";
import Nat "mo:base@0.16.0/Nat";
import Nat64 "mo:base@0.16.0/Nat64";
import Int "mo:base@0.16.0/Int";
import Iter "mo:base@0.16.0/Iter";
import Debug "mo:base@0.16.0/Debug";

module {
    public let WORD_SIZE : Nat = 64;

    public type BitMap = {
        words : Vector.Vector<Nat64>;
        var filled_positions : Nat;
    };

    func div_ceil(n : Nat, d : Nat) : Nat {
        (n + d - 1) / d;
    };

    public func empty() : BitMap {
        {
            words = Vector.new<Nat64>();
            var filled_positions = 0;
        };
    };

    public func new(init_size : Nat) : BitMap {
        let init_words : Nat = div_ceil(init_size, WORD_SIZE);
        let words = Vector.new<Nat64>();

        for (_ in Iter.range(1, init_words)) {
            Vector.add(words, 0 : Nat64);
        };

        {
            words = words;
            var filled_positions = 0;
        };
    };

    public func fromIter(iter : Iter.Iter<Nat>) : BitMap {
        // Start with a reasonable initial capacity for efficiency
        let bitmap = new(1024);
        for (n in iter) {
            set(bitmap, n, true);
        };
        bitmap;
    };

    public func fromArray(arr : [Nat]) : BitMap {
        fromIter(arr.vals());
    };

    public func size(bitmap : BitMap) : Nat = bitmap.filled_positions;

    public func capacity(bitmap : BitMap) : Nat = Vector.size(bitmap.words) * WORD_SIZE;

    public func clone(bitmap : BitMap) : BitMap {
        {
            words = Vector.clone(bitmap.words);
            var filled_positions = bitmap.filled_positions;
        };
    };

    public func clear(bitmap : BitMap) {
        // Reset all words to 0, maintaining capacity
        let num_words = Vector.size(bitmap.words);
        for (i in Iter.range(0, num_words - 1)) {
            Vector.put(bitmap.words, i, 0 : Nat64);
        };
        bitmap.filled_positions := 0;
    };

    func grow(bitmap : BitMap, new_size : Nat) {
        let current_capacity = capacity(bitmap);
        if (new_size <= current_capacity) return;

        let additional_space_needed = Int.abs(new_size - current_capacity);
        let additional_words_needed = div_ceil(additional_space_needed, WORD_SIZE);

        for (_ in Iter.range(1, additional_words_needed)) {
            Vector.add(bitmap.words, 0 : Nat64);
        };
    };

    // Internal function that accepts row (word_index) and col (bit_index) directly
    func grow_to_row(bitmap : BitMap, row : Nat) {
        let current_words = Vector.size(bitmap.words);
        if (row < current_words) return;

        // Grow exponentially to amortize the cost of resizing
        // This matches what mo:vector@0.4.2 does internally
        let min_words_needed = row + 1;
        let exponential_growth = current_words * 2;
        let new_capacity = Nat.max(min_words_needed, exponential_growth);
        let additional_words_needed = Int.abs(new_capacity - current_words);

        for (_ in Iter.range(1, additional_words_needed)) {
            Vector.add(bitmap.words, 0 : Nat64);
        };
    };

    // Internal function for setting a bit using row and col where each row has 64 bits
    public func set_internal(bitmap : BitMap, row : Nat, col : Nat, value : Bool) {
        if (col >= WORD_SIZE) {
            Debug.trap("Column index must be less than WORD_SIZE (64)");
        };

        if (row >= Vector.size(bitmap.words)) {
            grow_to_row(bitmap, row);
        };

        let bit_index = Nat64.fromNat(col);
        let word : Nat64 = Vector.get(bitmap.words, row);
        let mask : Nat64 = 1 << bit_index;

        let prev_value = (word & mask) != 0;

        if (prev_value == value) {
            return;
        };

        if (value) {
            Vector.put(bitmap.words, row, word | mask);
            bitmap.filled_positions += 1;
        } else {
            Vector.put(bitmap.words, row, word & ^mask);
            bitmap.filled_positions -= 1;
        };
    };

    // Internal function for getting a bit using row and col
    public func get_internal(bitmap : BitMap, row : Nat, col : Nat) : Bool {
        if (col >= WORD_SIZE) {
            Debug.trap("Column index must be less than WORD_SIZE (64)");
        };

        if (row >= Vector.size(bitmap.words)) {
            return false;
        };

        let bit_index = Nat64.fromNat(col);
        let word : Nat64 = Vector.get(bitmap.words, row);
        let mask : Nat64 = 1 << bit_index;

        (word & mask) != 0;
    };

    public func set(bitmap : BitMap, position : Nat, value : Bool) {
        let row = position / WORD_SIZE;
        let col = position % WORD_SIZE;
        set_internal(bitmap, row, col, value);
    };

    public func get(bitmap : BitMap, n : Nat) : Bool {
        let row = n / WORD_SIZE;
        let col = n % WORD_SIZE;
        get_internal(bitmap, row, col);
    };

    // Utility functions for converting between position and row/col coordinates
    public func position_to_row_col(position : Nat) : (Nat, Nat) {
        let row = position / WORD_SIZE;
        let col = position % WORD_SIZE;
        (row, col);
    };

    public func row_col_to_position(row : Nat, col : Nat) : Nat {
        if (col >= WORD_SIZE) {
            Debug.trap("Column index must be less than WORD_SIZE (64)");
        };
        row * WORD_SIZE + col;
    };

    public func getWord(bitmap : BitMap, n : Nat) : Nat64 {
        Vector.get(bitmap.words, n);
    };

    public func intersectInPlace(bitmap1 : BitMap, bitmap2 : BitMap) {
        let min_words = Nat.min(Vector.size(bitmap1.words), Vector.size(bitmap2.words));
        bitmap1.filled_positions := 0;

        // Clear extra words in bitmap1 if it's larger than bitmap2
        if (Vector.size(bitmap1.words) > min_words) {
            let original_size = Vector.size(bitmap1.words);
            for (i in Iter.range(min_words, original_size - 1)) {
                ignore Vector.removeLast(bitmap1.words);
            };
        };

        for (i in Iter.range(0, min_words - 1)) {
            let word1 = Vector.get(bitmap1.words, i);
            let word2 = Vector.get(bitmap2.words, i);
            let new_word = word1 & word2;

            Vector.put(bitmap1.words, i, new_word);
            bitmap1.filled_positions += Nat64.toNat(Nat64.bitcountNonZero(new_word));
        };
    };

    public func intersect(bitmap1 : BitMap, bitmap2 : BitMap) : BitMap {
        let result = clone(bitmap1);
        intersectInPlace(result, bitmap2);
        result;
    };

    public func unionInPlace(bitmap1 : BitMap, bitmap2 : BitMap) {
        if (Vector.size(bitmap2.words) * WORD_SIZE > capacity(bitmap1)) {
            grow(bitmap1, Vector.size(bitmap2.words) * WORD_SIZE);
        };

        let start = 0;
        let end = Nat.min(capacity(bitmap1), capacity(bitmap2)) / WORD_SIZE;

        if (capacity(bitmap1) == 0) return;

        bitmap1.filled_positions := 0;

        for (i in Iter.range(start, end - 1)) {
            let other_word = Vector.get(bitmap2.words, i);
            let curr_word = Vector.get(bitmap1.words, i);

            let new_word = curr_word | other_word;

            Vector.put(bitmap1.words, i, new_word);

            bitmap1.filled_positions += Nat64.toNat(Nat64.bitcountNonZero(new_word));
        };
    };

    public func union(bitmap1 : BitMap, bitmap2 : BitMap) : BitMap {
        let result = clone(bitmap1);
        unionInPlace(result, bitmap2);
        result;
    };

    /// Removes all bits from `bitmap1` that are set in `bitmap2`.
    /// This implements set difference (A - B), keeping only bits that are in `bitmap1` but not in `bitmap2`.
    /// Only `bitmap1` is modified in place.
    public func differenceInPlace(bitmap1 : BitMap, bitmap2 : BitMap) {
        if (capacity(bitmap1) == 0) return;

        let start = 0;
        let end = Nat.min(capacity(bitmap1), capacity(bitmap2)) / WORD_SIZE;

        bitmap1.filled_positions := 0;

        for (i in Iter.range(start, end - 1)) {
            let other_word = Vector.get(bitmap2.words, i);
            let curr_word = Vector.get(bitmap1.words, i);

            let new_word = curr_word & (^ other_word);

            Vector.put(bitmap1.words, i, new_word);

            bitmap1.filled_positions += Nat64.toNat(Nat64.bitcountNonZero(new_word));
        };

        // Count remaining bits in bitmap1 if it's larger
        if (capacity(bitmap1) > capacity(bitmap2)) {
            let start = capacity(bitmap2) / WORD_SIZE;
            let end = capacity(bitmap1) / WORD_SIZE;

            for (i in Iter.range(start, end - 1)) {
                let curr_word = Vector.get(bitmap1.words, i);
                bitmap1.filled_positions += Nat64.toNat(Nat64.bitcountNonZero(curr_word));
            };
        };
    };

    /// Returns a new bitmap containing bits that are in `bitmap1` but not in `bitmap2`.
    /// This implements set difference (A - B).
    public func difference(bitmap1 : BitMap, bitmap2 : BitMap) : BitMap {
        let result = clone(bitmap1);
        differenceInPlace(result, bitmap2);
        result;
    };

    /// Modifies `bitmap1` to contain only bits that are in either `bitmap1` or `bitmap2`, but not in both.
    /// This implements symmetric difference (A ⊕ B).
    /// Only `bitmap1` is modified in place.
    public func symmetricDifferenceInPlace(bitmap1 : BitMap, bitmap2 : BitMap) {
        if (Vector.size(bitmap2.words) * WORD_SIZE > capacity(bitmap1)) {
            grow(bitmap1, Vector.size(bitmap2.words) * WORD_SIZE);
        };

        let end = Nat.min(capacity(bitmap1), capacity(bitmap2)) / WORD_SIZE;

        bitmap1.filled_positions := 0;

        for (i in Iter.range(0, end - 1)) {
            let other_word = Vector.get(bitmap2.words, i);
            let curr_word = Vector.get(bitmap1.words, i);

            let new_word = curr_word ^ other_word;

            Vector.put(bitmap1.words, i, new_word);

            bitmap1.filled_positions += Nat64.toNat(Nat64.bitcountNonZero(new_word));
        };

        // Handle remaining words if bitmap2 is larger
        if (capacity(bitmap2) > capacity(bitmap1)) {
            let start = capacity(bitmap1) / WORD_SIZE;
            let end = capacity(bitmap2) / WORD_SIZE;

            for (i in Iter.range(start, end - 1)) {
                let other_word = Vector.get(bitmap2.words, i);
                Vector.put(bitmap1.words, i, other_word);
                bitmap1.filled_positions += Nat64.toNat(Nat64.bitcountNonZero(other_word));
            };
        };
    };

    /// Returns a new bitmap containing bits that are in either `bitmap1` or `bitmap2`, but not in both.
    /// This implements symmetric difference (A ⊕ B).
    public func symmetricDifference(bitmap1 : BitMap, bitmap2 : BitMap) : BitMap {
        let result = clone(bitmap1);
        symmetricDifferenceInPlace(result, bitmap2);
        result;
    };

    public func vals(bitmap : BitMap) : Iter.Iter<Nat> {
        if (Vector.size(bitmap.words) == 0) return {
            next = func() : ?Nat = null;
        };

        var word_index = 0;
        var word : Nat64 = Vector.get(bitmap.words, word_index);
        var n = 0;

        object {
            public func next() : ?Nat {
                if (word_index >= Vector.size(bitmap.words)) return null;

                while (word == 0) {
                    n += WORD_SIZE;
                    word_index += 1;
                    if (word_index >= Vector.size(bitmap.words)) return null;
                    word := Vector.get(bitmap.words, word_index);
                };

                let position = Nat64.toNat(Nat64.bitcountTrailingZero(word));
                word &= (word - 1); // Clear the least significant set bit

                ?(n + position);
            };
        };
    };

    public func toArray(bitmap : BitMap) : [Nat] {
        let iter = vals(bitmap);

        Array.tabulate(
            bitmap.filled_positions,
            func(i : Nat) : Nat {
                let ?val = iter.next() else Debug.trap("Unexpected end of iterator in toArray");
                val;
            },
        );
    };

    public func multiUnion(bitmaps : Iter.Iter<BitMap>) : BitMap {
        let bitmap = switch (bitmaps.next()) {
            case (?first) { clone(first) };
            case (null) { return empty() };
        };

        var only_one = true;

        label merging_bitmaps loop switch (bitmaps.next()) {
            case (?bitmap2) {
                only_one := false;
                _union_no_size_update(bitmap, bitmap2);
            };
            case (null) break merging_bitmaps;
        };

        if (not only_one) {
            _update_size(bitmap);
        };

        bitmap;
    };

    public func multiIntersect(bitmaps : Iter.Iter<BitMap>) : BitMap {
        let bitmap = switch (bitmaps.next()) {
            case (?first) { clone(first) };
            case (null) { return empty() };
        };

        var only_one = true;

        label merging_bitmaps loop switch (bitmaps.next()) {
            case (?bitmap2) {
                only_one := false;
                _intersect_no_size_update(bitmap, bitmap2);
            };
            case (null) break merging_bitmaps;
        };

        if (not only_one) {
            _update_size(bitmap);
        };

        bitmap;
    };

    public func _update_size(bitmap : BitMap) {
        bitmap.filled_positions := 0;

        for (i in Iter.range(0, Vector.size(bitmap.words) - 1)) {
            bitmap.filled_positions += Nat64.toNat(Nat64.bitcountNonZero(Vector.get(bitmap.words, i)));
        };
    };

    public func _union_no_size_update(bitmap1 : BitMap, bitmap2 : BitMap) {
        if (Vector.size(bitmap2.words) * WORD_SIZE > capacity(bitmap1)) {
            grow(bitmap1, Vector.size(bitmap2.words) * WORD_SIZE);
        };

        let end = Nat.min(capacity(bitmap1), capacity(bitmap2)) / WORD_SIZE;

        if (capacity(bitmap1) == 0) return;

        var i = 0;
        while (i < end) {
            let other_word = Vector.get(bitmap2.words, i);
            let curr_word = Vector.get(bitmap1.words, i);

            let new_word = curr_word | other_word;

            Vector.put(bitmap1.words, i, new_word);

            i += 1;
        };
    };

    public func _intersect_no_size_update(bitmap1 : BitMap, bitmap2 : BitMap) {
        if (capacity(bitmap2) < capacity(bitmap1)) {
            // it's assumed that the bits at the positions that are not present in the other bitmap are false or empty
            // since they are all empty and it's an intersection, we can set all the bits in the extra words to 0

            let start = capacity(bitmap2) / WORD_SIZE;
            let end = capacity(bitmap1) / WORD_SIZE;

            for (i in Iter.range(start, end - 1)) {
                Vector.put(bitmap1.words, i, 0 : Nat64);
            };
        };

        if (capacity(bitmap1) == 0) return;

        let end = Nat.min(capacity(bitmap1), capacity(bitmap2)) / WORD_SIZE;

        for (i in Iter.range(0, end - 1)) {
            let other_word = Vector.get(bitmap2.words, i);
            let curr_word = Vector.get(bitmap1.words, i);
            let new_word = curr_word & other_word;

            Vector.put(bitmap1.words, i, new_word);
        };
    };

};
