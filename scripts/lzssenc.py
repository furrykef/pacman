#!/usr/bin/env python
# LZSS compressor for Pac-Man
# Written for Python 3.4
import argparse
import sys


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]
    args = get_args(argv)
    with open(args.src, 'rb') as infile:
        src = infile.read()
    with open(args.dest, 'wb') as outfile:
        window = []
        src_idx = 0
        window_idx = 0                      # from decoder's perspective (absolute index into 256-byte circular buffer)
        group_flags = 0
        group_bit = 1
        group = []
        while src_idx < len(src):
            match, match_offset = find_longest_match(src[src_idx:], window)
            if len(match) <= 2:
                # Write a literal
                window.append(src[src_idx])
                group.append(src[src_idx])
                src_idx += 1
                window_idx += 1
            else:
                # Write a backref
                window += match
                group_flags |= group_bit
                group += [len(match), (window_idx + match_offset) & 0xff]
                src_idx += len(match)
                window_idx += len(match)
            window = window[-256:]
            window_idx &= 0xff
            group_bit <<= 1
            if group_bit == 0x100:
                outfile.write(bytes([group_flags]))
                outfile.write(bytes(group))
                group = []
                group_flags = 0
                group_bit = 1
        group.append(0)
        group_flags |= group_bit
        outfile.write(bytes([group_flags]))
        outfile.write(bytes(group))


def find_longest_match(data, window):
    if len(window) == 0:
        return ([], 0)
    best_match = []
    best_match_pos = 0
    for i in range(len(window)):
        match = match_data(data, window[i:])
        if len(match) > len(best_match):
            best_match_pos = i
            best_match = match
    return best_match, best_match_pos - len(window)


def match_data(data, subwindow):
    match = []
    for i in range(255):
        if i == len(data):
            break
        next = subwindow[i % len(subwindow)]
        if data[i] != next:
            break
        match.append(next)
    return match


def get_args(argv):
    parser = argparse.ArgumentParser(
        prog="lzssenc",
        description="LZSS compressor for Pac-Man."
    )
    parser.add_argument('src')
    parser.add_argument('dest')
    return parser.parse_args(argv)


if __name__ == '__main__':
    sys.exit(main())
