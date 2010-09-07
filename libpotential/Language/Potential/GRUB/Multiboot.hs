{-
  Copyright 2010 Timothy Carstens    carstens@math.utah.edu

  This file is part of the Potential Standard Library.

    The Potential Standard Library is free software: you can redistribute it
    and/or modify it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, version 3 of the License.

    The Potential Standard Library is distributed in the hope that it will be
    useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with the Potential Standard Library.  If not, see
    <http://www.gnu.org/licenses/>.
-}
{-# LANGUAGE
	EmptyDataDecls,
        NoImplicitPrelude,
        NoMonomorphismRestriction,
        MultiParamTypeClasses,
        FlexibleInstances,
        FlexibleContexts,
        ScopedTypeVariables,
        TypeFamilies,
        TemplateHaskell,
        QuasiQuotes
	#-}
module Language.Potential.GRUB.Multiboot where

import Language.Potential.Core
import Language.Potential.DataStructure


[$struct_diagram| VideoHeader

                          NoVideoHeader

                           VideoHeader

    |63-----------------------32|31------------------------0|
    |           depth           |           height          | 8
    |---------------------------|---------------------------|

    |63-----------------------32|31------------------------0|
    |           width           |          mode_type        | 0
    |---------------------------|---------------------------|

|]

[$struct_diagram| EntryHeader

                          NoEntryHeader

                           EntryHeader

    |63-----------------------32|31------------------------0|
    |       entry_addr          |        bss_end_addr       | 12
    |---------------------------|---------------------------|

    |95---------------64|63-------------32|31--------------0|
    |   load_end_addr   |    load_addr    |    header_addr  | 0
    |-------------------|-----------------|-----------------|

|]

[$struct_diagram| MultibootHeader

			MultibootHeader

    |127---------------------------------------------------0|
    |                         video                         | 32
    |-------------------------------------------------------|

    |159---------------------------------------------------0|
    |                    alt_load_addrs                     | 12
    |-------------------------------------------------------|

    |31----------------------------------------------------0|
    |                        checksum                       | 8
    |-------------------------------------------------------|

    |31--------------------------------17|--------16--------|
    |               reserved             | alt_load_addrs_p | 6
    |------------------------------------|------------------|
                                           ( bootloader must
                                           ( use the values
                                           ( in alt_load_addrs
                                           ( when loading the
                                           ( kernel

    |15-------3|--------2-------|-------1------|-----0------|
    | reserved | req_video_info | req_mem_info | align_mods | 4
    |----------|----------------|--------------|------------|
                        (               (        ( modules must
                        (               (        ( be loaded along
                        (               (        ( page boundaries
                        (               (
                        (               ( mem_* fields of
                        (               ( Multiboot info struct
                        (               ( must be populated
                        (
                        ( info about the video mode table must
                        ( be in the Multiboot info struct

    |31----------------------------------------------------0|
    |                         magic                         | 0
    |-------------------------------------------------------|
|]


[$struct_diagram| VBEInformation

                         NoVBEInformation

                          VBEInformation

    |31-----------------------16|15------------------------0|
    |     vbe_interface_len     |     vbe_interface_off     | 12
    |---------------------------|---------------------------|

    |31-----------------------16|15------------------------0|
    |     vbe_interface_seg     |          vbe_mode         | 8
    |---------------------------|---------------------------|

    |63-----------------------32|31------------------------0|
    |        vbe_mode_info      |      vbe_control_info     | 0
    |---------------------------|---------------------------|

|]

[$struct_diagram| BootDevice

			 NoBootDevice

			  BootDevice

    |31---------24|23--------12|11-----------8|7-----------0|
    |    part3    |    part2   |    part1     |    drive    | 0
    |-------------|------------|--------------|-------------|
|]

[$struct_diagram| Module

			    NoModule

			     Module

    |63----------------------32|31-------------------------0|
    |          reserved        |          mod_string        | 8
    |--------------------------|----------------------------|

    |63----------------------32|31-------------------------0|
    |           mod_end        |          mod_start         | 0
    |--------------------------|----------------------------|

|]

[$struct_diagram| DrivesInfo

                           NoDrivesInfo

                            DrivesInfo

    |63-----------------------32|31------------------------0|
    |        drives_addr        |        drives_length      | 0
    |---------------------------|---------------------------|

|]

[$struct_diagram| MMapInfo

                            NoMMapInfo

                             MMapInfo

    |63-----------------------32|31------------------------0|
    |         mmap_addr         |         mmap_length       | 0
    |---------------------------|---------------------------|

|]

[$struct_diagram| SymInfo

                            NoSymInfo

                           AOutSymInfo

    |127--------96|95---------64|63---------32|31----------0|
    |  reserved   |     addr    |   strsize   |   tabsize   | 0
    |-------------|-------------|-------------|-------------|

                            ElfSymInfo

    |127--------96|95---------64|63---------32|31----------0|
    |    shndx    |     addr    |     size    |     num     | 0
    |-------------|-------------|-------------|-------------|

|]

[$struct_diagram| ModsInfo

                            NoModsInfo

                             ModsInfo

    |63-----------------------32|31------------------------0|
    |         mods_addr         |         mods_length       | 0
    |---------------------------|---------------------------|

|]

[$struct_diagram| MemInfo

                            NoMemInfo

                             MemInfo

    |63-----------------------32|31------------------------0|
    |         mem_upper         |         mem_lower         | 0
    |---------------------------|---------------------------|

|]

[$struct_diagram| MultibootInformation

			MultibootInformation

    |159----------------------32|31------------------------0|
    |          vbe_info         |         apm_table         | 68
    |---------------------------|---------------------------|

    |63-----------------------32|31------------------------0|
    |      boot_loader_name     |        config_table       | 60
    |---------------------------|---------------------------|

    |319-------256|255-------192|191--------64|63----------0|
    | drives_info |  mmap_info  |  sym_info   |  mods_info  | 20
    |-------------|-------------|-------------|-------------|

    |63-----------------------32|31------------------------0|
    |         cmd_line          |        boot_device        | 12
    |---------------------------|---------------------------|

    |63----------------------------------------------------0|
    |                       mem_info                        | 4
    |-------------------------------------------------------|

    |31---------------------------------------------------12|
    |                       reserved                        | 0.75
    |-------------------------------------------------------|

    |----11-----|-----10------|-------9-------|------8------|
    |   vbe_p   | apm_table_p | loader_name_p | cfg_table_p | 0.5
    |-----------|-------------|---------------|-------------|

    |------7-----|-----6------|-------5------|------4-------|
    |  drives_p  |   mmap_p   |   sym_elf_p  |  sym_aout_p  | 0.25
    |------------|------------|--------------|--------------|

    |------3-----|--------2-------|--------1-------|----0---|
    |   mods_p   |   cmd_line_p   |   boot_dev_p   |  mem_p | 0
    |------------|----------------|----------------|--------|
|]


