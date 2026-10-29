"""Losslessly split approved walk cels into standalone LibreSprite timelines."""
import json
import struct
from pathlib import Path

from ase_document import ROOT, chunk, string


def frames(raw):
    offset = 128
    result = []
    for _ in range(struct.unpack_from('<H', raw, 6)[0]):
        size = struct.unpack_from('<I', raw, offset)[0]
        cursor, chunks = offset + 16, []
        while cursor < offset + size:
            length, kind = struct.unpack_from('<IH', raw, cursor)
            chunks.append((kind, raw[cursor:cursor + length]))
            cursor += length
        assert cursor == offset + size
        result.append((raw[offset:offset + 16], chunks))
        offset += size
    assert offset == len(raw)
    return result


def main():
    source = ROOT / 'assets/characters/combat/sources'
    output = source / 'walking'
    output.mkdir(exist_ok=True)
    layout = json.loads((source.parent / 'layout.json').read_text())
    clips = [(name, clip['frames']) for name, clip in layout['animations'].items()
             if name.startswith('walk_')]
    indices = [index for _, selected in clips for index in selected]
    tags = struct.pack('<H8x', len(clips))
    cursor = 0
    for name, selected in clips:
        tags += struct.pack('<HHB8x3BB', cursor, cursor + len(selected) - 1,
                            0, 71, 218, 203, 0) + string(name)
        cursor += len(selected)
    for actor in ('portador', 'portador_cenital', 'prefecto', 'madre'):
        raw = (source / (actor + '.ase')).read_bytes()
        original = frames(raw)
        metadata = [data for kind, data in original[0][1]
                    if kind not in (0x2005, 0x2018)]
        exported = []
        for index, old_index in enumerate(indices):
            header, chunks = original[old_index]
            cels = [data for kind, data in chunks if kind == 0x2005]
            # Linked cels require remapping; never silently export wrong references.
            assert all(struct.unpack_from('<H', cel, 13)[0] == 2 for cel in cels)
            content = (metadata + [chunk(0x2018, tags)] if index == 0 else []) + cels
            payload = b''.join(content)
            duration = struct.unpack_from('<H', header, 8)[0]
            exported.append(struct.pack('<IHHH2xI', len(payload) + 16,
                                        0xF1FA, len(content), duration, 0) + payload)
        header = bytearray(raw[:128])
        struct.pack_into('<I', header, 0, 128 + sum(map(len, exported)))
        struct.pack_into('<H', header, 6, len(exported))
        result = bytes(header) + b''.join(exported)
        for actual, old_index in zip(frames(result), indices):
            assert actual[0][8:10] == original[old_index][0][8:10]
            assert [data for kind, data in actual[1] if kind == 0x2005] == [
                data for kind, data in original[old_index][1] if kind == 0x2005]
        target = output / (actor + '_caminar.ase')
        target.write_bytes(result)
        print(target.relative_to(ROOT), '32 frames; original layers, cels and timing preserved')


if __name__ == '__main__':
    main()
