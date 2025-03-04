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
    short: [:0]const u8,
    long: [:0]const u8,
    description: [:0]const u8,
    value: Value,
    allocator: mem.Allocator,

    pub fn init(allocator: mem.Allocator, short: [:0]const u8, long: [:0]const u8, description: [:0]const u8, value: Value) Flag {
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
    usage: *const fn () void = defaultUsage,
    name: [:0]const u8 = "example",
    allocator: std.mem.Allocator,
    flags: FlagArray,

    const FlagArray = std.ArrayList(?*anyopaque);
    const GPA = std.heap.GeneralPurposeAllocator(.{});

    pub fn init(allocator: std.mem.Allocator) Flags {
        return .{
            .allocator = allocator,
            .flags = FlagArray.init(allocator),
        };
    }

    fn defaultUsage() void {
        var gpa: GPA = .{};
        defer _ = gpa.deinit();

        var args = std.process.argsWithAllocator(gpa.allocator()) catch {
            return;
        };
        defer args.deinit();

        if (args.next()) |arg| {
            std.io.getStdErr().writer().print("{s} [flags...] arguments...\n", .{arg}) catch {};
        }
    }
};

test "defaultUsage" {
    Flags.defaultUsage();
}
