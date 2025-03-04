const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const testing = std.testing;

pub const Value = union {
    Int8: i8,
    Int16: i16,
    Int32: i32,
    Int64: i64,
    UInt8: u8,
    UInt16: u16,
    UInt32: u32,
    UInt64: u64,
    Float32: f32,
    Float64: f64,
    Bool: bool,
    String: []const u8,
};

pub const Flag = struct {
    short: ?[]const u8,
    long: ?[]const u8,
    description: ?[]const u8,
    value: ?Value,
    allocator: mem.Allocator,

    pub fn init(allocator: mem.Allocator, short: ?[]const u8, long: ?[]const u8, description: ?[]const u8, value: ?Value) error{NoNameSpecified}!Flag {
        if (short == null and long == null) {
            return error.NoNameSpecified;
        }

        return .{
            .short = short,
            .long = long,
            .description = description,
            .value = value,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Flag) void {
        if (self.value == .String) |s| {
            self.allocator.free(s);
        }
    }
};

pub const Flags = struct {
    usage: *const fn (allocator: mem.Allocator) void = defaultUsage,
    name: [:0]const u8 = "example",
    allocator: std.mem.Allocator,
    flags: FlagArray,

    const FlagArray = std.ArrayList(Flag);
    const GPA = std.heap.GeneralPurposeAllocator(.{});

    pub fn init(allocator: std.mem.Allocator) Flags {
        return .{
            .allocator = allocator,
            .flags = FlagArray.init(allocator),
        };
    }

    pub fn deinit(self: *Flags) void {
        self.flags.deinit();
    }

    fn defaultUsage(allocator: mem.Allocator) void {
        var args = std.process.argsWithAllocator(allocator) catch {
            return;
        };
        defer args.deinit();

        if (args.next()) |arg| {
            std.io.getStdErr().writer().print("{s} [flags...] arguments...\n", .{arg}) catch {};
        }
    }

    pub fn addShortBoolOption(self: *Flags, name: []const u8, description: []const u8, default: Value) !void {
        const flag = try Flag.init(self.allocator, name, null, description, default);
        try self.flags.append(flag);
    }
};

test "defaultUsage" {
    Flags.defaultUsage();
}

test "addShortOption" {
    var flags = Flags.init(testing.allocator);
    try flags.addShortBoolOption("-p", "print", .{ .Bool = false });
    flags.deinit();
}
