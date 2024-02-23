const std = @import("std");

fn noopLog(comptime _: []const u8, _: anytype) void {}
const debugLog = noopLog;
//const debugLog = std.debug.print;

const biggus_modulus = 3318308475676071413;
const optimus_primus = 1499;

var hashes: [2_000_001]u128 = undefined;
var primes: [300_001]u128 = undefined;

fn str_hash(
    a: usize,
    b: usize,
) u128 {
    const left = (primes[b - a] *% hashes[a]) % biggus_modulus;
    const wrapped_h = ((hashes[b] -% left +% biggus_modulus) % biggus_modulus);
    return wrapped_h;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    const source_buf = try alloc.alloc(u8, 2_000_001);
    var buffered = std.io.bufferedReaderSize(1024 * 1024, std.io.getStdIn().reader());
    const inp = buffered.reader();

    var slowOutput = std.io.getStdOut();
    var bufferedOutput = std.io.bufferedWriter(slowOutput.writer());
    const writer = bufferedOutput.writer();

    var prime_acc: u128 = 1;
    for (&primes) |*prime| {
        prime.* = prime_acc;
        prime_acc = (prime_acc *% optimus_primus) % biggus_modulus;
    }

    while (try inp.readUntilDelimiterOrEof(source_buf, '\n')) |source| {
        var hash: u128 = 0;
        hashes[0] = 0;
        for (source, 1..) |c, i| {
            hash = ((hash *% optimus_primus) % biggus_modulus) + @as(u128, @as(u8, c -% 'a' +% 1)) % biggus_modulus;
            hashes[i] = hash;
            //std.debug.print("{c} at {d}: {d}\n", .{ c, i, hash });
        }

        for (1..source.len) |test_length| {
            if (source.len % test_length != 0) {
                continue;
            }

            const a_hash = str_hash(0, test_length);
            _ = a_hash;

            // If only there was a way to compute the hash of a_hash ^ n

            writer.print("HAR HAR HAR0\n", .{});
        }
    }

    try bufferedOutput.flush();
}
