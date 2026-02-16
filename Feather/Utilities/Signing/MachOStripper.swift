import Foundation
import MachO

enum MachOStripperError: Error {
    case invalidMachO
    case unsupportedArchitecture
    case writeError
}

class MachOStripper {
    private var data: Data
    private var is64Bit: Bool = false
    private var isBigEndian: Bool = false

    init(data: Data) {
        self.data = data
    }

    static func strip(at url: URL) throws {
        let data = try Data(contentsOf: url)
        let stripper = MachOStripper(data: data)
        let strippedData = try stripper.strip()
        try strippedData.write(to: url)
    }

    func strip() throws -> Data {
        var mutableData = data
        let magic = mutableData.withUnsafeBytes { $0.load(as: uint32_t.self) }

        if magic == FAT_MAGIC || magic == FAT_CIGAM {
            return try stripFat(magic: magic)
        } else if isMachOMagic(magic) {
            return try stripThin(offset: 0)
        } else {
            throw MachOStripperError.invalidMachO
        }
    }

    private func isMachOMagic(_ magic: uint32_t) -> Bool {
        return magic == MH_MAGIC || magic == MH_CIGAM || magic == MH_MAGIC_64 || magic == MH_CIGAM_64
    }

    private func stripFat(magic: uint32_t) throws -> Data {
        let isBigEndian = magic == FAT_CIGAM

        let headerSize = MemoryLayout<fat_header>.size
        guard data.count >= headerSize else { throw MachOStripperError.invalidMachO }

        var header = data.withUnsafeBytes { $0.load(as: fat_header.self) }
        if isBigEndian {
            header.nfat_arch = OSSwapInt32(header.nfat_arch)
        }

        let archSize = MemoryLayout<fat_arch>.size
        var mutableData = data

        for i in 0..<Int(header.nfat_arch) {
            let offset = headerSize + i * archSize
            guard data.count >= offset + archSize else { throw MachOStripperError.invalidMachO }

            var arch = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: fat_arch.self) }
            if isBigEndian {
                arch.offset = OSSwapInt32(arch.offset)
                arch.size = OSSwapInt32(arch.size)
            }

            let thinData = data.subdata(in: Int(arch.offset)..<Int(arch.offset + arch.size))
            let stripper = MachOStripper(data: thinData)
            let strippedThinData = try stripper.stripThin(offset: 0)

            // This is tricky because stripping the signature might change the size.
            // But usually we just remove the load command and maybe truncate.
            // If we truncate, we might need to update the fat_arch size.

            mutableData.replaceSubdata(in: Int(arch.offset)..<Int(arch.offset + arch.size), with: strippedThinData)

            var newSize = uint32_t(strippedThinData.count)
            if isBigEndian {
                newSize = OSSwapInt32(newSize)
            }

