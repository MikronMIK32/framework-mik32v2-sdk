set EEPROM_REGS_BASE_ADDRESS 0x00070400

set EEPROM_REGS_EEDAT [expr {($EEPROM_REGS_BASE_ADDRESS + 0x00)}]
set EEPROM_REGS_EEA [expr {($EEPROM_REGS_BASE_ADDRESS + 0x04)}]
set EEPROM_REGS_EECON [expr {($EEPROM_REGS_BASE_ADDRESS + 0x08)}]
set EEPROM_REGS_EESTA [expr {($EEPROM_REGS_BASE_ADDRESS + 0x0C)}]
set EEPROM_REGS_EERB [expr {($EEPROM_REGS_BASE_ADDRESS + 0x10)}]
set EEPROM_REGS_EEADJ [expr {($EEPROM_REGS_BASE_ADDRESS + 0x14)}]
set EEPROM_REGS_NCYCRL [expr {($EEPROM_REGS_BASE_ADDRESS + 0x18)}]
set EEPROM_REGS_NCYCEP1 [expr {($EEPROM_REGS_BASE_ADDRESS + 0x1C)}]
set EEPROM_REGS_NCYCEP2 [expr {($EEPROM_REGS_BASE_ADDRESS + 0x20)}]

#--------------------------
# EEPROM register fields
#--------------------------
#EECON
set EEPROM_EX_S         0
set EEPROM_OP_S         1
set EEPROM_WRBEH_S      3
set EEPROM_APBNWS_S     5
set EEPROM_DISECC_S     6
set EEPROM_BWE_S        7
set EEPROM_IESERR_S     8
#EESTA
set EEPROM_BSY_S        0
set EEPROM_SERR_S       1
#NCYCRL
set EEPROM_N_LD_S       0
set EEPROM_N_R_1_S      8
set EEPROM_N_R_2_S      16
#--------------------------
# EEPROM codes
#--------------------------
set EEPROM_OP_RD        0
set EEPROM_OP_ER        1
set EEPROM_OP_PR        2
set EEPROM_BEH_EVEN     1
set EEPROM_BEH_ODD      2
set EEPROM_BEH_GLOB     3

set EEPROM_PAGE_MASK    0x1F80

#set NO_CH  [expr (0<<1)] 

proc eeprom_print_error {a_text} {
	puts -nonewline "\033\[1;31m"; #RED
	puts "ERROR: $a_text"
	puts -nonewline "\033\[0m";# Reset
}

proc eeprom_sysinit {} {
	puts "MCU clock init..."
	mww 0x00060010 0x202
	mww 0x0005001C 0xffffffff
	mww 0x00050014 0xffffffff
	mww 0x0005000C 0xffffffff
} 

proc eeprom_global_erase {} {
	puts "EEPROM global erase..."
    mww $::EEPROM_REGS_NCYCRL [expr {(1<<$::EEPROM_N_LD_S  | 3<<$::EEPROM_N_R_1_S | 1 << $::EEPROM_N_R_2_S)}];
    mww $::EEPROM_REGS_NCYCEP1 100000;
    mww $::EEPROM_REGS_NCYCEP2 1000;
    sleep 100;
    mww $::EEPROM_REGS_EECON [expr {(1 << $::EEPROM_BWE_S) | ($::EEPROM_BEH_GLOB << $::EEPROM_WRBEH_S)}]; #prepare to buffer load
    mww $::EEPROM_REGS_EEA 0x00000000;
    #buffer load
    for {set i 0} {$i < 32} {incr i} {
        mww $::EEPROM_REGS_EEDAT 0x00000000;
    }
    #start operation
    mww $::EEPROM_REGS_EECON [expr {(1 << $::EEPROM_EX_S) | (1 << $::EEPROM_BWE_S) | ($::EEPROM_OP_ER << $::EEPROM_OP_S) | ($::EEPROM_BEH_GLOB << $::EEPROM_WRBEH_S)}];
	#eeprom_global_erase_check;
}

