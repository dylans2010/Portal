import Foundation
import MachO
import Darwin

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
        let magic = mutableData.withUnsafeBytes { $0.load(as: UInt32.self) }

        if magic == FAT_MAGIC || magic == FAT_CIGAM {
            return try stripFat(magic: magic)
        } else if isMachOMagic(magic) {
            return try stripThin(offset: 0)
        } else {
            throw MachOStripperError.invalidMachO
        }
    }

    private func isMachOMagic(_ magic: UInt32) -> Bool {
        return magic == MH_MAGIC || magic == MH_CIGAM || magic == MH_MAGIC_64 || magic == MH_CIGAM_64
    }

    private func stripFat(magic: UInt32) throws -> Data {
        let isBigEndian = magic == FAT_CIGAM

        let headerSize = MemoryLayout<fat_header>.size
        guard data.count >= headerSize else { throw MachOStripperError.invalidMachO }

        var header = data.withUnsafeBytes { $0.load(as: fat_header.self) }
        if isBigEndian {
            header.nfat_arch = header.nfat_arch.byteSwapped
        }

        let archSize = MemoryLayout<fat_arch>.size
        var mutableData = data

        for i in 0..<Int(header.nfat_arch) {
            let offset = headerSize + i * archSize
            guard data.count >= offset + archSize else { throw MachOStripperError.invalidMachO }

            var arch = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: fat_arch.self) }
            if isBigEndian {
                arch.offset = arch.offset.byteSwapped
                arch.size = arch.size.byteSwapped
            }

            let thinData = data.subdata(in: Int(arch.offset)..<Int(arch.offset + arch.size))
            let stripper = MachOStripper(data: thinData)
            let strippedThinData = try stripper.stripThin(offset: 0)

            // This is tricky because stripping the signature might change the size.
            // But usually we just remove the load command and maybe truncate.
            // If we truncate, we might need to update the fat_arch size.

            mutableData.replaceSubrange(Int(arch.offset)..<Int(arch.offset + arch.size), with: strippedThinData)

            var newSize = UInt32(strippedThinData.count)
            if isBigEndian {
                newSize = newSize.byteSwapped
            }

            // Update arch size in fat header if it changed
            let sizeOffset = offset + 12 // cputype(4) + cpusubtype(4) + offset(4)
            mutableData.replaceSubrange(sizeOffset..<(sizeOffset + 4), with: withUnsafeBytes(of: newSize) { Data($0) })
        }

        return mutableData
    }

    func appendSignature(_ signature: Data) throws -> Data {
        var mutableData = data
        let magic = mutableData.withUnsafeBytes { $0.load(as: UInt32.self) }

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
        let magic = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
        let is64Bit = magic == MH_MAGIC_64 || magic == MH_CIGAM_64
        let isBigEndian = magic == MH_CIGAM || magic == MH_CIGAM_64

        let headerSize = is64Bit ? MemoryLayout<mach_header_64>.size : MemoryLayout<mach_header>.size

        var ncmds: UInt32 = 0
        var sizeofcmds: UInt32 = 0

        if is64Bit {
            var header = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header_64.self) }
            ncmds = isBigEndian ? header.ncmds.byteSwapped : header.ncmds
            sizeofcmds = isBigEndian ? header.sizeofcmds.byteSwapped : header.sizeofcmds
        } else {
            var header = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header.self) }
            ncmds = isBigEndian ? header.ncmds.byteSwapped : header.ncmds
            sizeofcmds = isBigEndian ? header.sizeofcmds.byteSwapped : header.sizeofcmds
        }

        // 1. Append signature data at the end (aligned to 16 bytes)
        let originalLength = mutableData.count
        let padding = (16 - (originalLength % 16)) % 16
        if padding > 0 {
            mutableData.append(Data(repeating: 0, count: padding))
        }

        let signatureOffset = UInt32(mutableData.count)
        mutableData.append(signature)
        let signatureSize = UInt32(signature.count)

        // 2. Add LC_CODE_SIGNATURE load command
        var sigCmd = linkedit_data_command()
        sigCmd.cmd = isBigEndian ? UInt32(LC_CODE_SIGNATURE).byteSwapped : UInt32(LC_CODE_SIGNATURE)
        sigCmd.cmdsize = isBigEndian ? UInt32(MemoryLayout<linkedit_data_command>.size).byteSwapped : UInt32(MemoryLayout<linkedit_data_command>.size)
        sigCmd.dataoff = isBigEndian ? signatureOffset.byteSwapped : signatureOffset
        sigCmd.datasize = isBigEndian ? signatureSize.byteSwapped : signatureSize

        let newCmdOffset = offset + headerSize + Int(sizeofcmds)
        mutableData.replaceSubrange(newCmdOffset..<newCmdOffset, with: withUnsafeBytes(of: sigCmd) { Data($0) })

        // 3. Update Header
        let newNcmds = ncmds + 1
        let newSizeofcmds = sizeofcmds + UInt32(MemoryLayout<linkedit_data_command>.size)

        if is64Bit {
            var header = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header_64.self) }
            header.ncmds = isBigEndian ? newNcmds.byteSwapped : newNcmds
            header.sizeofcmds = isBigEndian ? newSizeofcmds.byteSwapped : newSizeofcmds
            mutableData.replaceSubrange(offset..<(offset + MemoryLayout<mach_header_64>.size), with: withUnsafeBytes(of: header) { Data($0) })
        } else {
            var header = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header.self) }
            header.ncmds = isBigEndian ? newNcmds.byteSwapped : newNcmds
            header.sizeofcmds = isBigEndian ? newSizeofcmds.byteSwapped : newSizeofcmds
            mutableData.replaceSubrange(offset..<(offset + MemoryLayout<mach_header>.size), with: withUnsafeBytes(of: header) { Data($0) })
        }

        // 4. Update __LINKEDIT segment
        var currentCmdOffset = offset + headerSize
        for _ in 0..<Int(ncmds) {
            let cmd = machoData.withUnsafeBytes { $0.load(fromByteOffset: currentCmdOffset, as: load_command.self) }
            let cmdType = isBigEndian ? cmd.cmd.byteSwapped : cmd.cmd
            let cmdSize = isBigEndian ? cmd.cmdsize.byteSwapped : cmd.cmdsize

            if cmdType == LC_SEGMENT_64 {
                var seg = mutableData.withUnsafeBytes { $0.load(fromByteOffset: currentCmdOffset, as: segment_command_64.self) }
                let segName = withUnsafeBytes(of: seg.segname) { String(cString: $0.baseAddress!.assumingMemoryBound(to: CChar.self)) }
                if segName == "__LINKEDIT" {
                    let fileOff = isBigEndian ? seg.fileoff.byteSwapped : seg.fileoff
                    let newFilesize = UInt64(signatureOffset + signatureSize) - fileOff
                    seg.filesize = isBigEndian ? newFilesize.byteSwapped : newFilesize
                    seg.vmsize = isBigEndian ? ((newFilesize + 4095) & ~4095).byteSwapped : (newFilesize + 4095) & ~4095
                    mutableData.replaceSubrange(currentCmdOffset..<(currentCmdOffset + MemoryLayout<segment_command_64>.size), with: withUnsafeBytes(of: seg) { Data($0) })
                }
            } else if cmdType == LC_SEGMENT {
                var seg = mutableData.withUnsafeBytes { $0.load(fromByteOffset: currentCmdOffset, as: segment_command.self) }
                let segName = withUnsafeBytes(of: seg.segname) { String(cString: $0.baseAddress!.assumingMemoryBound(to: CChar.self)) }
                if segName == "__LINKEDIT" {
                    let fileOff = isBigEndian ? seg.fileoff.byteSwapped : seg.fileoff
                    let newFilesize = UInt32(signatureOffset + signatureSize) - fileOff
                    seg.filesize = isBigEndian ? newFilesize.byteSwapped : newFilesize
                    seg.vmsize = isBigEndian ? ((newFilesize + 4095) & ~4095).byteSwapped : (newFilesize + 4095) & ~4095
                    mutableData.replaceSubrange(currentCmdOffset..<(currentCmdOffset + MemoryLayout<segment_command>.size), with: withUnsafeBytes(of: seg) { Data($0) })
                }
            }
            currentCmdOffset += Int(cmdSize)
        }

        return mutableData
    }

    private func stripThin(offset: Int) throws -> Data {
        let magic = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
        let is64Bit = magic == MH_MAGIC_64 || magic == MH_CIGAM_64
        let isBigEndian = magic == MH_CIGAM || magic == MH_CIGAM_64

        let headerSize = is64Bit ? MemoryLayout<mach_header_64>.size : MemoryLayout<mach_header>.size
        guard data.count >= offset + headerSize else { throw MachOStripperError.invalidMachO }

        var ncmds: UInt32 = 0
        var sizeofcmds: UInt32 = 0

        if is64Bit {
            var header = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header_64.self) }
            if isBigEndian {
                header.ncmds = header.ncmds.byteSwapped
                header.sizeofcmds = header.sizeofcmds.byteSwapped
            }
            ncmds = header.ncmds
            sizeofcmds = header.sizeofcmds
        } else {
            var header = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header.self) }
            if isBigEndian {
                header.ncmds = header.ncmds.byteSwapped
                header.sizeofcmds = header.sizeofcmds.byteSwapped
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
                cmdType = cmdType.byteSwapped
                cmdSize = cmdSize.byteSwapped
            }

            if cmdType == LC_CODE_SIGNATURE {
                let sigCmd = mutableData.withUnsafeBytes { $0.load(fromByteOffset: currentOffset, as: linkedit_data_command.self) }
                var dataOff = sigCmd.dataoff
                var dataSize = sigCmd.datasize
                if isBigEndian {
                    dataOff = dataOff.byteSwapped
                    dataSize = dataSize.byteSwapped
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
            let moveSize = Int(sizeofcmds) - (cmdOffset - (offset + headerSize)) - Int(isBigEndian ? cmdSize.byteSwapped : cmdSize)

            if moveSize > 0 {
                let nextCmdOffset = cmdOffset + Int(isBigEndian ? cmdSize.byteSwapped : cmdSize)
                let subsequentData = mutableData.subdata(in: nextCmdOffset..<(nextCmdOffset + moveSize))
                mutableData.replaceSubrange(cmdOffset..<(cmdOffset + moveSize), with: subsequentData)
            }

            // Zero out the remaining space in load commands
            let zeroOffset = offset + headerSize + Int(newSizeofcmds)
            let zeroSize = Int(isBigEndian ? cmdSize.byteSwapped : cmdSize)
            mutableData.replaceSubrange(zeroOffset..<(zeroOffset + zeroSize), with: Data(repeating: 0, count: zeroSize))

            // 2. Update Mach-O Header
            if is64Bit {
                var header = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header_64.self) }
                header.ncmds = isBigEndian ? newNcmds.byteSwapped : newNcmds
                header.sizeofcmds = isBigEndian ? newSizeofcmds.byteSwapped : newSizeofcmds
                mutableData.replaceSubrange(offset..<(offset + MemoryLayout<mach_header_64>.size), with: withUnsafeBytes(of: header) { Data($0) })
            } else {
                var header = mutableData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: mach_header.self) }
                header.ncmds = isBigEndian ? newNcmds.byteSwapped : newNcmds
                header.sizeofcmds = isBigEndian ? newSizeofcmds.byteSwapped : newSizeofcmds
                mutableData.replaceSubrange(offset..<(offset + MemoryLayout<mach_header>.size), with: withUnsafeBytes(of: header) { Data($0) })
            }

            // 3. Adjust __LINKEDIT segment
            if let linkEditOffset = linkEditCommandOffset {
                if is64Bit {
                    var seg = mutableData.withUnsafeBytes { $0.load(fromByteOffset: linkEditOffset, as: segment_command_64.self) }
                    var vmsize = isBigEndian ? seg.vmsize.byteSwapped : seg.vmsize
                    var filesize = isBigEndian ? seg.filesize.byteSwapped : seg.filesize

                    let newFilesize = UInt64(sigOffset) - (isBigEndian ? seg.fileoff.byteSwapped : seg.fileoff)
                    seg.filesize = isBigEndian ? newFilesize.byteSwapped : newFilesize

                    let newVmsize = (newFilesize + 4095) & ~4095
                    seg.vmsize = isBigEndian ? newVmsize.byteSwapped : newVmsize

                    mutableData.replaceSubrange(linkEditOffset..<(linkEditOffset + MemoryLayout<segment_command_64>.size), with: withUnsafeBytes(of: seg) { Data($0) })
                } else {
                    var seg = mutableData.withUnsafeBytes { $0.load(fromByteOffset: linkEditOffset, as: segment_command.self) }

                    let newFilesize = UInt32(sigOffset) - (isBigEndian ? seg.fileoff.byteSwapped : seg.fileoff)
                    seg.filesize = isBigEndian ? newFilesize.byteSwapped : newFilesize

                    let newVmsize = (newFilesize + 4095) & ~4095
                    seg.vmsize = isBigEndian ? newVmsize.byteSwapped : newVmsize

                    mutableData.replaceSubrange(linkEditOffset..<(linkEditOffset + MemoryLayout<segment_command>.size), with: withUnsafeBytes(of: seg) { Data($0) })
                }
            }

            // 4. Truncate the data to remove the signature
            mutableData = mutableData.subdata(in: 0..<sigOffset)
        }

        return mutableData
    }
}