            // Update arch size in fat header if it changed
            let sizeOffset = offset + 12 // cputype(4) + cpusubtype(4) + offset(4)
            mutableData.replaceSubdata(in: sizeOffset..<(sizeOffset + 4), with: withUnsafeBytes(of: newSize) { Data($0) })
        }

        return mutableData
    }

    func appendSignature(_ signature: Data) throws -> Data {
        var mutableData = data
        let magic = mutableData.withUnsafeBytes { $0.load(as: uint32_t.self) }

        if magic == FAT_MAGIC || magic == FAT_CIGAM {
            // Appending signature to Fat binary is complex because we need to append to each thin slice
            // and shift everything. For now, let's assume we are signing thin binaries or handle it properly.
            // Simplified: If it's Fat, throw error or implement properly.
            throw MachOStripperError.unsupportedArchitecture
        }

        return try appendSignatureThin(to: mutableData, signature: signature, offset: 0)
    }

    private func appendSignatureThin(to machoData: Data, signature: Data, offset: Int) throws -> Data {
        var mutableData = machoData
        let magic = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: uint32_t.self) }
        let is64Bit = magic == MH_MAGIC_64 || magic == MH_CIGAM_64
        let isBigEndian = magic == MH_CIGAM || magic == MH_CIGAM_64

        let headerSize = is64Bit ? MemoryLayout<mach_header_64>.size : MemoryLayout<mach_header>.size

        var ncmds: uint32_t = 0
        var sizeofcmds: uint32_t = 0

        if is64Bit {
            var header = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header_64.self) }
            ncmds = isBigEndian ? OSSwapInt32(header.ncmds) : header.ncmds
            sizeofcmds = isBigEndian ? OSSwapInt32(header.sizeofcmds) : header.sizeofcmds
        } else {
            var header = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header.self) }
            ncmds = isBigEndian ? OSSwapInt32(header.ncmds) : header.ncmds
            sizeofcmds = isBigEndian ? OSSwapInt32(header.sizeofcmds) : header.sizeofcmds
        }

        // 1. Append signature data at the end (aligned to 16 bytes)
        let originalLength = mutableData.count
        let padding = (16 - (originalLength % 16)) % 16
        if padding > 0 {
            mutableData.append(Data(repeating: 0, count: padding))
        }

        let signatureOffset = uint32_t(mutableData.count)
        mutableData.append(signature)
        let signatureSize = uint32_t(signature.count)

        // 2. Add LC_CODE_SIGNATURE load command
        var sigCmd = linkedit_data_command()
        sigCmd.cmd = isBigEndian ? OSSwapInt32(uint32_t(LC_CODE_SIGNATURE)) : uint32_t(LC_CODE_SIGNATURE)
        sigCmd.cmdsize = isBigEndian ? OSSwapInt32(uint32_t(MemoryLayout<linkedit_data_command>.size)) : uint32_t(MemoryLayout<linkedit_data_command>.size)
        sigCmd.dataoff = isBigEndian ? OSSwapInt32(signatureOffset) : signatureOffset
        sigCmd.datasize = isBigEndian ? OSSwapInt32(signatureSize) : signatureSize

        let newCmdOffset = offset + headerSize + Int(sizeofcmds)
        mutableData.replaceSubdata(in: newCmdOffset..<newCmdOffset, with: withUnsafeBytes(of: sigCmd) { Data($0) })

        // 3. Update Header
        let newNcmds = ncmds + 1
        let newSizeofcmds = sizeofcmds + uint32_t(MemoryLayout<linkedit_data_command>.size)

        if is64Bit {
            var header = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header_64.self) }
            header.ncmds = isBigEndian ? OSSwapInt32(newNcmds) : newNcmds
            header.sizeofcmds = isBigEndian ? OSSwapInt32(newSizeofcmds) : newSizeofcmds
            mutableData.replaceSubdata(in: offset..<(offset + MemoryLayout<mach_header_64>.size), with: withUnsafeBytes(of: header) { Data($0) })
        } else {
            var header = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header.self) }
            header.ncmds = isBigEndian ? OSSwapInt32(newNcmds) : newNcmds
            header.sizeofcmds = isBigEndian ? OSSwapInt32(newSizeofcmds) : newSizeofcmds
            mutableData.replaceSubdata(in: offset..<(offset + MemoryLayout<mach_header>.size), with: withUnsafeBytes(of: header) { Data($0) })
        }

        // 4. Update __LINKEDIT segment
        var currentCmdOffset = offset + headerSize
        for _ in 0..<Int(ncmds) {
            let cmd = machoData.withUnsafeBytes { $0.load(fromByteOffset: currentCmdOffset, as: load_command.self) }
            let cmdType = isBigEndian ? OSSwapInt32(cmd.cmd) : cmd.cmd
            let cmdSize = isBigEndian ? OSSwapInt32(cmd.cmdsize) : cmd.cmdsize

            if cmdType == LC_SEGMENT_64 {
                var seg = mutableData.withUnsafeBytes { $0.load(fromByteOffset: currentCmdOffset, as: segment_command_64.self) }
                let segName = withUnsafeBytes(of: seg.segname) { String(cString: $0.baseAddress!.assumingMemoryBound(to: CChar.self)) }
                if segName == "__LINKEDIT" {
                    let fileOff = isBigEndian ? OSSwapInt64(seg.fileoff) : seg.fileoff
                    let newFilesize = uint64_t(signatureOffset + signatureSize) - fileOff
                    seg.filesize = isBigEndian ? OSSwapInt64(newFilesize) : newFilesize
                    seg.vmsize = isBigEndian ? OSSwapInt64((newFilesize + 4095) & ~4095) : (newFilesize + 4095) & ~4095
                    mutableData.replaceSubdata(in: currentCmdOffset..<(currentCmdOffset + MemoryLayout<segment_command_64>.size), with: withUnsafeBytes(of: seg) { Data($0) })
                }
            } else if cmdType == LC_SEGMENT {
                var seg = mutableData.withUnsafeBytes { $0.load(fromByteOffset: currentCmdOffset, as: segment_command.self) }
                let segName = withUnsafeBytes(of: seg.segname) { String(cString: $0.baseAddress!.assumingMemoryBound(to: CChar.self)) }
                if segName == "__LINKEDIT" {
                    let fileOff = isBigEndian ? OSSwapInt32(seg.fileoff) : seg.fileoff
                    let newFilesize = uint32_t(signatureOffset + signatureSize) - fileOff
                    seg.filesize = isBigEndian ? OSSwapInt32(newFilesize) : newFilesize
                    seg.vmsize = isBigEndian ? OSSwapInt32((newFilesize + 4095) & ~4095) : (newFilesize + 4095) & ~4095
                    mutableData.replaceSubdata(in: currentCmdOffset..<(currentCmdOffset + MemoryLayout<segment_command>.size), with: withUnsafeBytes(of: seg) { Data($0) })
                }
            }
            currentCmdOffset += Int(cmdSize)
        }

        return mutableData
    }

    private func stripThin(offset: Int) throws -> Data {
        let magic = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: uint32_t.self) }
        let is64Bit = magic == MH_MAGIC_64 || magic == MH_CIGAM_64
        let isBigEndian = magic == MH_CIGAM || magic == MH_CIGAM_64

        let headerSize = is64Bit ? MemoryLayout<mach_header_64>.size : MemoryLayout<mach_header>.size
        guard data.count >= offset + headerSize else { throw MachOStripperError.invalidMachO }

        var ncmds: uint32_t = 0
        var sizeofcmds: uint32_t = 0

        if is64Bit {
            var header = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header_64.self) }
            if isBigEndian {
                header.ncmds = OSSwapInt32(header.ncmds)
                header.sizeofcmds = OSSwapInt32(header.sizeofcmds)
            }
            ncmds = header.ncmds
            sizeofcmds = header.sizeofcmds
        } else {
            var header = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header.self) }
            if isBigEndian {
                header.ncmds = OSSwapInt32(header.ncmds)
                header.sizeofcmds = OSSwapInt32(header.sizeofcmds)
            }
            ncmds = header.ncmds
            sizeofcmds = header.sizeofcmds
        }

        var currentOffset = offset + headerSize
        var codeSignatureOffset: Int?
        var codeSignatureSize: Int?
        var codeSignatureCommandOffset: Int?

        var linkEditCommandOffset: Int?

        var newNcmds = ncmds
        var newSizeofcmds = sizeofcmds

        var mutableData = data

        for _ in 0..<Int(ncmds) {
            guard mutableData.count >= currentOffset + MemoryLayout<load_command>.size else { break }
            let cmd = mutableData.withUnsafeBytes { $0.load(fromByteOffset: currentOffset, as: load_command.self) }
            var cmdType = cmd.cmd
            var cmdSize = cmd.cmdsize
            if isBigEndian {
                cmdType = OSSwapInt32(cmdType)
                cmdSize = OSSwapInt32(cmdSize)
            }

            if cmdType == LC_CODE_SIGNATURE {
                let sigCmd = mutableData.withUnsafeBytes { $0.load(fromByteOffset: currentOffset, as: linkedit_data_command.self) }
                var dataOff = sigCmd.dataoff
                var dataSize = sigCmd.datasize
                if isBigEndian {
                    dataOff = OSSwapInt32(dataOff)
                    dataSize = OSSwapInt32(dataSize)
                }
                codeSignatureOffset = Int(dataOff)
                codeSignatureSize = Int(dataSize)
                codeSignatureCommandOffset = currentOffset

                newNcmds -= 1
                newSizeofcmds -= cmdSize
            } else if cmdType == LC_SEGMENT_64 {
                let segCmd = mutableData.withUnsafeBytes { $0.load(fromByteOffset: currentOffset, as: segment_command_64.self) }
                let segName = withUnsafeBytes(of: segCmd.segname) { String(cString: $0.baseAddress!.assumingMemoryBound(to: CChar.self)) }
                if segName == "__LINKEDIT" {
                    linkEditCommandOffset = currentOffset
                }
            } else if cmdType == LC_SEGMENT {
                let segCmd = mutableData.withUnsafeBytes { $0.load(fromByteOffset: currentOffset, as: segment_command.self) }
                let segName = withUnsafeBytes(of: segCmd.segname) { String(cString: $0.baseAddress!.assumingMemoryBound(to: CChar.self)) }
                if segName == "__LINKEDIT" {
                    linkEditCommandOffset = currentOffset
                }
            }

            currentOffset += Int(cmdSize)
        }

        if let cmdOffset = codeSignatureCommandOffset, let sigOffset = codeSignatureOffset, let sigSize = codeSignatureSize {
            // 1. Remove the LC_CODE_SIGNATURE command by shifting subsequent commands
            let cmdSize = mutableData.withUnsafeBytes { $0.load(fromByteOffset: cmdOffset, as: load_command.self).cmdsize }
            let moveSize = Int(sizeofcmds) - (cmdOffset - (offset + headerSize)) - Int(isBigEndian ? OSSwapInt32(cmdSize) : cmdSize)

            if moveSize > 0 {
                let nextCmdOffset = cmdOffset + Int(isBigEndian ? OSSwapInt32(cmdSize) : cmdSize)
                let subsequentData = mutableData.subdata(in: nextCmdOffset..<(nextCmdOffset + moveSize))
                mutableData.replaceSubdata(in: cmdOffset..<(cmdOffset + moveSize), with: subsequentData)
            }

            // Zero out the remaining space in load commands
            let zeroOffset = offset + headerSize + Int(newSizeofcmds)
            let zeroSize = Int(isBigEndian ? OSSwapInt32(cmdSize) : cmdSize)
            mutableData.replaceSubdata(in: zeroOffset..<(zeroOffset + zeroSize), with: Data(repeating: 0, count: zeroSize))

            // 2. Update Mach-O Header
            if is64Bit {
                var header = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header_64.self) }
                header.ncmds = isBigEndian ? OSSwapInt32(newNcmds) : newNcmds
                header.sizeofcmds = isBigEndian ? OSSwapInt32(newSizeofcmds) : newSizeofcmds
                mutableData.replaceSubdata(in: offset..<(offset + MemoryLayout<mach_header_64>.size), with: withUnsafeBytes(of: header) { Data($0) })
            } else {
                var header = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header.self) }
                header.ncmds = isBigEndian ? OSSwapInt32(newNcmds) : newNcmds
                header.sizeofcmds = isBigEndian ? OSSwapInt32(newSizeofcmds) : newSizeofcmds
                mutableData.replaceSubdata(in: offset..<(offset + MemoryLayout<mach_header>.size), with: withUnsafeBytes(of: header) { Data($0) })
            }

            // 3. Adjust __LINKEDIT segment
            if let linkEditOffset = linkEditCommandOffset {
                if is64Bit {
                    var seg = mutableData.withUnsafeBytes { $0.load(fromByteOffset: linkEditOffset, as: segment_command_64.self) }
                    var vmsize = isBigEndian ? OSSwapInt64(seg.vmsize) : seg.vmsize
                    var filesize = isBigEndian ? OSSwapInt64(seg.filesize) : seg.filesize

                    let newFilesize = uint64_t(sigOffset) - (isBigEndian ? OSSwapInt64(seg.fileoff) : seg.fileoff)
                    seg.filesize = isBigEndian ? OSSwapInt64(newFilesize) : newFilesize

                    let newVmsize = (newFilesize + 4095) & ~4095
                    seg.vmsize = isBigEndian ? OSSwapInt64(newVmsize) : newVmsize

                    mutableData.replaceSubdata(in: linkEditOffset..<(linkEditOffset + MemoryLayout<segment_command_64>.size), with: withUnsafeBytes(of: seg) { Data($0) })
                } else {
                    var seg = mutableData.withUnsafeBytes { $0.load(fromByteOffset: linkEditOffset, as: segment_command.self) }

                    let newFilesize = uint32_t(sigOffset) - (isBigEndian ? OSSwapInt32(seg.fileoff) : seg.fileoff)
                    seg.filesize = isBigEndian ? OSSwapInt32(newFilesize) : newFilesize

                    let newVmsize = (newFilesize + 4095) & ~4095
                    seg.vmsize = isBigEndian ? OSSwapInt32(newVmsize) : newVmsize

                    mutableData.replaceSubdata(in: linkEditOffset..<(linkEditOffset + MemoryLayout<segment_command>.size), with: withUnsafeBytes(of: seg) { Data($0) })
                }
            }

            // 4. Truncate the data to remove the signature
            mutableData = mutableData.subdata(in: 0..<sigOffset)
        }

        return mutableData
    }
}