proc eeprom_global_erase_check {} {
	puts "EEPROM global erase check through APB...";
	puts "  Read Data at ..."
	set ex_value 0x00000000;
	mww $::EEPROM_REGS_EEA 0x00000000;
	for {set i 0} {$i < 64} {incr i} {
		puts "    Row=$i...";
		for {set j 0} {$j < 32} {incr j} {
			set value {};
			mem2array value 32 $::EEPROM_REGS_EEDAT 1;
			if {$ex_value != $value(0)} {
				eeprom_print_error "Unexpect value at Row $i, Word $j, expect $ex_value, get $value"
				return 1
			};
		}
	}
}

proc eeprom_write_word {a_addr a_data} {
    mww $::EEPROM_REGS_EECON [expr {(1 << $::EEPROM_BWE_S)}]; #prepare to buffer load
    mww $::EEPROM_REGS_EEA $a_addr;
    #buffer load
    mww $::EEPROM_REGS_EEDAT $a_data;
	#puts "[format "%#.4x" $a_addr]: $a_data";
    #for {set i 0} {$i < 32} {incr i} {
    #    mww $::EEPROM_REGS_EEDAT 0x00000000;
    #}
    #start operation
    mww $::EEPROM_REGS_EECON [expr {(1 << $::EEPROM_EX_S) | (1 << $::EEPROM_BWE_S) | ($::EEPROM_OP_PR << $::EEPROM_OP_S)}]
    sleep 1
}

proc eeprom_write_page {a_addr a_data} {
	mww $::EEPROM_REGS_EECON [expr {(1 << $::EEPROM_BWE_S)}]; #prepare to buffer load
	mww $::EEPROM_REGS_EEA $a_addr;
    set page_address [expr {$a_addr & $::EEPROM_PAGE_MASK}]
    set n 0
    # buffer load
	foreach word $a_data {
		if {[expr {($a_addr + $n) & $::EEPROM_PAGE_MASK}] != $page_address} {
			eeprom_print_error "word outside page! page_address=$page_address"
			return 1
		}
		mww $::EEPROM_REGS_EEDAT $word;
	}
    mww $::EEPROM_REGS_EECON [expr {(1 << $::EEPROM_EX_S) | (1 << $::EEPROM_BWE_S) | ($::EEPROM_OP_PR << $::EEPROM_OP_S)}]
    sleep 1
}

proc eeprom_hex_reverse_bytes {str} {
	if {[string length $str] != 8} {
		eeprom_print_error "eeprom_hex_reverse_bytes string length != 8";
		return 1;
	}
	return "[string range $str 6 7][string range $str 4 5][string range $str 2 3][string range $str 0 1]";
}

proc eeprom_hex_parse_file {a_filename} {
	puts "EEPROM reading $a_filename..."
	set fp [open $a_filename r];
	set list {};
	while {[gets $fp s1] > 0} {
		if {[string range $s1 1 2] == "10"} {
			lappend list [eeprom_hex_reverse_bytes [string range $s1 9 16]];
			lappend list [eeprom_hex_reverse_bytes [string range $s1 17 24]];
			lappend list [eeprom_hex_reverse_bytes [string range $s1 25 32]];
			lappend list [eeprom_hex_reverse_bytes [string range $s1 33 40]];
		}
	}
	close $fp;
	return $list;
}

proc eeprom_check_data_apb {data} {
	puts "EEPROM check through APB...";
	mww $::EEPROM_REGS_EEA 0x00000000;
	set list_size [llength $data]
    set ll 0
	set progress 2
	puts -nonewline "\["
	set value {}
	foreach byte $data {
		mem2array value 32 $::EEPROM_REGS_EEDAT 1
		#mem2array value 32 $::EEPROM_REGS_EEDAT 1;
		scan $byte %x decimal
		if {$decimal != [lindex $value 1]} {
			eeprom_print_error "Unexpect value at $ll word, expect $decimal $byte, get $value"
			return 1
		};
		incr ll;
		if {[expr {($ll * 100) / $list_size}] > $progress} {
			puts -nonewline "#"
			set progress [expr {$progress + 2}]
		}
	}
	puts "\]";
	puts "EEPROM check through APB done!"
}

