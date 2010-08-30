module Tests.Multiboot where

import Language.Potential

[$struct_diagram|
                        MultibootVideo

    |63-----------------------32|31------------------------0|
    |       depth :: Word32     |      height :: Word32     | 8
    |---------------------------|---------------------------|

    |63-----------------------32|31------------------------0|
    |       width :: Word32     |         mode_type         | 0
    |---------------------------|---------------------------|

|]

[$struct_diagram|
                          MultibootEntry

    |63-----------------------32|31------------------------0|
    |         entry_addr        |        bss_end_addr       | 12
    |---------------------------|---------------------------|

    |95---------------64|63-------------32|31--------------0|
    |   load_end_addr   |    load_addr    |    header_addr  | 0
    |-------------------|-----------------|-----------------|
|]

[$struct_diagram|
			 MultibootHeader

    |127---------------------------------------------------0|
    |    video :: Maybe MultibootVideo @ req_video_info     | 32
    |-------------------------------------------------------|

    |159---------------------------------------------------0|
    |        entry :: Maybe MultibootEntry @ use_entry      | 12
    |-------------------------------------------------------|

    |31----------------------------------------------------0|
    |                 checksum :: Word32                    | 8
    |-------------------------------------------------------|

    |31----------------------------------17|-------16-------|
    |                reserved              |   use_entry    | 6
    |--------------------------------------|----------------|
                                             ( bootloader must
                                             ( use the values
                                             ( in offsets 12-28
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
    |                    magic :: Word32                    | 0
    |-------------------------------------------------------|
|]


[$struct_diagram|
			MultibootInformation


    |127---------------------------------------------------0|
    |      vbe_info :: Maybe MultibootVBEInfo @ vbe_p       | 72
    |-------------------------------------------------------|

    |31----------------------------------------------------0|
    |                      apm_table                        | 68
    |-------------------------------------------------------|

    |63-----------------------32|31------------------------0|
    | boot_loader_name :: Maybe |        config_table       | 60
    |    String @ boot_name_p   |                           | 60
    |---------------------------|---------------------------|

    |63-----------------------32|31------------------------0|
    |        drives_addr        |        drives_length      | 52
    |---------------------------|---------------------------|

    |63-----------------------32|31------------------------0|
    |         mmap_addr         |         mmap_length       | 44
    |---------------------------|---------------------------|

    |127---------------------------------------------------0|
    | symbols :: MultibootSymbols @ (sym_elf_p:sym_aout_p)  | 28
    | NoSymbols (0:0), AOutSymbols (0:1), ElfSymbols (1:0)  |
    |-------------------------------------------------------|

    |63----------------------------------------------------0|
    |        mods_array :: Maybe ModsArray @ mods_p         | 20
    |-------------------------------------------------------|

    |63-----------------------32|31------------------------0|
    |  cmd_line :: Maybe String |    boot_device :: Maybe   | 12
    |       @ cmd_line_p        |  BootDevice @ boot_dev_p  |
    |---------------------------|---------------------------|

    |63----------------------------------------------------0|
    |         mem_limits :: Maybe MemLimits @ mem_p         | 4
    |-------------------------------------------------------|

    |31---------------------------------------------------12|
    |                       reserved                        | 3
    |-------------------------------------------------------|

    |-----11-----|-----10------|------9-------|-----8-------|
    |    vbe_p   | apm_table_p | boot_name_p  | cfg_table_p | 2
    |------------|-------------|--------------|-------------|

    |------7-----|-----6-----|-------5------|-------4-------|
    |  drives_p  |   mmap_p  |   sym_elf_p  |   sym_aout_p  | 1
    |------------|-----------|--------------|---------------|

    |------3-----|--------2-------|--------1-------|----0---|
    |   mods_p   |   cmd_line_p   |   boot_dev_p   |  mem_p | 0
    |------------|----------------|----------------|--------|
|]

[$struct_diagram|
                         MultibootSymbols

                            NoSymbols

                           AOutSymbols

    |63----------------------------------------------------0|
    |          reserved          |           addr           | 8
    |-------------------------------------------------------|

    |63----------------------------------------------------0|
    |          strsize           |          tabsize         | 0
    |-------------------------------------------------------|

                           ElfSymbols

    |63----------------------------------------------------0|
    |            shndx           |           addr           | 8
    |-------------------------------------------------------|

    |63----------------------------------------------------0|
    |            size            |            num           | 0
    |-------------------------------------------------------|
|]

[$struct_diagram|
                            ModsArray

    |63-----------------------32|31------------------------0|
    | mods_addr :: Array Module |    mods_count :: Word32   | 0
    |---------------------------|---------------------------|
|]

[$struct_diagram|
                            MemLimits

    |63-----------------------32|31------------------------0|
    |    mem_upper :: Word32    |     mem_lower :: Word32   | 0
    |---------------------------|---------------------------|
|]

[$struct_diagram|
                       MultibootVBEInfo

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

[$struct_diagram|
			     BootDevice

    |31----------24|23---------12|11----------8|7----------0|
    |     part3    |    part2    |    part1    |   drive    | 0
    |--------------|-------------|-------------|------------|
|]

[$struct_diagram|
			     Module

    |63----------------------32|31-------------------------0|
    |          reserved        |            string          | 8
    |--------------------------|----------------------------|

    |63----------------------32|31-------------------------0|
    |           mod_end        |          mod_start         | 0
    |--------------------------|----------------------------|
|]


