const std = @import("std");
const testing = std.testing;

pub fn ArgIterator(comptime IteratorType: type) type {
    return struct {
        const NextFn = *const fn (*IteratorType) ?[]const u8;
        const Self = @This();

        underlying: *IteratorType,
        nextFn: NextFn,

        pub fn init(it: *IteratorType, nextFn: NextFn) Self {
            return .{
                .underlying = it,
                .nextFn = nextFn,
            };
        }

        fn fromProcessArgIterator(iter: *std.process.ArgIterator) ArgIterator(std.process.ArgIterator) {
            return .{
                .underlying = iter,
                .nextFn = std.process.ArgIterator.next,
            };
        }

        pub fn next(self: *Self) ?[]const u8 {
            return self.nextFn(self.underlying);
        }
    };
}

pub const MockArgIterator = struct {
    args: []const []const u8,
    idx: usize = 0,

    pub fn init(args: []const []const u8) MockArgIterator {
        return .{
            .args = args,
        };
    }

    pub fn next(self: *MockArgIterator) ?[]const u8 {
        if (self.idx >= self.args.len) {
            return null;
        }
        defer self.idx += 1;
        return self.args[self.idx];
    }
};

test "adapting std.process.ArgIterator" {
    var args = try std.process.argsWithAllocator(testing.allocator);
    defer args.deinit();
    var iter = ArgIterator(std.process.ArgIterator).fromProcessArgIterator(&args);
    _ = iter.next();
}

test "adapting MockArgIterator" {
    var args = MockArgIterator.init(&[_][]const u8{ "foo", "bar", "baz" });
    var iter = ArgIterator(MockArgIterator).init(&args, MockArgIterator.next);
    try testing.expectEqualStrings("foo", iter.next().?);
    try testing.expectEqualStrings("bar", iter.next().?);
    try testing.expectEqualStrings("baz", iter.next().?);
    try testing.expectEqual(null, iter.next());
}