proc eeprom_check_data_ahb_lite {a_words} {
	puts "EEPROM check through AHB-Lite..."
	set len_words [llength $a_words]
	# set mem_array [read_memory 0x01000000 32 $len_words]
	mem2array mem_array 32 0x01000000 $len_words
	if {$len_words != [expr {[llength $mem_array] / 2}]} {
		eeprom_print_error "Wrong number of words in read_memory output!"
		return 1
	}
	set progress 0
	puts -nonewline "\[";
	for {set word_num 0} {$word_num < $len_words} {incr word_num} {
		if {"0x[lindex $a_words $word_num]" != [dict get $mem_array $word_num]} {
			eeprom_print_error "Unexpect value at $word_num word, expect 0x[lindex $a_words $word_num], get [lindex $mem_array $word_num]"
			return 1
		}
        set curr_progress [expr {($word_num * 50) / $len_words}]
        if {$curr_progress > $progress} {
            for {set i 0} {$i < [expr {$curr_progress - $progress}]} {incr i} {
				puts -nonewline "#";
			}
			set progress $curr_progress;
		}
	}
	puts "\]";
	puts "EEPROM check through APB done!";
}

proc eeprom_write_file {a_filename} {
	eeprom_sysinit;
	eeprom_global_erase;
	mww $::EEPROM_REGS_NCYCRL [expr {(1<<$::EEPROM_N_LD_S  | 3<<$::EEPROM_N_R_1_S | 1 << $::EEPROM_N_R_2_S)}];
    mww $::EEPROM_REGS_NCYCEP1 100000;
    mww $::EEPROM_REGS_NCYCEP2 1000;
    sleep 100;
	set words [eeprom_hex_parse_file $a_filename];
	set list_size [llength $words];
	set word_num 0
	set progress 0
	puts "EEPROM writing $a_filename...";
	puts -nonewline "\[";
	
	set page {}
	set page_num 0
	set page_size 32
	while {$word_num < $list_size} {
		if {$word_num < [expr {$page_size*($page_num+1)}]} {
			lappend page "0x[lindex $words $word_num]"
			incr word_num;
		} else {
			# print(list(map(lambda word: f"{word:#0x}", page)))
			eeprom_write_page [expr {$page_num*$page_size*4}] $page;
			incr page_num;
			set page {}; # page.clear()
		}
		set curr_progress [expr {($word_num * 50) / $list_size}]
		if {$curr_progress > $progress} {
			for {set i 0} {$i < [expr {$curr_progress - $progress}]} {incr i} {
				puts -nonewline "#";
			}
			set progress $curr_progress;
		}
		
	
		# eeprom_write_word [expr {$ll*4}] 0x$byte;
		# incr ll;
		# if {[expr {($ll * 100) / $list_size}] > $progress} {
			# puts -nonewline "#";
			# set progress [expr {$progress + 2}];
		# }
	}
	eeprom_write_page [expr {$page_num*$page_size*4}] $page;
	puts "\]";
	puts "EEPROM write file done!";
	eeprom_check_data_ahb_lite $words;
}

proc eeprom_write_file_by_word {a_filename} {
	eeprom_sysinit;
	eeprom_global_erase;
	mww $::EEPROM_REGS_NCYCRL [expr {(1<<$::EEPROM_N_LD_S  | 3<<$::EEPROM_N_R_1_S | 1 << $::EEPROM_N_R_2_S)}];
    mww $::EEPROM_REGS_NCYCEP1 100000;
    mww $::EEPROM_REGS_NCYCEP2 1000;
    sleep 100;
	set bytes [eeprom_hex_parse_file $a_filename];
	set list_size [llength $bytes];
    set ll 0;
	set progress 2;
	puts "EEPROM writing a_filename..."
	puts -nonewline "\[";
	foreach byte $bytes {
		eeprom_write_word [expr {$ll*4}] 0x$byte;
		incr ll;
		if {[expr {($ll * 100) / $list_size}] > $progress} {
			puts -nonewline "#";
			set progress [expr {$progress + 2}];
		}
	}
	puts "\]";
	puts "EEPROM write file done!";
	eeprom_check_data_apb $bytes;
}
